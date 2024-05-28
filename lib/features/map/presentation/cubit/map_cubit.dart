import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_countries.dart';
import 'package:collection/collection.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_marine_areas.dart';
import 'package:rioko_ni/features/map/domain/usecases/get_regions.dart';

part 'map_state.dart';
part 'map_cubit.freezed.dart';

enum RiokoMode {
  normal,
  umi,
}

class MapCubit extends Cubit<MapState> {
  final GetCountries getCountryPolygonUsecase;
  final GetCountryRegions getCountryRegionsUsecase;
  final GetMarineAreas getMarineAreasUsecase;

  MapCubit({
    required this.getCountryPolygonUsecase,
    required this.getCountryRegionsUsecase,
    required this.getMarineAreasUsecase,
  }) : super(const MapState.initial());

  List<Country> countries = [];

  List<MarineArea> marineAreas = [];

  RiokoMode _mode = RiokoMode.normal;
  RiokoMode get mode => _mode;
  set mode(RiokoMode mode) {
    _mode = mode;
    optionsBox.put("mode", mode.name);
    emit(MapState.changeRiokoMode(mode));
  }

  void toggleMode() {
    mode = (mode == RiokoMode.umi ? RiokoMode.normal : RiokoMode.umi);
  }

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
  late Box marineAreasBox;
  late Box optionsBox;

  void load() async {
    emit(const MapState.loading());
    await _getDir();
    countriesBox = await Hive.openBox('countries');
    regionsBox = await Hive.openBox('regions_v2');
    marineAreasBox = await Hive.openBox('marine_areas');
    optionsBox = await Hive.openBox('options');
    _getCurrentPosition();
    _getCountryPolygons().then((_) {
      _getLocalCountryData();
      _getLocalRegionsData();
    });
    _getMarineAreas().then((_) => _getLocalMarineAreasData());
    _getLocalOptionsData();
  }

  Future _getLocalOptionsData() async {
    String name = optionsBox.get('mode', defaultValue: RiokoMode.normal.name);
    mode = RiokoMode.values.byName(name);
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

  Future _getMarineAreas() async {
    await getMarineAreasUsecase.call(NoParams()).then(
          (result) => result.fold(
            (failure) {
              emit(MapState.error(failure.message));
              debugPrint(failure.fullMessage);
            },
            (marineAreas) {
              this.marineAreas = marineAreas;
              emit(MapState.fetchedMarineAreas(marineAreas));
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

  List<MarineArea> marineAreasByString(String text) {
    final result = marineAreas
        .where(
          (marineArea) =>
              marineArea.name.toLowerCase().contains(text.toLowerCase()) ||
              marineArea.typeName.toLowerCase().contains(text.toLowerCase()),
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

    emit(MapState.readMapObjectsData(
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

  Future _getLocalMarineAreasData() async {
    final List<String> beenCodes = marineAreasBox.get('been') ?? [];
    final List<String> wantCodes = marineAreasBox.get('want') ?? [];

    if (beenCodes.isNotEmpty) {
      marineAreas
          .where((c) => beenCodes.contains(c.nameCode))
          .forEach((marineArea) => marineArea.status = MOStatus.been);
    }
    if (wantCodes.isNotEmpty) {
      marineAreas
          .where((c) => wantCodes.contains(c.nameCode))
          .forEach((marineArea) => marineArea.status = MOStatus.want);
    }

    emit(MapState.readMapObjectsData(
      been: marineAreas.where((m) => m.status == MOStatus.been).toList(),
      want: marineAreas.where((m) => m.status == MOStatus.want).toList(),
      lived: [],
    ));
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

  List<Country> get noAntarcticCountries =>
      countries.where((c) => c.area != Area.antarctic).toList();

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

  LatLng getWorldCenter({bool withAntarctic = true}) =>
      LatLng(withAntarctic ? 15.6642 : 43.6642, 0.9432);

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
    emit(MapState.savedMapObjectsData(
      been: beenCountries,
      want: wantCountries,
      lived: livedCountries,
    ));
  }

  void saveMarineAreasLocally() async {
    var box = Hive.box('marine_areas');
    final been = marineAreas.where((m) => m.status == MOStatus.been).toList();
    final want = marineAreas.where((m) => m.status == MOStatus.want).toList();
    await box.put('been', been.map((c) => c.nameCode).toList());
    await box.put('want', want.map((c) => c.nameCode).toList());
    emit(MapState.savedMapObjectsData(
      been: been,
      want: want,
      lived: [],
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
    emit(MapState.updatedMapObjectStatus(mapObject: country, status: status));
  }

  void updateMarineAreaStatus({
    required MarineArea marineArea,
    required MOStatus status,
  }) {
    marineAreas.firstWhere((m) => m.name == marineArea.name).status = status;
    saveMarineAreasLocally();
    emit(
        MapState.updatedMapObjectStatus(mapObject: marineArea, status: status));
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

  MarineArea? getMarineAreaFromPosition(LatLng position) {
    final watch = Stopwatch()..start();
    final results =
        marineAreas.where((area) => area.contains(position)).toList();
    if (results.length > 1) {
      results.sort((a, b) => GeoUtils.calculateDistance(a.center, position)
          .compareTo(GeoUtils.calculateDistance(b.center, position)));
    }
    watch.stop();
    if (results.isEmpty) {
      if (position.latitude > 80) {
        results.add(marineAreas.firstWhere((m) => m.nameCode == 'arcticOcean'));
      }
      if (position.latitude < -60) {
        results
            .add(marineAreas.firstWhere((m) => m.nameCode == 'southernOcean'));
      }
    }
    debugPrint('$position searched for: ${watch.elapsedMilliseconds / 1000}s');
    results.sort((a, b) => GeoUtils.calculateDistance(a.center, position)
        .compareTo(GeoUtils.calculateDistance(b.center, position)));
    return results.firstOrNull;
  }
}
