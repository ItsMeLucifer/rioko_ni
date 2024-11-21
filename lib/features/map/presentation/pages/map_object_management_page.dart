import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/extensions/latlng_bounds2.dart';
import 'package:rioko_ni/core/extensions/string2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class MapObjectManagementPage extends StatefulWidget {
  final MapObject mapObject;

  const MapObjectManagementPage({
    required this.mapObject,
    super.key,
  });

  @override
  State<MapObjectManagementPage> createState() =>
      _MapObjectManagementPageState();
}

class _MapObjectManagementPageState extends State<MapObjectManagementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late MapController _mapObjectPreviewMapController;
  late MapController _regionsPreviewMapController;

  bool isPopping = false;

  String get l10n => 'map.countryManagement';

  Region? _region;

  bool get umi => _mapCubit.mode == RiokoMode.umi;

  bool get regionsMode =>
      (widget.mapObject as Country).displayRegions &&
      (widget.mapObject as Country).moreDataAvailable;

  final _mapCubit = locator<MapCubit>();

  @override
  void initState() {
    if (!umi) {
      _region = (widget.mapObject as Country)
          .regions
          .firstWhereOrNull((r) => r.status != MOStatus.none);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _mapObjectPreviewMapController = MapController();
    _regionsPreviewMapController = MapController();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });

    _animation.addListener(() {
      if (_animation.value >= 0.4) {
        setState(() {});
      }
    });
    isPopping = false;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapObjectPreviewMapController.dispose();
    _regionsPreviewMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapCubit, MapState>(
      listener: (context, state) {
        state.maybeWhen(
          fetchedRegions: (regions) {
            setState(() => _region = regions[regions.length ~/ 2]);
          },
          orElse: () {},
        );
      },
      child: Stack(
        children: [
          Scaffold(
            body: Stack(children: [
              _buildBody(context),
              BlocBuilder<MapCubit, MapState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    fetchingRegions: () => Container(
                      width: context.width(),
                      height: context.height(),
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            ]),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!umi && (widget.mapObject as Country).moreDataAvailable)
                  FloatingActionButton.extended(
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final value =
                          !(widget.mapObject as Country).displayRegions;
                      if (value &&
                          (widget.mapObject as Country).regions.isEmpty) {
                        _mapCubit
                            .fetchCountryRegions((widget.mapObject as Country));
                      }
                      _mapCubit.updateDisplayRegionsInfo(
                        (widget.mapObject as Country).alpha3,
                        value,
                      );
                      setState(() =>
                          (widget.mapObject as Country).displayRegions = value);
                    },
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        (widget.mapObject as Country).displayRegions
                            ? tr('$l10n.labels.hideRegions')
                            : tr('$l10n.labels.showRegions'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.labelMedium,
                      ),
                    ),
                  ),
                const SizedBox(width: AppSizes.paddingTriple),
                FloatingActionButton.extended(
                  onPressed: () => pop(context, short: true),
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      tr('core.dialog.confirm'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!umi && regionsMode) {
      return _buildRegionsContent(context);
    }
    return _buildMapObjectContent(context);
  }

  // Country
  Widget _buildMapObjectContent(BuildContext context) {
    return Stack(
      children: [
        _buildMapObjectMiniature(context),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingDouble,
              AppSizes.paddingDouble,
              AppSizes.paddingDouble,
              AppSizes.paddingHalf,
            ),
            child: Column(
              children: [
                _buildMapObjectInfo(context),
                Expanded(
                  child: _buildStatusButtons(context, target: widget.mapObject),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapObjectInfo(BuildContext context) {
    String subtitle = '';
    if (widget.mapObject is Country) {
      final subArea = (widget.mapObject as Country).subArea?.name;
      subtitle =
          '${(widget.mapObject as Country).area.name} ${subArea == null ? '' : '- $subArea'}';
    }
    if (umi) {
      subtitle = (widget.mapObject as MarineArea).typeName;
    }

    return Column(children: [
      Text(
        widget.mapObject.name,
        style: Theme.of(context).textTheme.headlineLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSizes.paddingHalf),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSizes.padding),
      widget.mapObject.flag(
        scale: 0.4,
        borderColor: Theme.of(context).colorScheme.outline,
        borderRadius: 3,
      ),
    ]);
  }

  Widget _buildMapObjectMiniature(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: MapBuilder().buildMapObjectPreview(
        context,
        mapObject: widget.mapObject,
        controller: _mapObjectPreviewMapController,
      ),
    );
  }

  // Region

  Widget _buildRegionsContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingDouble,
          AppSizes.paddingDouble,
          AppSizes.paddingDouble,
          AppSizes.paddingHalf,
        ),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildMapObjectInfo(context),
                _buildRegionsPreview(context),
                if (_region != null) _buildRegionInfo(context),
                const SizedBox(height: AppSizes.padding),
                if (_region != null)
                  _buildStatusButtons(
                    context,
                    target: _region!,
                    onPressed: (_) {
                      (widget.mapObject as Country).calculateStatus();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionInfo(BuildContext context) {
    String regionName = tr('regions.${_region!.type}');
    if (!trExists('regions.${_region!.type}')) {
      regionName = tr('regions.region');
    }
    return Column(
      children: [
        Text(
          _region!.name.toTitleCase(),
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingHalf),
        Text(
          regionName.toTitleCase(),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegionsPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: AppSizes.paddingQuadruple,
        bottom: AppSizes.paddingDouble,
      ),
      height: context.width(0.7),
      child: MapBuilder().buildRegionsMapPreview(
        context,
        country: (widget.mapObject as Country),
        regions: (widget.mapObject as Country).regions,
        controller: _regionsPreviewMapController,
        onTap: (tapPosition, latLng) {
          final region = (widget.mapObject as Country)
              .regions
              .firstWhereOrNull((region) => region.contains(latLng));
          if (_region == region) {
            return setState(() => _region = null);
          }
          _region = region;
          setState(() {});
        },
        selectedRegion: _region,
        minZoom: widget.mapObject.bounds().zoom(Size(
                  context.width(),
                  context.width(0.7),
                )) -
            1,
      ),
    );
  }

  // Common

  Widget _buildStatusButtons(
    BuildContext context, {
    required MapObject target,
    void Function(MOStatus)? onPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -50 * (1 - _animation.value),
                  0,
                ),
                child: Opacity(opacity: _animation.value, child: child),
              );
            },
            child: _buildButton(
              context,
              icon: FontAwesomeIcons.trophy,
              onPressed: () {
                if (target.status == MOStatus.been) {
                  target.status = MOStatus.none;
                } else {
                  target.status = MOStatus.been;
                }
                onPressed?.call(target.status);
                setState(() {});
              },
              label: tr('$l10n.labels.been'),
              color: MOStatus.been.color(context),
              selected: target.status == MOStatus.been,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  50 * (1 - _animation.value),
                ),
                child: Opacity(opacity: _animation.value, child: child),
              );
            },
            child: _buildButton(
              context,
              icon: FontAwesomeIcons.suitcase,
              onPressed: () {
                if (target.status == MOStatus.want) {
                  target.status = MOStatus.none;
                } else {
                  target.status = MOStatus.want;
                }
                onPressed?.call(target.status);
                setState(() {});
              },
              label: tr('$l10n.labels.want'),
              color: MOStatus.want.color(context),
              selected: target.status == MOStatus.want,
            ),
          ),
        ),
        if (!umi)
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    50 * (1 - _animation.value),
                    0,
                  ),
                  child: Opacity(opacity: _animation.value, child: child),
                );
              },
              child: _buildButton(
                context,
                icon: FontAwesomeIcons.houseFlag,
                onPressed: () {
                  if (target.status == MOStatus.lived) {
                    target.status = MOStatus.none;
                  } else {
                    target.status = MOStatus.lived;
                  }

                  onPressed?.call(target.status);
                  setState(() {});
                },
                label: tr('$l10n.labels.lived'),
                color: MOStatus.lived.color(context),
                selected: target.status == MOStatus.lived,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required void Function() onPressed,
    required String label,
    required Color color,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 35,
              ),
              const SizedBox(height: AppSizes.padding),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _animation.value > 0.4 ? 1 : 0,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void pop(BuildContext context, {bool short = false}) {
    if (isPopping) return;
    if (!umi) {
      _mapCubit.updateCountryStatus(
        country: widget.mapObject as Country,
        status: widget.mapObject.status,
      );
      if ((widget.mapObject as Country).displayRegions) {
        _mapCubit.saveRegionsLocally();
      }
    } else {
      _mapCubit.updateMarineAreaStatus(
        marineArea: widget.mapObject as MarineArea,
        status: widget.mapObject.status,
      );
    }
    if (widget.mapObject is Country &&
        widget.mapObject.status == MOStatus.none) {
      for (var region in (widget.mapObject as Country).regions) {
        region.status = MOStatus.none;
      }
    }
    isPopping = true;
    _controller.reverse();
    Future.delayed(
      Duration(milliseconds: short ? 100 : 300),
      Navigator.of(context).pop,
    );
  }
}
