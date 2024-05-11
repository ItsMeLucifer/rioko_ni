import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rioko_server_client.g.dart';

@RestApi()
abstract class RiokoServerClient {
  factory RiokoServerClient(Dio dio, {String baseUrl}) = _RiokoServerClient;

  static const api = 'api';

  /// Using [ISO 3166-1 alpha-3](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes) code as a parameter.
  @GET('$api/regions/{isoA3Code}')
  Future<String> getCountryRegions({
    @Path('isoA3Code') required String countryCode,
  });
}
