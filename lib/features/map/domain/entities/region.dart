import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';

part 'region.freezed.dart';

@unfreezed
class Region extends MapObject with _$Region {
  Region._() : super(status: MOStatus.none);
  factory Region({
    /// GeoJson data
    required List<LatLng> polygon,
    required String code,
    required String name,
    required String type,
    required String countryCode,
    required String engType,
    @Default(MOStatus.none) MOStatus status,
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
