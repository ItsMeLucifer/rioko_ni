import 'package:country_code/country_code.dart';
import 'package:country_flags/country_flags.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rioko_ni/core/extensions/polygon2.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/models/country_model.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geobase/geobase.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/main.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;

part 'country.freezed.dart';

enum CountryStatus {
  none,
  been,
  want,
  lived,
}

enum Region {
  northAmerica,
  southAmerica,
  europe,
  africa,
  asia,
  oceania,
  antarctic,
}

extension RegionExtension on Region {
  static Region fromString(String name) {
    switch (name) {
      case 'Asia':
        return Region.asia;
      case 'Africa':
        return Region.africa;
      case 'North America':
        return Region.northAmerica;
      case 'South America':
        return Region.southAmerica;
      case 'Oceania':
        return Region.oceania;
      case 'Antarctic':
        return Region.antarctic;
      case 'Europe':
        return Region.europe;
      default:
        return Region.asia;
    }
  }

  String get name {
    switch (this) {
      case Region.africa:
        return tr('regions.africa');
      case Region.antarctic:
        return tr('regions.antarctic');
      case Region.asia:
        return tr('regions.asia');
      case Region.europe:
        return tr('regions.europe');
      case Region.northAmerica:
        return tr('regions.northAmerica');
      case Region.southAmerica:
        return tr('regions.southAmerica');
      case Region.oceania:
        return tr('regions.oceania');
    }
  }
}

extension CountryStatusExtension on CountryStatus {
  Color get color {
    final context = RiokoNi.navigatorKey.currentContext;
    if (context == null) return Colors.transparent;
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case CountryStatus.been:
        return scheme.onPrimary;
      case CountryStatus.want:
        return scheme.onSecondary;
      case CountryStatus.lived:
        return scheme.onTertiary;
      default:
        return Colors.transparent;
    }
  }
}

@unfreezed
class Country with _$Country {
  const Country._();
  factory Country({
    /// GeoJson data
    required FeatureCollection featureCollection,
    required CountryCode countryCode,
    required Region region,
    @Default(CountryStatus.none) CountryStatus status,
  }) = _Country;

  CountryModel toModel() => CountryModel(
        countryCode: countryCode.alpha3,
        featureCollection: featureCollection,
        region: region,
      );

  String get alpha2 => countryCode.alpha2;
  String get alpha3 => countryCode.alpha3;

  String get name => tr('countries.$alpha3');

  List<List<LatLng>> points({
    int reductionPercentage = 75,
    double areaThresholdInSquareKilometers = 500,
  }) {
    List<List<LatLng>> result = [];
    final polygons = _getFeatureCollectionPolygons();

    // Process each polygon
    for (Polygon polygon in polygons) {
      List<LatLng> points = [];

      // Skip polygons without exterior positions
      if (polygon.exterior == null) continue;

      // Convert GeoJSON positions to LatLng points
      polygon.exterior?.positions.forEach((position) {
        double latitude = position.y;
        double longitude = position.x;

        // Ensure longitude is within the valid range of flutter_map coordination system
        if (longitude <= -180 || longitude >= 180) {
          longitude = longitude.clamp(-179.999999, 179.999999);
        }

        points.add(LatLng(latitude, longitude));
      });

      // Skip invalid polygons
      if (points.isEmpty || points.length < 2 || points.first != points.last) {
        continue;
      }

      // Skip polygons that area is smaller that threshold
      if (result.isNotEmpty &&
          GeoUtils.calculatePolygonArea(points) <
              areaThresholdInSquareKilometers) {
        continue;
      }

      fm.Polygon fmPolygon = fm.Polygon(
        points: points,
      );

      if (points.length > 100) {
        fmPolygon = Polygon2(fmPolygon)
            .simplify(reductionPercentage: reductionPercentage);
      }

      result = [...result, fmPolygon.points];
    }

    return result;
  }

  List<Polygon> _getFeatureCollectionPolygons() {
    List<Polygon> polygons = [];

    // Iterate through each GeoJSON feature in the collection
    for (Feature feature in featureCollection.features) {
      // Extract polygons from the feature's geometry
      if (feature.geometry is Polygon) {
        polygons.add(feature.geometry as Polygon);
      }
      if (feature.geometry is MultiPolygon) {
        var multiPolygon = feature.geometry as MultiPolygon;

        // For MultiPolygon, sort Polygons from highest number of points to lowest.
        polygons = [
          ...multiPolygon.polygons.toList()
            ..sort((a, b) {
              final bPositionsLength = b.exterior!.positions.length;
              final aPositionsLength = a.exterior!.positions.length;
              return bPositionsLength.compareTo(aPositionsLength);
            })
        ];
      }
    }
    return polygons;
  }

  bool contains(LatLng position) {
    final poly = _getFeatureCollectionPolygons();
    // First check if the position is in the bounding box
    final result = poly.where((p) {
      final corners = p.calculateBounds(scheme: Geographic.scheme)!.corners2D;
      LatLng? corner1;
      LatLng? corner2;
      if (corners.length == 2) {
        corner1 = LatLng(corners.first.y, corners.first.x);
        corner2 = LatLng(corners.last.y, corners.last.x);
      }
      if (corners.length == 4) {
        corner1 = LatLng(corners.first.y, corners.first.x);
        corner2 = LatLng(corners.elementAt(2).y, corners.elementAt(2).x);
      }
      if (corner1 == null || corner2 == null) return false;
      if (alpha2 == 'RU') {
        corner2 = LatLng(corner2.latitude, corner2.longitude.abs());
      }

      return fm.LatLngBounds(corner1, corner2).contains(position);
    });
    if (result.isEmpty) return false;
    // And then execute more complex method to check if position is inside the geometry
    return poly.any(
      (p) => pip.Poly.isPointInPolygon(
        pip.Point(x: position.longitude, y: position.latitude),
        p.exterior!.positions
            .map((position) => pip.Point(x: position.x, y: position.y))
            .toList(),
      ),
    );
  }

  int get pointsNumber {
    final _points =
        points(reductionPercentage: 65).map((p) => p.length).toList();

    if (_points.isNotEmpty) {
      return _points.reduce((value, element) => value + element);
    }

    return -1;
  }

  Widget flag({
    double scale = 1,
    double borderRadius = 0,
  }) {
    const double height = 48;
    const double width = 62;
    return CountryFlag.fromCountryCode(
      alpha2,
      height: height * scale,
      width: width * scale,
      borderRadius: borderRadius,
    );
  }
}
