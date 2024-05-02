import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/color2.dart';
import 'package:rioko_ni/core/extensions/iterable2.dart';
import 'package:rioko_ni/core/extensions/latlng_bounds2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
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

  Widget buildCountryMapPreview(
    BuildContext context, {
    required Country country,
    required MapController controller,
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.none,
      ),
      keepAlive: false,
      initialCameraFit: CameraFit.bounds(
        bounds: country.bounds,
      ),
    );

    final layers = [
      PolygonLayer(
        polygonCulling: true,
        polygons: country.polygons.map((points) {
          return Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.miter,
            points: points,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
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
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      keepAlive: false,
      initialCameraFit: CameraFit.bounds(
        bounds: country.bounds,
        padding: const EdgeInsets.all(AppSizes.paddingDouble),
      ),
      maxZoom: 10,
      cameraConstraint: CameraConstraint.contain(
        bounds: country.bounds.scale(1.3),
      ),
      onTap: onTap,
    );

    final layers = [
      PolygonLayer(
        polygonCulling: true,
        polygons: [
          ...country.polygons.map((points) {
            return Polygon(
              strokeCap: StrokeCap.butt,
              strokeJoin: StrokeJoin.miter,
              points: points,
              color: const Color(0x00000000),
              isFilled: false,
              borderColor: Theme.of(context).colorScheme.outline,
              borderStrokeWidth: 1.0,
            );
          }),
          ...regions.map((region) {
            Color color = const Color(0x00000000);
            if (region.status != MOStatus.none) {
              color = region.status.color(context);
            }
            return Polygon(
              strokeCap: StrokeCap.butt,
              strokeJoin: StrokeJoin.miter,
              points: region.polygon,
              color: color.withOpacity(0.3),
              borderColor: Theme.of(context).colorScheme.outline,
              borderStrokeWidth: region == selectedRegion ? 2.0 : 0.5,
              isFilled: true,
            );
          }),
        ],
        polygonLabels: false,
      )
    ];

    return Map.noBorder(
      mapOptions: mapOptions,
      layers: layers,
      controller: controller,
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
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      onTap: onTap,
      center: center,
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
                  borderStrokeWidth: 0.5,
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
      polygons.addAll(
        regions.map((r) {
          return Polygon(
            strokeCap: StrokeCap.butt,
            strokeJoin: StrokeJoin.bevel,
            points: r.polygon,
            color: r.status.color(context).withMultipliedOpacity(0.4),
            borderColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            borderStrokeWidth: r.status == MOStatus.none ? 0.5 : 0,
            isFilled: true,
          );
        }).toList(),
      );
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

    return Map(
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
