import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/datasources/map_local_data_source.dart';
import 'package:rioko_ni/features/map/data/models/country_model.dart';

class MapLocalDataSourceImpl implements MapLocalDataSource {
  const MapLocalDataSourceImpl();

  static String get countriesGeoDataPath =>
      'assets/data/geo/countries_geo.json';
  static String get countriesDataPath => 'assets/data/countries.json';

  static String get marineAreasDataPath => 'assets/data/geo/marine_areas.json';

  @override
  Future<List<CountryModel>> getCountries() async {
    final countriesGeoData = await rootBundle.loadString(countriesGeoDataPath);
    final countriesInfoData = await rootBundle.loadString(countriesDataPath);
    final geoData = jsonDecode(countriesGeoData) as Map<String, dynamic>;
    final infoData = jsonDecode(countriesInfoData) as Map<String, dynamic>;
    final List<CountryModel> result = [];
    for (String key in geoData.keys) {
      final cca3 = key;
      final info = infoData[cca3] as Map<String, dynamic>;
      final List<List<List<double>>> polygons = GeoUtils.clampPolygons(
          (geoData[key] as List<dynamic>)
              .map<List<List<double>>>((dynamic item) => (item as List<dynamic>)
                  .map<List<double>>((dynamic innerItem) =>
                      (innerItem as List<dynamic>)
                          .map<double>((dynamic subItem) => subItem.toDouble())
                          .toList())
                  .toList())
              .toList());
      result.add(
        CountryModel(
          polygons: polygons,
          countryCode: cca3,
          area: info['area'] as int,
          subArea: info['sub_area'] as int?,
          moreDataAvailable: info['more_data_available'] as bool,
        ),
      );
    }
    return result;
  }
}
