import 'package:country_code/country_code.dart';
import 'package:country_flags/country_flags.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/models/country_model.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';

part 'country.freezed.dart';

enum Area {
  asia,
  northAmerica,
  southAmerica,
  africa,
  europe,
  oceania,
  antarctic,
  world,
}

extension AreaExtension on Area {
  static List<Area> get fixedValues => [
        Area.world,
        Area.europe,
        Area.africa,
        Area.northAmerica,
        Area.southAmerica,
        Area.asia,
        Area.oceania,
      ];

  static Area fromIndex(int index) {
    switch (index) {
      case 0:
        return Area.asia;
      case 1:
        return Area.northAmerica;
      case 2:
        return Area.southAmerica;
      case 3:
        return Area.africa;
      case 4:
        return Area.europe;
      case 5:
        return Area.oceania;
      case 6:
        return Area.antarctic;
      default:
        return Area.asia;
    }
  }

  LatLng get center {
    switch (this) {
      case Area.europe:
        return const LatLng(54, 13);
      case Area.northAmerica:
        return const LatLng(50, -100);
      case Area.southAmerica:
        return const LatLng(-26, -64);
      case Area.africa:
        return const LatLng(2, 17);
      case Area.asia:
        return const LatLng(35, 85);
      case Area.oceania:
        return const LatLng(-16.810507, 143.407079);
      default:
        return const LatLng(15.6, 0.9);
    }
  }

  double get zoom {
    switch (this) {
      case Area.europe:
        return 2.7;
      case Area.northAmerica:
        return 1.7;
      case Area.southAmerica:
        return 2;
      case Area.africa:
        return 2.17;
      case Area.asia:
        return 2;
      case Area.oceania:
        return 2.1;
      default:
        return 0.45;
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
      case Area.world:
        return tr('areas.allWorld');
    }
  }

  String get imagePath {
    switch (this) {
      case Area.africa:
        return AssetsHandler.africaMiniature;
      case Area.asia:
        return AssetsHandler.asiaMiniature;
      case Area.europe:
        return AssetsHandler.europeMiniature;
      case Area.northAmerica:
        return AssetsHandler.northAmericaMiniature;
      case Area.southAmerica:
        return AssetsHandler.southAmericaMiniature;
      case Area.oceania:
        return AssetsHandler.oceaniaMiniature;
      default:
        return 'world-image';
    }
  }
}

@unfreezed
class Country extends MapObject with _$Country {
  Country._() : super(status: MOStatus.none, name: '');
  factory Country({
    /// GeoJson data
    required List<List<LatLng>> polygons,
    required CountryCode countryCode,
    required Area area,
    required SubArea? subArea,
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
        area: area.index,
        subArea: subArea?.index,
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

  @override
  fm.LatLngBounds bounds({
    bool cutOffFarPolygons = false,
    double distance = 2000,
  }) {
    return GeoUtils.calculateOverallBounds(polygons
        .where((p) {
          if (!cutOffFarPolygons) return true;
          return GeoUtils.calculateDistance(
                  fm.Polygon(points: polygons.first).boundingBox.center,
                  fm.Polygon(points: p).boundingBox.center) <
              distance;
        })
        .map((p) => fm.Polygon(points: p))
        .toList());
  }

  LatLng get center {
    return bounds().center;
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

enum SubArea {
  easternEurope,
  easternAfrica,
  micronesia,
  westernAfrica,
  southeastEurope,
  caribbean,
  polynesia,
  northernEurope,
  southernEurope,
  westernAsia,
  southEasternAsia,
  middleAfrica,
  northernAfrica,
  centralEurope,
  melanesia,
  centralAsia,
  australiaAndNewZealand,
  southernAsia,
  easternAsia,
  centralAmerica,
  westernEurope,
  southernAfrica,
}

extension SubAreaExtension on SubArea {
  static SubArea fromIndex(int index) {
    switch (index) {
      case 0:
        return SubArea.easternEurope;
      case 1:
        return SubArea.easternAfrica;
      case 2:
        return SubArea.micronesia;
      case 3:
        return SubArea.westernAfrica;
      case 4:
        return SubArea.southeastEurope;
      case 5:
        return SubArea.caribbean;
      case 6:
        return SubArea.polynesia;
      case 7:
        return SubArea.northernEurope;
      case 8:
        return SubArea.southernEurope;
      case 9:
        return SubArea.westernAsia;
      case 10:
        return SubArea.southEasternAsia;
      case 11:
        return SubArea.middleAfrica;
      case 12:
        return SubArea.northernAfrica;
      case 13:
        return SubArea.centralEurope;
      case 14:
        return SubArea.melanesia;
      case 15:
        return SubArea.centralAsia;
      case 16:
        return SubArea.australiaAndNewZealand;
      case 17:
        return SubArea.southernAsia;
      case 18:
        return SubArea.easternAsia;
      case 19:
        return SubArea.centralAmerica;
      case 20:
        return SubArea.westernEurope;
      case 21:
        return SubArea.southernAfrica;
      default:
        return SubArea.easternEurope;
    }
  }

  String get name {
    switch (this) {
      case SubArea.easternEurope:
        return tr('subAreas.easternEurope');
      case SubArea.easternAfrica:
        return tr('subAreas.easternAfrica');
      case SubArea.micronesia:
        return tr('subAreas.micronesia');
      case SubArea.westernAfrica:
        return tr('subAreas.westernAfrica');
      case SubArea.southeastEurope:
        return tr('subAreas.southeastEurope');
      case SubArea.caribbean:
        return tr('subAreas.caribbean');
      case SubArea.polynesia:
        return tr('subAreas.polynesia');
      case SubArea.northernEurope:
        return tr('subAreas.northernEurope');
      case SubArea.southernEurope:
        return tr('subAreas.southernEurope');
      case SubArea.westernAsia:
        return tr('subAreas.westernAsia');
      case SubArea.southEasternAsia:
        return tr('subAreas.southEasternAsia');
      case SubArea.middleAfrica:
        return tr('subAreas.middleAfrica');
      case SubArea.northernAfrica:
        return tr('subAreas.northernAfrica');
      case SubArea.centralEurope:
        return tr('subAreas.centralEurope');
      case SubArea.melanesia:
        return tr('subAreas.melanesia');
      case SubArea.centralAsia:
        return tr('subAreas.centralAsia');
      case SubArea.australiaAndNewZealand:
        return tr('subAreas.australiaAndNewZealand');
      case SubArea.southernAsia:
        return tr('subAreas.southernAsia');
      case SubArea.easternAsia:
        return tr('subAreas.easternAsia');
      case SubArea.centralAmerica:
        return tr('subAreas.centralAmerica');
      case SubArea.westernEurope:
        return tr('subAreas.westernEurope');
      case SubArea.southernAfrica:
        return tr('subAreas.southernAfrica');
    }
  }
}
