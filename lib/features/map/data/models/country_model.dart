import 'package:country_code/country_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';

part 'country_model.freezed.dart';

@freezed
class CountryModel with _$CountryModel {
  const CountryModel._();
  factory CountryModel({
    required List<List<List<double>>> polygons,
    required String countryCode,
    required int area,
    required int? subArea,
    required bool moreDataAvailable,
  }) = _CountryModel;

  Country toEntity() {
    final poly = polygons
        .map((p) => p.map((p2) => LatLng(p2.first, p2.last)).toList())
        .toList();
    return Country(
      countryCode: CountryCode.parse(countryCode),
      polygons: poly.map((p) {
        if (GeoUtils.calculatePolygonArea(p) < 2000) {
          return p;
        }
        return [
          ...GeoUtils.simplifyPolygon(p.sublist(0, p.length - 2),
              tolerance: 0.007),
          p.last
        ];
      }).toList(),
      area: AreaExtension.fromIndex(area),
      subArea: subArea == null ? null : SubAreaExtension.fromIndex(subArea!),
      moreDataAvailable: moreDataAvailable,
    );
  }
}
