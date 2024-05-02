import 'package:country_code/country_code.dart';
import 'package:country_flags/country_flags.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/models/country_model.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';

part 'country.freezed.dart';

enum Area {
  northAmerica,
  southAmerica,
  europe,
  africa,
  asia,
  oceania,
  antarctic,
}

extension AreaExtension on Area {
  static Area fromString(String name) {
    switch (name) {
      case 'Asia':
        return Area.asia;
      case 'Africa':
        return Area.africa;
      case 'North America':
        return Area.northAmerica;
      case 'South America':
        return Area.southAmerica;
      case 'Oceania':
        return Area.oceania;
      case 'Antarctic':
        return Area.antarctic;
      case 'Europe':
        return Area.europe;
      default:
        return Area.asia;
    }
  }

  String get name {
    switch (this) {
      case Area.africa:
        return tr('areas.africa');
      case Area.antarctic:
        return tr('areas.antarctic');
      case Area.asia:
        return tr('areas.asia');
      case Area.europe:
        return tr('areas.europe');
      case Area.northAmerica:
        return tr('areas.northAmerica');
      case Area.southAmerica:
        return tr('areas.southAmerica');
      case Area.oceania:
        return tr('areas.oceania');
    }
  }
}

@unfreezed
class Country extends MapObject with _$Country {
  Country._() : super(status: MOStatus.none);
  factory Country({
    /// GeoJson data
    required List<List<LatLng>> polygons,
    required CountryCode countryCode,
    required Area region,
    required bool moreDataAvailable,
    @Default(MOStatus.none) MOStatus status,
    @Default(false) bool displayRegions,
    @Default(<Region>[]) List<Region> regions,
  }) = _Country;

  CountryModel toModel() => CountryModel(
        countryCode: countryCode.alpha3,
        polygons: polygons
            .map((p) => p.map((p2) => [p2.latitude, p2.longitude]).toList())
            .toList(),
        region: region,
        moreDataAvailable: moreDataAvailable,
      );

  String get alpha2 => countryCode.alpha2;
  String get alpha3 => countryCode.alpha3;

  String get name => tr('countries.$alpha3');

  /// Updated country status, based on the regions data
  void calculateStatus() {
    if (displayRegions) {
      if (regions.any((r) => r.status == MOStatus.lived)) {
        status = MOStatus.lived;
        return;
      }
      if (regions.any((r) => r.status == MOStatus.been)) {
        status = MOStatus.been;
        return;
      }
      if (regions.any((r) => r.status == MOStatus.want)) {
        status = MOStatus.want;
        return;
      }
      status = MOStatus.none;
      return;
    }
  }

  bool contains(LatLng position) {
    final bounds = polygons.map((p) => fm.LatLngBounds.fromPoints(p)).toList();
    // First check if the position is in the bounding box
    final result = bounds.where((b) => b.contains(position));
    if (result.isEmpty) return false;
    // And then execute more complex method to check if position is inside the geometry
    return bounds.any(
      (b) {
        final i = bounds.indexOf(b);
        return pip.Poly.isPointInPolygon(
          pip.Point(x: position.longitude, y: position.latitude),
          polygons[i]
              .map((latLng) =>
                  pip.Point(x: latLng.longitude, y: latLng.latitude))
              .toList(),
        );
      },
    );
  }

  fm.LatLngBounds get bounds {
    return GeoUtils.calculateOverallBounds(
        polygons.map((p) => fm.Polygon(points: p)).toList());
  }

  LatLng get center {
    return bounds.center;
  }

  Widget flag({
    double scale = 1,
    double borderRadius = 0,
    Color? borderColor,
  }) {
    const double height = 48;
    const double width = 62;
    final flag = CountryFlag.fromCountryCode(
      alpha2,
      height: height * scale,
      width: width * scale,
      borderRadius: borderRadius,
    );
    if (borderColor != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1),
          color: borderColor,
        ),
        child: flag,
      );
    }
    return flag;
  }
}
