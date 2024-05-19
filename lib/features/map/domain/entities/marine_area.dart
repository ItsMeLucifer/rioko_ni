import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';

part 'marine_area.freezed.dart';

@unfreezed
class MarineArea with _$MarineArea {
  const factory MarineArea({
    required int rank,
    required int type,
    required String name,
    required List<List<List<double>>> polygons,
    @Default(MOStatus.none) MOStatus status,
  }) = _MarineArea;
}
