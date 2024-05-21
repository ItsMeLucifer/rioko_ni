import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rioko_ni/core/domain/usecase.dart';
import 'package:rioko_ni/core/errors/failure.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/utils/geo_utils.dart';
import 'package:rioko_ni/core/utils/geolocation_handler.dart';

import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_countries.dart';
import 'package:collection/collection.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_regions.dart';

part 'map_state.dart';
part 'map_cubit.freezed.dart';

class MapCubit extends Cubit<MapState> {
  final GetCountries getCountryPolygonUsecase;
  final GetCountryRegions getCountryRegionsUsecase;

  MapCubit({
    required this.getCountryPolygonUsecase,
    required this.getCountryRegionsUsecase,
  }) : super(const MapState.initial());

  List<Country> countries = [];

  String urlTemplate({ThemeDataType? otherTheme}) {
    final themeCubit = locator<ThemeCubit>();
    switch (otherTheme ?? themeCubit.type) {
      case ThemeDataType.classic:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case ThemeDataType.humani:
        return 'https://tile-a.openstreetmap.fr/hot/{z}/{x}/{y}.png';
      case ThemeDataType.neoDark:
        return "https://api.mapbox.com/styles/v1/mister-lucifer/cls7n0t4g00zh01qsdc652wos/tiles/256/{z}/{x}/{y}{r}?access_token={accessToken}";
      case ThemeDataType.monochrome:
        return "https://api.mapbox.com/styles/v1/mister-lucifer/cls7m179n00lz01qldhet90ig/tiles/256/{z}/{x}/{y}{r}?access_token={accessToken}";
    }
  }

  late Box regionsBox;
  late Box countriesBox;

  void load() async {
    emit(const MapState.loading());
    await _getDir();
    countriesBox = await Hive.openBox('countries');
    regionsBox = await Hive.openBox('regions_v2');
    _getCurrentPosition();
    await _getCountryPolygons().then((_) {
      _getLocalCountryData();
      _getLocalRegionsData();
    });
  }

  Future _getCountryPolygons() async {
    await getCountryPolygonUsecase.call(NoParams()).then(
          (result) => result.fold(
            (failure) {
              emit(MapState.error(failure.message));
              debugPrint(failure.fullMessage);
            },
            (countryPolygons) {
              countries = countryPolygons;
              emit(MapState.fetchedCountryPolygons(countryPolygons));
            },
          ),
        );
  }

  List<Country> countriesByString(String text) {
    final result = countries
        .where(
          (country) =>
              tr('countries.${country.alpha3}')
                  .toLowerCase()
                  .contains(text.toLowerCase()) ||
              country.area.name.toLowerCase().contains(text.toLowerCase()),
        )
        .toList();
    return result;
  }

  Future<List<Region>> fetchCountryRegions(Country country) async {
    emit(const MapState.fetchingRegions());
    return await getCountryRegionsUsecase.call(country.alpha3).then(
          (result) => result.fold(
            (failure) {
              emit(MapState.error(failure.message));
              debugPrint(failure.fullMessage);
              return [];
            },
            (data) {
              country.regions = data;
              country.displayRegions = true;
              emit(MapState.fetchedRegions(data));
              regionsBox.put(country.alpha3, data);
              return data;
            },
          ),
        );
  }

  Future _getLocalCountryData() async {
    final List<String> beenCodes = countriesBox.get('been') ?? [];
    final List<String> wantCodes = countriesBox.get('want') ?? [];
    final List<String> livedCodes = countriesBox.get('lived') ?? [];
    final List<String> withRegionsCodes = countriesBox.get('withRegions') ?? [];

    if (beenCodes.isNotEmpty) {
      countries
          .where((c) => beenCodes.contains(c.alpha3))
          .forEach((country) => country.status = MOStatus.been);
    }
    if (wantCodes.isNotEmpty) {
      countries
          .where((c) => wantCodes.contains(c.alpha3))
          .forEach((country) => country.status = MOStatus.want);
    }
    if (livedCodes.isNotEmpty) {
      countries
          .where((c) => livedCodes.contains(c.alpha3))
          .forEach((country) => country.status = MOStatus.lived);
    }
    if (withRegionsCodes.isNotEmpty) {
      countries
          .where((c) => withRegionsCodes.contains(c.alpha3))
          .forEach((country) => country.displayRegions = true);
    }

    emit(MapState.readCountriesData(
      been: beenCountries,
      want: wantCountries,
      lived: livedCountries,
    ));
  }

