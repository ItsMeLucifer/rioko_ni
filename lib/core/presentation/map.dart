import 'dart:math';

import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/core/extensions/color2.dart';
import 'package:rioko_ni/core/extensions/iterable2.dart';
import 'package:rioko_ni/core/extensions/latlng_bounds2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/main.dart';

class MapBuilder {
  MapOptions getMapOptions({
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    Color? backgroundColor,
    InteractionOptions? interactionOptions,
    void Function(TapPosition, LatLng)? onTap,
    LatLng? center,
    bool keepAlive = true,
    CameraFit? initialCameraFit,
    CameraConstraint? cameraConstraint,
  }) {
    return MapOptions(
      interactionOptions: interactionOptions ?? const InteractionOptions(),
      initialZoom: initialZoom ?? 5,
      backgroundColor: backgroundColor ?? const Color(0x00000000),
      // For values of 2 and less, the polygons displayed on the map bug out -
      // this is due to the fact that polygons for maximum longitude and minimum longitude are visible at the same time,
      // and flutter_map incorrectly analyzes them and tries to merge them together.
      minZoom: minZoom ?? 3.8,
      maxZoom: maxZoom ?? 13,
      onTap: onTap,
      cameraConstraint: cameraConstraint ??
          CameraConstraint.contain(
            bounds:
                LatLngBounds(const LatLng(85, -180), const LatLng(-85, 180)),
          ),
      initialCenter: center ?? const LatLng(50.5, 30.51),
      keepAlive: keepAlive,
      initialCameraFit: initialCameraFit,
    );
  }

