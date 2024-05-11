import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';

part 'region_model.freezed.dart';
part 'region_model.g.dart';

@freezed
class RegionModel with _$RegionModel {
  const RegionModel._();
  factory RegionModel({
    required List<List<List<double>>> polygons,
    // ISO 3166-2 region code
    required String code,
    required String name,
    required String type,
  }) = _RegionModel;

  factory RegionModel.fromJson(Map<String, dynamic> json) =>
      _$RegionModelFromJson(json);

  Region toEntity(String countryCode) {
    return Region(
      code: code,
      polygons: polygons
          .map((p) => p.map((p2) => LatLng(p2.first, p2.last)).toList())
          .toList(),
      name: name,
      type: type,
      countryCode: countryCode,
    );
  }
}