  Future _getLocalRegionsData() async {
    final data = regionsBox.toMap().cast<String, List<dynamic>>();
    for (String alpha3 in data.keys) {
      countries.firstWhere((c) => c.alpha3 == alpha3)
        ..regions = (data[alpha3] ?? []).cast<Region>()
        ..displayRegions = true
        ..calculateStatus();
    }
    emit(MapState.readRegionsData(data: data.cast<String, List<Region>>()));
  }

  void updateDisplayRegionsInfo(String code, bool value) {
    final List<String> withRegionsData = countriesBox.get('withRegions') ?? [];
    countriesBox.put('withRegions', [...withRegionsData, code]);
  }

  void clearRegionData(String alpha3) {
    countries.firstWhere((c) => c.alpha3 == alpha3)
      ..regions = []
      ..displayRegions = false;
    regionsBox.delete(alpha3);
  }

  List<Country> get beenCountries =>
      countries.where((c) => c.status == MOStatus.been).toList();

  List<Country> get wantCountries =>
      countries.where((c) => c.status == MOStatus.want).toList();

  List<Country> get livedCountries =>
      countries.where((c) => c.status == MOStatus.lived).toList();

  List<Country> get themePreviewCountries {
    List<Country> result = [];
    result.add(countries.firstWhere((c) => c.alpha3 == 'POL')
      ..status = MOStatus.lived);
    result.add(
        countries.firstWhere((c) => c.alpha3 == 'LVA')..status = MOStatus.want);
    result.add(
        countries.firstWhere((c) => c.alpha3 == 'DEU')..status = MOStatus.been);
    result.add(
      countries.firstWhere((c) => c.alpha3 == 'HUN')
        ..status = MOStatus.been
        ..displayRegions = false,
    );
    return result;
  }

  // Asia

