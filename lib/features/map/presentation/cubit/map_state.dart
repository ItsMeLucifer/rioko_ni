part of 'map_cubit.dart';

@immutable
sealed class MapState {}

final class MapInitial extends MapState {}

final class MapError extends MapState {
  final String message;
  MapError(this.message);
}

final class MapFetchedCountryPolygons extends MapState {
  final List<CountryPolygons> polygons;
  MapFetchedCountryPolygons(this.polygons);
}

final class MapReadCountriesData extends MapState {
  final List<CountryPolygons> beenCountries;
  final List<CountryPolygons> wantCountries;
  MapReadCountriesData({
    required this.beenCountries,
    required this.wantCountries,
  });
}
