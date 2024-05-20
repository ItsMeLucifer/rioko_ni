import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:point_in_polygon/point_in_polygon.dart' as pip;

part 'marine_area.freezed.dart';

@unfreezed
class MarineArea extends MapObject with _$MarineArea {
  MarineArea._() : super(status: MOStatus.none);
  factory MarineArea({
    required int rank,
    required int type,
    required String name,
    required List<List<LatLng>> polygons,
    @Default(MOStatus.none) MOStatus status,
  }) = _MarineArea;

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
  fm.LatLngBounds bounds() {
    return fm.LatLngBounds.fromPoints(polygons.first);
  }

  LatLng get center {
    return bounds().center;
  }
}
