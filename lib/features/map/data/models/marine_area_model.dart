import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';

part 'marine_area_model.freezed.dart';
part 'marine_area_model.g.dart';

@freezed
class MarineAreaModel with _$MarineAreaModel {
  const MarineAreaModel._();
  const factory MarineAreaModel({
    required int rank,
    required int type,
    required String name,
    required List<List<List<double>>> polygons,
  }) = _MarineAreaModel;

  factory MarineAreaModel.fromJson(Map<String, dynamic> json) =>
      _$MarineAreaModelFromJson(json);

  MarineArea toEntity() => MarineArea(
        rank: rank,
        type: type,
        name: name,
        polygons: polygons,
      );
}
