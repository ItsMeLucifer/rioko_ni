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
    @HiveField(0) required List<LatLng> polygon,
    @HiveField(1) required String code,
    @HiveField(2) required String name,
    @HiveField(3) required String type,
    @HiveField(4) required String countryCode,
    @HiveField(5) required String engType,
    @HiveField(6) @Default(MOStatus.none) MOStatus status,
  }) = _Region;

  bool contains(LatLng position) {
    return pip.Poly.isPointInPolygon(
      pip.Point(x: position.longitude, y: position.latitude),
      polygon
          .map((latLng) => pip.Point(x: latLng.longitude, y: latLng.latitude))
          .toList(),
    );
  }

  RegionModel toModel() => RegionModel(
        code: code,
        polygons: polygon.map((p2) => [p2.latitude, p2.longitude]).toList(),
        name: name,
        type: type,
        countryCode: countryCode,
        engType: engType,
      );
}
