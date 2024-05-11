import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';

part 'region.freezed.dart';
part 'region_hive_adapter.dart';

@unfreezed
class Region extends MapObject with _$Region {
  Region._() : super(status: MOStatus.none);
  @HiveType(typeId: 1)
  factory Region({
    /// GeoJson data
    @HiveField(0) required List<List<LatLng>> polygons,
    @HiveField(1) required String code,
    @HiveField(2) required String name,
    @HiveField(3) required String type,
    @HiveField(4) required String countryCode,
    @HiveField(5) String? engType,
    @HiveField(6) @Default(MOStatus.none) MOStatus status,
  }) = _Region;

  List<LatLng> get polygon => polygons.first;

  bool contains(LatLng position) {
    return polygons.any((polygon) {
      return pip.Poly.isPointInPolygon(
        pip.Point(x: position.longitude, y: position.latitude),
        polygon
            .map((latLng) => pip.Point(x: latLng.longitude, y: latLng.latitude))
            .toList(),
      );
    });
  }

  RegionModel toModel() => RegionModel(
        code: code,
        polygons: polygons
            .map((p) => p.map((p2) => [p2.latitude, p2.longitude]).toList())
            .toList(),
        name: name,
        type: type,
      );
}
