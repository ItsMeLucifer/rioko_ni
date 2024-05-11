import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:rioko_ni/features/map/data/models/region_model.dart';

part 'rioko_server_client.g.dart';

@RestApi()
abstract class RiokoServerClient {
  factory RiokoServerClient(Dio dio, {String baseUrl}) = _RiokoServerClient;

  static const api = 'api';

  /// Using [ISO 3166-1 alpha-3](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) code as a parameter.
  @GET('$api/regions/{isoA3Code}')
  Future<HttpResponse<List<RegionModel>>> getCountryRegions({
    @Path('isoA3Code') required String countryCode,
  });
}
