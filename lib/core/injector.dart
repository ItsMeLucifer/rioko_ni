import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rioko_ni/core/data/rioko_server_client.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/features/map/data/datasources/map_local_data_source_impl.dart';
import 'package:rioko_ni/features/map/data/datasources/map_remote_data_source_impl.dart';
import 'package:rioko_ni/features/map/data/repositories/map_repository_impl.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_countries.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_regions.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

final locator = GetIt.instance;

Future registerDependencies() async {
  const connectTimeout = Duration(seconds: 60);
  const receiveTimeout = Duration(seconds: 120);
  final riokoDio = Dio(
    BaseOptions(
      baseUrl: 'https://riokoserver-y5bplxlvoa-lm.a.run.app/',
      receiveDataWhenStatusError: true,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        "Authorization":
            "Bearer ${const String.fromEnvironment('rioko_server_key')}"
      },
    ),
  );
  if (kDebugMode == true) {
    final prettyDioLogger = PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: false,
      responseHeader: true,
      error: true,
      request: false,
      compact: false,
    );
    riokoDio.interceptors.add(prettyDioLogger);
  }
  locator.registerSingleton<Dio>(riokoDio, instanceName: 'rioko-server');

  locator.registerSingleton<RiokoServerClient>(
      RiokoServerClient(locator<Dio>(instanceName: 'rioko-server')));
  locator.registerSingleton<MapLocalDataSourceImpl>(
      const MapLocalDataSourceImpl());
  locator.registerSingleton<MapRemoteDataSourceImpl>(
      MapRemoteDataSourceImpl(client: locator<RiokoServerClient>()));
  locator.registerSingleton<MapRepositoryImpl>(MapRepositoryImpl(
    localDataSource: locator<MapLocalDataSourceImpl>(),
    remoteDataSource: locator<MapRemoteDataSourceImpl>(),
  ));
  locator.registerSingleton<GetCountries>(
      GetCountries(locator<MapRepositoryImpl>()));

  locator.registerSingleton<GetCountryRegions>(
      GetCountryRegions(locator<MapRepositoryImpl>()));

  locator.registerSingleton<MapCubit>(
    MapCubit(
      getCountryPolygonUsecase: locator<GetCountries>(),
      getCountryRegionsUsecase: locator<GetCountryRegions>(),
    ),
  );
  // Revenue cat
  locator.registerSingleton<RevenueCatCubit>(RevenueCatCubit());
  // Theme
  var box = Hive.box('theme_data');
  final type = box.get('type') as ThemeDataType?;
  locator.registerSingleton<ThemeCubit>(ThemeCubit(type: type));
}
