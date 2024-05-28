import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:rioko_ni/main.dart';

part 'marine_area.freezed.dart';

@unfreezed
class MarineArea extends MapObject with _$MarineArea {
  MarineArea._() : super();
  factory MarineArea({
    required int rank,
    required int type,
    required String nameCode,
    required List<List<LatLng>> polygons,
    @Default(MOStatus.none) MOStatus status,
  }) = _MarineArea;

  String get typeName => tr('marineAreaTypes.$type');

  @override
  String get name => tr('marineAreas.$nameCode');

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

  /// return the bounds od the biggest polygon
  /// (in the marine areas it is not necessary to get overall bounds as in Country object)
  @override
  fm.LatLngBounds bounds() {
    return fm.LatLngBounds.fromPoints(polygons.first);
  }

  @override
  LatLng get center {
    return bounds().center;
  }

  @override
  Widget flag({
    double scale = 1,
    double borderRadius = 0,
    Color? borderColor,
  }) {
    const double height = 48;
    const double width = 62;
    final flag = Container(
      height: height * scale,
      width: width * scale,
      color: Colors.blue,
      padding: const EdgeInsets.all(AppSizes.paddingHalf),
      child: Center(
        child: MapBuilder().buildMapObjectPreview(
          RiokoNi.navigatorKey.currentContext!,
          mapObject: this,
          polygonColor: Colors.white,
          zoom: 0,
        ),
      ),
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
