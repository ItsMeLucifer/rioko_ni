part of 'map_cubit.dart';

@freezed
class MapState with _$MapState {
  const factory MapState.initial() = _Initial;

  const factory MapState.loading() = _Loading;

  const factory MapState.gotDir(String dir) = _GotDir;

  const factory MapState.fetchedCountryPolygons(List<Country> polygons) =
      _FetchedCountryPolygons;

  const factory MapState.fetchedMarineAreas(List<MarineArea> marineAreas) =
      _FetchedMarineAreas;

  const factory MapState.readMapObjectsData({
    required List<MapObject> been,
    required List<MapObject> want,
    required List<MapObject> lived,
  }) = _ReadMapObjectsData;

  const factory MapState.readRegionsData({
    required Map<String, List<Region>> data,
  }) = _ReadRegionsData;

  const factory MapState.savedMapObjectsData({
    required List<MapObject> been,
    required List<MapObject> want,
    required List<MapObject> lived,
  }) = _SavedMapObjectsData;

  const factory MapState.savedRegionsData({
    required Map<String, List<Region>> data,
  }) = _SavedRegionsData;

  const factory MapState.updatedMapObjectStatus({
    required MapObject mapObject,
    required MOStatus status,
  }) = _UpdatedCountryStatus;

  const factory MapState.setCurrentPosition(LatLng position) =
      _SetCurrentPosition;

  const factory MapState.changeRiokoMode(RiokoMode mode) = _ChangeRiokoMode;

  const factory MapState.fetchingRegions() = _FetchingRegions;

  const factory MapState.fetchedRegions(List<Region> regions) = _FetchedRegions;

  const factory MapState.error(String message) = _Error;
}
