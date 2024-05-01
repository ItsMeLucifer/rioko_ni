import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;

part 'region.freezed.dart';

@unfreezed
class Region with _$Region {
  const Region._();
  factory Region({
    /// GeoJson data
    required List<LatLng> polygon,
    required String code,
    required String name,
    required String type,
    required String countryCode,
    required String engType,
    @Default(CountryStatus.none) CountryStatus status,
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