  int get beenAsiaCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.asia).length;
    var l = livedCountries.where((c) => c.area == Area.asia).length;
    return b + l;
  }

  double get beenAsiaPercentage {
    if (allAsiaCountriesNumber == 0) return 0;
    return beenAsiaCountriesNumber / allAsiaCountriesNumber * 100;
  }

  int get wantAsianCountriesNumber =>
      wantCountries.where((c) => c.area == Area.asia).length;
  double get wantAsiaPercentage {
    if (allAsiaCountriesNumber == 0) return 0;
    return wantAsianCountriesNumber / allAsiaCountriesNumber * 100;
  }

  int get allAsiaCountriesNumber =>
      countries.where((c) => c.area == Area.asia).length;

  // Europe

  int get beenEuropeCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.europe).length;
    var l = livedCountries.where((c) => c.area == Area.europe).length;
    return b + l;
  }

  double get beenEuropePercentage {
    if (allEuropeCountriesNumber == 0) return 0;
    return beenEuropeCountriesNumber / allEuropeCountriesNumber * 100;
  }

  int get wantEuropeCountriesNumber =>
      beenCountries.where((c) => c.area == Area.europe).length;
  double get wantEuropePercentage {
    if (allEuropeCountriesNumber == 0) return 0;
    return wantEuropeCountriesNumber / allEuropeCountriesNumber * 100;
  }

  int get allEuropeCountriesNumber =>
      countries.where((c) => c.area == Area.europe).length;

  // North America

  int get beenNorthAmericaCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.northAmerica).length;
    var l = livedCountries.where((c) => c.area == Area.northAmerica).length;
    return b + l;
  }

  double get beenNorthAmericaPercentage {
    if (allNorthAmericaCountriesNumber == 0) return 0;
    return beenNorthAmericaCountriesNumber /
        allNorthAmericaCountriesNumber *
        100;
  }

  int get wantNorthAmericaCountriesNumber =>
      wantCountries.where((c) => c.area == Area.northAmerica).length;
  double get wantNorthAmericaPercentage {
    if (allNorthAmericaCountriesNumber == 0) return 0;
    return wantNorthAmericaCountriesNumber /
        allNorthAmericaCountriesNumber *
        100;
  }

  int get allNorthAmericaCountriesNumber =>
      countries.where((c) => c.area == Area.northAmerica).length;

  // South America

  int get beenSouthAmericaCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.southAmerica).length;
    var l = livedCountries.where((c) => c.area == Area.southAmerica).length;
    return b + l;
  }

  double get beenSouthAmericaPercentage {
    if (allSouthAmericaCountriesNumber == 0) return 0;
    return beenSouthAmericaCountriesNumber /
        allSouthAmericaCountriesNumber *
        100;
  }

  int get wantSouthAmericaCountriesNumber =>
      beenCountries.where((c) => c.area == Area.southAmerica).length;
  double get wantSouthAmericaPercentage {
    if (allSouthAmericaCountriesNumber == 0) return 0;
    return wantSouthAmericaCountriesNumber /
        allSouthAmericaCountriesNumber *
        100;
  }

  int get allSouthAmericaCountriesNumber =>
      countries.where((c) => c.area == Area.southAmerica).length;

  // Africa

  int get beenAfricaCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.africa).length;
    var l = livedCountries.where((c) => c.area == Area.africa).length;
    return b + l;
  }

  double get beenAfricaPercentage {
    if (allAfricaCountriesNumber == 0) return 0;
    return beenAfricaCountriesNumber / allAfricaCountriesNumber * 100;
  }

  int get wantAfricaCountriesNumber =>
      wantCountries.where((c) => c.area == Area.africa).length;
  double get wantAfricaPercentage {
    if (allAfricaCountriesNumber == 0) return 0;
    return wantAfricaCountriesNumber / allAfricaCountriesNumber * 100;
  }

  int get allAfricaCountriesNumber =>
      countries.where((c) => c.area == Area.africa).length;

  // Oceania

  int get beenOceaniaCountriesNumber {
    var b = beenCountries.where((c) => c.area == Area.oceania).length;
    var l = livedCountries.where((c) => c.area == Area.oceania).length;
    return b + l;
  }

  double get beenOceaniaPercentage {
    if (allOceaniaCountriesNumber == 0) return 0;
    return beenOceaniaCountriesNumber / allOceaniaCountriesNumber * 100;
  }

  int get wantOceaniaCountriesNumber =>
      wantCountries.where((c) => c.area == Area.oceania).length;
  double get wantOceaniaPercentage {
    if (allOceaniaCountriesNumber == 0) return 0;
    return wantOceaniaCountriesNumber / allOceaniaCountriesNumber * 100;
  }

  int get allOceaniaCountriesNumber =>
      countries.where((c) => c.area == Area.oceania).length;

  // -----

  void saveCountriesLocally() async {
    var box = Hive.box('countries');
    await box.put('been', beenCountries.map((c) => c.alpha3).toList());
    await box.put('want', wantCountries.map((c) => c.alpha3).toList());
    await box.put('lived', livedCountries.map((c) => c.alpha3).toList());
    emit(MapState.savedCountriesData(
      been: beenCountries,
      want: wantCountries,
      lived: livedCountries,
    ));
  }

  void saveRegionsLocally() async {
    Map<String, List<Region>> data = {};
    for (Country country in countries) {
      if (country.displayRegions) {
        data[country.alpha3] = country.regions;
      }
    }
    await regionsBox.putAll(data);
    emit(MapState.savedRegionsData(data: data));
  }

  void updateCountryStatus({
    required Country country,
    required MOStatus status,
  }) {
    countries.firstWhere((c) => c.alpha3 == country.alpha3).status = status;
    saveCountriesLocally();
    emit(MapState.updatedCountryStatus(country: country, status: status));
  }

  LatLng? currentPosition;

  void _getCurrentPosition() async {
    try {
      final position = await GeoLocationHandler.determinePosition();
      final latLng = LatLng(position.latitude, position.longitude);
      currentPosition = latLng;
      emit(MapState.setCurrentPosition(latLng));
    } on PermissionFailure catch (e) {
      emit(MapState.error(e.message));
    } catch (e) {
      emit(MapState.error('$e'));
    }
  }

  // Caching

  String dir = '';

  Future _getDir() async {
    final cacheDirectory = await getTemporaryDirectory();
    dir = cacheDirectory.path;
    emit(MapState.gotDir(cacheDirectory.path));
  }

  // -----

  Country? getCountryFromPosition(LatLng position) {
    final watch = Stopwatch()..start();
    final results =
        countries.where((country) => country.contains(position)).toList();
    if (results.length > 1) {
      results.sort((a, b) => GeoUtils.calculateDistance(a.center, position)
          .compareTo(GeoUtils.calculateDistance(b.center, position)));
    }
    watch.stop();
    debugPrint('searched for: ${watch.elapsedMilliseconds / 1000}s');
    return results.firstOrNull;
  }
}
