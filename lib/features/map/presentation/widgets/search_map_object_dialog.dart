import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/marine_area.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class SearchMapObjectDialog extends StatefulWidget {
  final void Function(MapObject) onSelectMapObject;

  const SearchMapObjectDialog({
    required this.onSelectMapObject,
    super.key,
  });

  @override
  State<SearchMapObjectDialog> createState() => _SearchMapObjectDialogState();
}

class _SearchMapObjectDialogState extends State<SearchMapObjectDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late TextEditingController searchController;

  List<MapObject> searchedMapObjects = [];

  final _mapCubit = locator<MapCubit>();

  bool get umi => _mapCubit.mode == RiokoMode.umi;

  Color get borderColor =>
      Theme.of(context).colorScheme.onPrimary.withOpacity(0.8);

  @override
  void initState() {
    isPopping = false;
    searchedMapObjects = umi ? _mapCubit.marineAreas : _mapCubit.countries;
    searchController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  bool isPopping = false;

  String get l10n => 'map.searchDialog';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog.fullscreen(
      backgroundColor: Colors.black54,
      child: Stack(
        children: [
          Column(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      -50 * (1 - _animation.value),
                    ),
                    child: Opacity(
                      opacity: _animation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: AppSizes.paddingDouble,
                    right: AppSizes.paddingDouble,
                    top: size.height * 0.15,
                  ),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(AppSizes.radiusHalf),
                  ),
                  width: double.infinity,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      if (umi) {
                        searchedMapObjects =
                            _mapCubit.marineAreasByString(value);
                      } else {
                        searchedMapObjects = _mapCubit.countriesByString(value);
                      }
                      setState(() {});
                    },
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: borderColor,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusHalf),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: borderColor,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusHalf),
                      ),
                      labelText: tr(
                          '$l10n.labels.${umi ? 'searchMarineArea' : 'searchCountry'}'),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: borderColor),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        50 * (1 - _animation.value),
                      ),
                      child: Opacity(
                        opacity: _animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSizes.paddingDouble,
                    ),
                    child: ListView.builder(
                      itemCount: searchedMapObjects.length,
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(
                        bottom: AppSizes.paddingQuadruple,
                      ),
                      itemBuilder: (context, i) {
                        return _buildMapObjectItem(
                          context,
                          mapObject: searchedMapObjects.elementAt(i),
                        );
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.paddingDouble,
                  horizontal: AppSizes.paddingDouble,
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        50 * (1 - _animation.value),
                        0,
                      ),
                      child: Opacity(
                        opacity: _animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: pop,
                    child: Icon(
                      FontAwesomeIcons.circleXmark,
                      color: Theme.of(context).primaryColor,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void pop() {
    if (isPopping) return;
    isPopping = true;
    _controller.reverse();
    Future.delayed(
      const Duration(milliseconds: 600),
      Navigator.of(context).pop,
    );
  }

  Widget _buildMapObjectItem(
    BuildContext context, {
    required MapObject mapObject,
  }) {
    String subtitle = '';
    Widget? leading;
    if (mapObject is Country) {
      final subArea = mapObject.subArea?.name;
      subtitle =
          '${mapObject.area.name} ${subArea == null ? '' : '- $subArea'}';
      leading = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: mapObject.flag(scale: 0.5),
      );
    }
    if (mapObject is MarineArea) {
      subtitle = mapObject.typeName;
    }
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingDouble,
        vertical: AppSizes.paddingHalf,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.1),
        border: Border.all(
          color: borderColor,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusHalf),
      ),
      child: ListTile(
        onTap: () {
          pop();
          widget.onSelectMapObject(mapObject);
        },
        leading: leading,
        title: Text(
          mapObject.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
