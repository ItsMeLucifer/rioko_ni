import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:geobase/geobase.dart';
import 'package:http/io_client.dart';
import 'package:rioko_ni/core/data/gadm_client.dart';
import 'package:rioko_ni/core/errors/exception.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/features/map/data/datasources/map_remote_data_source.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final GADMClient client;

  const MapRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RegionModel>> getCountryRegions({
    required String countryCode,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final client = IOClient();
      final uri = Uri.https(
        "geodata.ucdavis.edu",
        "gadm/gadm4.1/json/gadm41_${countryCode}_1.json.zip",
      );
      debugPrint('GET ${uri.host}${uri.path}');
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        throw ServerException(response.toString(), stack: StackTrace.current);
      }
      debugPrint(
          'Got data from server in ${stopwatch.elapsedMilliseconds / 1000}s');

      // // Unzip the file
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);

      Map<String, dynamic> json = {};
      // Look for JSON file inside the archive
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.json')) {
          final jsonData = utf8.decode(file.content as List<int>);
          json = jsonDecode(jsonData);
        }
      }

      final featureCollection = FeatureCollection.fromData(json);

      return featureCollection.features.map((feature) {
        final name = feature.properties["NAME_1"];
        final type = feature.properties["TYPE_1"];
        final engType = feature.properties["ENGTYPE_1"];
        final code = feature.properties["CC_1"];

        final List<List<List<double>>> polygons = GeoUtils.clampPolygons(
            GeoUtils.extractPolygonsFromFeature(feature));

        polygons.sort((a, b) => b.length.compareTo(a.length));

        return RegionModel(
          countryCode: countryCode,
          code: code,
          name: name,
          type: type,
          engType: engType,
          polygons: polygons,
        );
      }).toList();
    } on ServerException {
      rethrow;
    } catch (e, stack) {
      throw RequestException(e.toString(), stack: stack);
    }
  }
}
