import 'package:rioko_ni/features/map/data/models/country_polygons_model.dart';
import 'package:rioko_ni/features/map/domain/usecases/save_countries_locally.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

abstract class MapLocalDataSource {
  Future<List<CountryPolygonsModel>> getCountryPolygons();
  Future<void> saveCountriesLocally({
    required ManageCountriesLocallyParams params,
  });

  Future<ManageCountriesLocallyParams> readCountriesLocally({
    required Countries params,
  });
}
