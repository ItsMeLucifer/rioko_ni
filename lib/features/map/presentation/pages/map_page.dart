import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/core/presentation/widgets/rioko_menu.dart';
import 'package:rioko_ni/core/presentation/widgets/toast.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/pages/map_object_management_page.dart';
import 'package:rioko_ni/features/map/presentation/widgets/floating_ui.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final _mapCubit = locator<MapCubit>();
  final _themeCubit = locator<ThemeCubit>();

  late AnimatedMapController mapController;

  Key _mapKey = UniqueKey();
  Key _polygonsLayerKey = UniqueKey();

  @override
  void initState() {
    mapController = AnimatedMapController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    super.initState();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: BlocConsumer<MapCubit, MapState>(
        listener: (context, state) {
          state.maybeWhen(
            error: (message) => ToastBuilder(message: message).show(context),
            setCurrentPosition: (position) => mapController.animateTo(
                dest: position, zoom: mapController.mapController.camera.zoom),
            orElse: () {},
          );
        },
        builder: (context, state) {
          return state.maybeWhen(
            orElse: () {
              return Stack(
                children: [
                  _buildMap(context),
                  FloatingUI(
                    onSelectMapObject: (mapObject) {
                      final constrained = CameraFit.bounds(
                        bounds: mapObject.bounds(),
                      ).fit(mapController.mapController.camera);
                      Future.delayed(
                        const Duration(milliseconds: 600),
                        () => mapController.animateTo(
                          dest: constrained.center,
                          zoom: constrained.zoom - 2,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GestureDetector(
        child: SizedBox(
          width: 60,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(AppSizes.radiusDouble),
                color: Theme.of(context).colorScheme.background,
                image: DecorationImage(
                  image: AssetImage(AssetsHandler.appIcon),
                ),
              ),
            ),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RiokoMenu(
              restartMapKeys: () => setState(() {
                _mapKey = UniqueKey();
                _polygonsLayerKey = UniqueKey();
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    if (_mapCubit.mode == RiokoMode.umi) {
      return MapBuilder().buildMarine(
        context,
        urlTemplate: _mapCubit.urlTemplate(),
        marineAreas: _mapCubit.marineAreas,
        controller: mapController.mapController,
        dir: _mapCubit.dir,
        key: _mapKey,
        polygonsLayerKey: _polygonsLayerKey,
        center: _mapCubit.currentPosition,
        onTap: (position, latLng) {
          final marineArea = _mapCubit.getMarineAreaFromPosition(latLng);
          debugPrint(marineArea?.name);
          if (marineArea == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  MapObjectManagementPage(mapObject: marineArea),
            ),
          );
        },
      );
    }

    return MapBuilder().build(
      context,
      key: _mapKey,
      polygonsLayerKey: _polygonsLayerKey,
      urlTemplate: _mapCubit.urlTemplate(),
      beenCountries: _mapCubit.beenCountries,
      wantCountries: _mapCubit.wantCountries,
      livedCountries: _mapCubit.livedCountries,
      center: _mapCubit.currentPosition,
      controller: mapController.mapController,
      onTap: (position, latLng) {
        final country = _mapCubit.getCountryFromPosition(latLng);
        if (country == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MapObjectManagementPage(mapObject: country),
          ),
        );
      },
      dir: _mapCubit.dir,
      showRegionsBorders: !_themeCubit.isLight,
    );
  }
}
