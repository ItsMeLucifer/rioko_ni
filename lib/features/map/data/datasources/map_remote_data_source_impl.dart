import 'package:flutter/material.dart';
import 'package:rioko_ni/core/data/rioko_server_client.dart';
import 'package:rioko_ni/core/errors/exception.dart';
import 'package:rioko_ni/features/map/data/datasources/map_remote_data_source.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final RiokoServerClient client;

  const MapRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RegionModel>> getCountryRegions({
    required String countryCode,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final httpResponse =
          await client.getCountryRegions(countryCode: countryCode);
      if (httpResponse.response.statusCode != 200) {
        throw ServerException(httpResponse.toString(),
            stack: StackTrace.current);
      }
      debugPrint(
          'Got data from server in ${stopwatch.elapsedMilliseconds / 1000}s');
      return httpResponse.data;
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      throw RequestException(e.toString(), stack: stack);
    }
  }
}
