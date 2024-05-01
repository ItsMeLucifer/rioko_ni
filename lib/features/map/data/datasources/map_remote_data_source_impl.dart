import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geobase/geobase.dart';
import 'package:rioko_ni/core/data/gadm_client.dart';
import 'package:rioko_ni/core/errors/exception.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/datasources/map_remote_data_source.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final GADMClient client;

  const MapRemoteDataSourceImpl({required this.client});

  static String get mockDataPath => 'assets/data/geo/gadm41_POL_1.json';

  @override
  Future<List<RegionModel>> getCountryRegions({
    required String countryCode,
  }) async {
    try {
      final mockData = await rootBundle.loadString(mockDataPath);
      final mockJson = jsonDecode(mockData) as Map<String, dynamic>;
      // final httpResponse =
      //     await client.getCountryRegions(countryCode: countryCode);
      // if (httpResponse.response.statusCode != 200) {
      //   throw ServerException(httpResponse.response.toString(),
      //       stack: StackTrace.current);
      // }

      // final featureCollection = FeatureCollection.fromData(httpResponse.data);

      final featureCollection = FeatureCollection.fromData(mockJson);

      return featureCollection.features.map((feature) {
        final name = feature.properties["NAME_1"];
        final type = feature.properties["TYPE_1"];
        final engType = feature.properties["ENGTYPE_1"];
        final code = feature.properties["CC_1"];

        final List<List<List<double>>> polygons =
            GeoUtils.extractPolygonsFromFeature(feature);

        polygons.sort((a, b) => b.length.compareTo(a.length));

        return RegionModel(
          countryCode: countryCode,
          code: code,
          name: name,
          type: type,
          engType: engType,
          polygons: polygons.first,
        );
      }).toList();
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      throw RequestException(e.toString(), stack: stack);
    }
  }
}
