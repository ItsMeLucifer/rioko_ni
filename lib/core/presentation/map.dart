import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:rioko_ni/core/extensions/iterable2.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/main.dart';

class MapBuilder {
  MapOptions getMapOptions({
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    Color? backgroundColor,
    InteractionOptions? interactionOptions,
    void Function(TapPosition, LatLng)? onTap,
  }) {
    return MapOptions(
      interactionOptions: interactionOptions,
      initialZoom: initialZoom ?? 5,
      backgroundColor: backgroundColor ?? const Color(0x00000000),
      // Smallest possible number. For values of 2 and less, the polygons displayed on the map bug out -
      // this is due to the fact that polygons for maximum longitude and minimum longitude are visible at the same time,
      // and flutter_map incorrectly analyzes them and tries to merge them together.
      minZoom: minZoom ?? 3,
      maxZoom: maxZoom ?? 17,
      onTap: onTap,
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
  }) {
    final mapOptions = getMapOptions(
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      onTap: onTap,
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
                maxStale: const Duration(days: 365),
                store: HiveCacheStore(
                  dir,
                  hiveBoxName: 'HiveCacheStore',
                ),
              ),
      ),
    );
    layers.add(
      PolygonLayer(
        polygonCulling: true,
        polygonLabels: false,
        polygons: [
          ...Iterable2(beenCountries.map((country) => country.polygons(
                        borderColor: country.status.color,
                      )))
                  .reduceOrNull((value, element) => [...value, ...element]) ??
              [],
          ...Iterable2(wantCountries.map((country) => country.polygons(
                        borderColor: country.status.color,
                      )))
                  .reduceOrNull((value, element) => [...value, ...element]) ??
              [],
          ...Iterable2(livedCountries.map((country) => country.polygons(
                        borderColor: country.status.color,
                      )))
                  .reduceOrNull((value, element) => [...value, ...element]) ??
              [],
        ],
      ),
    );
    layers.add(
      CurrentLocationLayer(
        alignDirectionOnUpdate: AlignOnUpdate.never,
        headingStream: null,
        style: LocationMarkerStyle(
          marker: DefaultLocationMarker(
            color: Theme.of(RiokoNi.navigatorKey.currentContext!)
                .colorScheme
                .primary,
          ),
          markerSize: const Size.square(15),
          headingSectorColor: Colors.transparent,
          accuracyCircleColor: Colors.transparent,
        ),
      ),
    );

    return Map(
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
  const Map({
    required this.mapOptions,
    required this.layers,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 33, 70, 54),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: _buildMap(context),
    );
  }

  Widget _buildMap(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      mapController: controller,
      children: layers,
    );
  }
}
