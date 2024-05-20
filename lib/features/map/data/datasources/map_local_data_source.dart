import 'package:rioko_ni/features/map/data/models/country_model.dart';
import 'package:rioko_ni/features/map/data/models/marine_area_model.dart';

abstract class MapLocalDataSource {
  Future<List<CountryModel>> getCountries();

  Future<List<MarineAreaModel>> getMarineAreas();
}