  Widget buildMapObjectPreview(
    BuildContext context, {
    required MapObject mapObject,
    MapController? controller,
    Color? polygonColor,
    double? zoom,
  }) {
    LatLngBounds? bounds;
    if (mapObject is Country) {
      bounds =
          mapObject.bounds(cutOffFarPolygons: true, distance: 200).scale(1.2);
    }
    if (mapObject is MarineArea) {
      bounds = mapObject.bounds();
    }
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.none,
      ),
      keepAlive: false,
      initialCameraFit: CameraFit.bounds(
        bounds: bounds!,
      ),
      initialZoom: zoom,
      minZoom: zoom,
      center: mapObject.center,
    );

    final layers = [
      PolygonLayer(
        polygonCulling: true,
        polygons: mapObject.polygons.map((points) {
          return Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.miter,
            points: points,
            color: polygonColor ??
                Theme.of(context).colorScheme.outline.withOpacity(0.1),
            isFilled: true,
          );
        }).toList(),
        polygonLabels: false,
      )
    ];

    return Map.noBorder(
      mapOptions: mapOptions,
      layers: layers,
      controller: controller,
    );
  }

  Widget buildRegionsMapPreview(
    BuildContext context, {
    required Country country,
    required List<Region> regions,
    required void Function(TapPosition, LatLng) onTap,
    required MapController controller,
    required Region? selectedRegion,
    required double minZoom,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      keepAlive: false,
      minZoom: minZoom,
      maxZoom: 9,
      initialCameraFit: CameraFit.bounds(
          bounds: country.bounds(cutOffFarPolygons: true)
            ..scale(1.005).toSquare()),
      cameraConstraint: CameraConstraint.containCenter(
        bounds: country.bounds().scale(1.01).toSquare(),
      ),
      onTap: onTap,
    );

    final List<Polygon> polygons = [];

    for (var points in country.polygons) {
      polygons.add(Polygon(
        strokeCap: StrokeCap.butt,
        strokeJoin: StrokeJoin.miter,
        points: points,
        color: const Color(0x00000000),
        isFilled: false,
        borderColor: Theme.of(context).colorScheme.outline,
        borderStrokeWidth: 1.0,
      ));
    }

    for (Region region in regions) {
      Color color = Theme.of(context).colorScheme.outline.withOpacity(0.1);
      if (region.status != MOStatus.none) {
        color = region.status.color(context);
      }
      double strokeWidth = region == selectedRegion ? 2.0 : 0.5;
      polygons.addAll(
        region.polygons.map(
          (polygon) => Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.miter,
            points: polygon,
            color: color.withMultipliedOpacity(0.5),
            borderColor: Theme.of(context).colorScheme.outline,
            borderStrokeWidth: strokeWidth,
            isFilled: true,
          ),
        ),
      );
    }

    final layers = [
      PolygonLayer(
        polygonCulling: true,
        polygons: polygons,
        polygonLabels: false,
      )
    ];

    return Map.noBorder(
      mapOptions: mapOptions,
      layers: layers,
      controller: controller,
    );
  }

  Widget buildWorldMapSummary(
    BuildContext context, {
    required List<Country> countries,
    double? zoom,
    bool withAntarctic = true,
    required Color Function(MOStatus) getCountryColor,
    Color Function(MOStatus)? getCountryBorderColor,
    required double Function(MOStatus) getCountryBorderStrokeWidth,
    MapController? controller,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      initialZoom: zoom ?? 0.45,
      center: LatLng(withAntarctic ? 15.6642 : 43.6642, 0.9432),
      minZoom: 0,
      maxZoom: 10,
      cameraConstraint: const CameraConstraint.unconstrained(),
      keepAlive: false,
    );
    List<Widget> layers = [];
    List<Polygon> polygons = [];

    polygons.addAll(
      Iterable2(
            countries.map((country) {
              final pointsList = country.polygons;
              Color color = country.status.color(context);
              if (country.status == MOStatus.none) {
                color = Colors.black;
              }
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor:
                      getCountryBorderColor?.call(country.status) ?? color,
                  borderStrokeWidth:
                      getCountryBorderStrokeWidth(country.status),
                  isFilled: true,
                  color: getCountryColor(country.status),
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    layers.add(PolygonLayer(
      polygonCulling: true,
      polygons: polygons,
      polygonLabels: false,
    ));

    return Map.noBorder(
      mapOptions: mapOptions,
      layers: layers,
      controller: controller ?? MapController(),
    );
  }

  Widget buildWorldMapUmiSummary(
    BuildContext context, {
    required List<Country> countries,
    required List<MarineArea> marineAreas,
    double? zoom,
    bool withAntarctic = true,
    required Color countryBorderColor,
    required Color Function(MOStatus) getMarineAreaColor,
    Color Function(MOStatus)? getMarineAreaBorderColor,
    required double Function(MOStatus) getMarineAreaBorderStrokeWidth,
    MapController? controller,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      initialZoom: zoom ?? 0.45,
      center: LatLng(withAntarctic ? 15.6642 : 43.6642, 0.9432),
      minZoom: 0,
      maxZoom: 10,
      cameraConstraint: const CameraConstraint.unconstrained(),
      keepAlive: false,
    );
    List<Widget> layers = [];
    List<Polygon> polygons = [];

    polygons.addAll(
      Iterable2(
            countries.map((country) {
              final pointsList = country.polygons;
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor: countryBorderColor,
                  borderStrokeWidth: 0.3,
                  isFilled: false,
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    polygons.addAll(
      Iterable2(
            marineAreas.map((marineArea) {
              final pointsList = marineArea.polygons;
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor:
                      getMarineAreaBorderColor?.call(marineArea.status) ??
                          marineArea.status.color(context),
                  borderStrokeWidth:
                      getMarineAreaBorderStrokeWidth(marineArea.status),
                  isFilled: true,
                  color: getMarineAreaColor(marineArea.status),
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    layers.add(PolygonLayer(
      polygonCulling: true,
      polygons: polygons,
      polygonLabels: false,
    ));

    return Map.noBorder(
      mapOptions: mapOptions,
      layers: layers,
      controller: controller ?? MapController(),
    );
  }

  Widget buildMarine(
    BuildContext context, {
    required String urlTemplate,
    required List<MarineArea> marineAreas,
    required MapController controller,
    void Function(TapPosition, LatLng)? onTap,
    required String? dir,
    required Key key,
    required LatLng? center,
    required Key polygonsLayerKey,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      onTap: onTap,
      center: center,
      maxZoom: 10,
      minZoom: 3,
    );
    List<Widget> layers = [];
    layers.add(
      TileLayer(
        retinaMode: RetinaMode.isHighDensity(context),
        urlTemplate: urlTemplate,
        additionalOptions: const {
          "accessToken": String.fromEnvironment("map_box_access_token"),
        },
        tileProvider: kDebugMode
            ? null
            : CachedTileProvider(
                // maxStale keeps the tile cached for the given Duration and
                // tries to revalidate the next time it gets requested
                maxStale: const Duration(days: 30),
                cachePolicy: CachePolicy.forceCache,
                store: HiveCacheStore(
                  dir,
                  hiveBoxName:
                      'HiveCacheStore_${locator<ThemeCubit>().type.name}',
                ),
              ),
      ),
    );
    List<Polygon> polygons = [];

    polygons.addAll(
      Iterable2(
            [...marineAreas].map((area) {
              final pointsList = area.polygons;
              Color color = area.status.color(context);
              if (area.status == MOStatus.none) {
                color = Theme.of(context).colorScheme.outline;
              }
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor: color,
                  borderStrokeWidth: 2,
                  isFilled: true,
                  color: color
                      .withOpacity(area.status == MOStatus.none ? 0.1 : 0.5),
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    layers.add(PolygonLayer(
      key: polygonsLayerKey,
      polygonCulling: true,
      polygons: polygons,
      polygonLabels: true,
    ));

    if (center != null) {
      layers.add(
        MarkerLayer(markers: [
          Marker(
            height: 15,
            width: 15,
            point: center,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(RiokoNi.navigatorKey.currentContext!)
                    .colorScheme
                    .primary,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ]),
      );
    }

    return Map(
      key: key,
      mapOptions: mapOptions,
      layers: layers,
      controller: controller,
    );
  }

  Widget buildThemePreview(
    BuildContext context, {
    required String urlTemplate,
    required List<Country> mock,
    required String? dir,
    required bool showRegionsBorders,
    required ThemeData theme,
    required ThemeDataType themeType,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      center: const LatLng(52.079025, 18.978023),
      initialZoom: 5,
    );
    List<Widget> layers = [];
    layers.add(
      TileLayer(
        retinaMode: RetinaMode.isHighDensity(context),
        urlTemplate: urlTemplate,
        additionalOptions: const {
          "accessToken": String.fromEnvironment("map_box_access_token"),
        },
        tileProvider: kDebugMode
            ? null
            : CachedTileProvider(
                // maxStale keeps the tile cached for the given Duration and
                // tries to revalidate the next time it gets requested
                maxStale: const Duration(days: 30),
                cachePolicy: CachePolicy.forceCache,
                store: HiveCacheStore(
                  dir,
                  hiveBoxName: 'HiveCacheStore_${themeType.name}',
                ),
              ),
      ),
    );
    List<Polygon> polygons = [];
    List<Region> regions = [];

    polygons.addAll(
      Iterable2(
            mock.map((country) {
              final pointsList = country.polygons;
              Color color = country.status.color(context);
              if (country.displayRegions) {
                regions.addAll(country.regions);
                color = theme.colorScheme.outline;
              }
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor: color,
                  borderStrokeWidth: 0.3,
                  isFilled: !country.displayRegions,
                  color: country.status
                      .color(context, otherTheme: theme)
                      .withMultipliedOpacity(0.4),
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    if (regions.isNotEmpty) {
      for (Region region in regions) {
        for (List<LatLng> polygon
            in region.polygons.sublist(0, min(3, region.polygons.length))) {
          polygons.add(Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.bevel,
            points: polygon,
            color: region.status
                .color(context, otherTheme: theme)
                .withMultipliedOpacity(0.4),
            borderColor: theme.colorScheme.outline.withOpacity(0.5),
            borderStrokeWidth: region.status == MOStatus.none
                ? (showRegionsBorders ? 0.2 : 0)
                : 0,
            isFilled: true,
          ));
        }
      }
    }

    layers.add(PolygonLayer(
      polygonCulling: true,
      polygons: polygons,
      polygonLabels: false,
    ));

    layers.add(
      MarkerLayer(markers: [
        Marker(
          height: 15,
          width: 15,
          point: const LatLng(54.349283, 18.537055),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(RiokoNi.navigatorKey.currentContext!)
                  .colorScheme
                  .primary,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ]),
    );

    return Map(
      mapOptions: mapOptions,
      layers: layers,
      controller: MapController(),
    );
  }

  Widget build(
    BuildContext context, {
    required String urlTemplate,
    required List<Country> beenCountries,
    required List<Country> wantCountries,
    required List<Country> livedCountries,
    required MapController controller,
    void Function(TapPosition, LatLng)? onTap,
    required String? dir,
    required Key key,
    required LatLng? center,
    required Key polygonsLayerKey,
    required bool showRegionsBorders,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      onTap: onTap,
      center: center,
      backgroundColor: Theme.of(context).colorScheme.onBackground,
    );
    List<Widget> layers = [];
    layers.add(
      TileLayer(
        retinaMode: RetinaMode.isHighDensity(context),
        urlTemplate: urlTemplate,
        additionalOptions: const {
          "accessToken": String.fromEnvironment("map_box_access_token"),
        },
        tileProvider: kDebugMode
            ? null
            : CachedTileProvider(
                // maxStale keeps the tile cached for the given Duration and
                // tries to revalidate the next time it gets requested
                maxStale: const Duration(days: 30),
                cachePolicy: CachePolicy.forceCache,
                store: HiveCacheStore(
                  dir,
                  hiveBoxName:
                      'HiveCacheStore_${locator<ThemeCubit>().type.name}',
                ),
              ),
      ),
    );
    List<Polygon> polygons = [];
    List<Region> regions = [];

    polygons.addAll(
      Iterable2(
            [...beenCountries, ...livedCountries, ...wantCountries]
                .map((country) {
              final pointsList = country.polygons;
              Color color = country.status.color(context);
              if (country.displayRegions) {
                regions.addAll(country.regions);
                color = Theme.of(context).colorScheme.outline;
              }
              return pointsList.map((points) {
                return Polygon(
                  strokeCap: StrokeCap.butt,
                  strokeJoin: StrokeJoin.miter,
                  points: points,
                  borderColor: color,
                  borderStrokeWidth: 0.3,
                  isFilled: !country.displayRegions,
                  color:
                      country.status.color(context).withMultipliedOpacity(0.4),
                );
              });
            }),
          ).reduceOrNull((value, element) => [...value, ...element]) ??
          [],
    );

    if (regions.isNotEmpty) {
      for (Region region in regions) {
        for (List<LatLng> polygon
            in region.polygons.sublist(0, min(3, region.polygons.length))) {
          polygons.add(Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.bevel,
            points: polygon,
            color: region.status.color(context).withMultipliedOpacity(0.4),
            borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            borderStrokeWidth: region.status == MOStatus.none
                ? (showRegionsBorders ? 0.2 : 0)
                : 0,
            isFilled: true,
          ));
        }
      }
    }

    layers.add(PolygonLayer(
      key: polygonsLayerKey,
      polygonCulling: true,
      polygons: polygons,
      polygonLabels: false,
    ));

    if (center != null) {
      layers.add(
        MarkerLayer(markers: [
          Marker(
            height: 15,
            width: 15,
            point: center,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(RiokoNi.navigatorKey.currentContext!)
                    .colorScheme
                    .primary,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ]),
      );
    }

    return Map.noBorder(
      key: key,
      mapOptions: mapOptions,
      layers: layers,
      controller: controller,
    );
  }
}

class Map extends StatelessWidget {
  final MapOptions mapOptions;
  final List<Widget> layers;
  final MapController? controller;

  final bool boxed;

  const Map({
    required this.mapOptions,
    required this.layers,
    required this.controller,
    super.key,
  }) : boxed = true;

  const Map.noBorder({
    required this.mapOptions,
    required this.layers,
    required this.controller,
    super.key,
  }) : boxed = false;

  @override
  Widget build(BuildContext context) {
    if (!boxed) return _buildMap(context);
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onBackground,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: _buildMap(context),
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      key: key,
      options: mapOptions,
      mapController: controller,
      children: layers,
    );
  }
}
