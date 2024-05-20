import 'package:dartz/dartz.dart';
import 'package:rioko_ni/core/domain/usecase.dart';
import 'package:rioko_ni/core/errors/failure.dart';
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';
import 'package:rioko_ni/features/map/domain/repositories/map_repository.dart';

class GetMarineAreas extends UseCase<List<MarineArea>, NoParams> {
  final MapRepository repository;
  GetMarineAreas(this.repository);

  @override
  Future<Either<Failure, List<MarineArea>>> call(NoParams params) async {
    return await repository.getMarineAreas();
  }
}
