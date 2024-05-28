import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/extensions/color2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/pages/map_object_management_page.dart';
import 'package:rioko_ni/features/map/presentation/widgets/share_world_data_dialog.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  MOStatus status = MOStatus.been;

  final _cubit = locator<MapCubit>();
  final _themeCubit = locator<ThemeCubit>();

  Area area = Area.world;

  late AnimatedMapController mapController;

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

  Color get borderColor {
    switch (status) {
      case MOStatus.been:
        return Theme.of(context).colorScheme.primary;
      case MOStatus.want:
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  List<Country> get countries {
    switch (status) {
      case MOStatus.been:
        return _cubit.beenCountries;
      case MOStatus.want:
        return _cubit.wantCountries;
      default:
        return _cubit.livedCountries;
    }
  }

  Color mapBorderColor(BuildContext context) {
    switch (_themeCubit.type) {
      case ThemeDataType.classic:
      case ThemeDataType.humani:
        return Colors.black;
      case ThemeDataType.neoDark:
      case ThemeDataType.monochrome:
        return Theme.of(context).colorScheme.onPrimary.withOpacity(1.0);
    }
  }

  TextStyle get nonSelectedText => Theme.of(context)
      .primaryTextTheme
      .bodyMedium!
      .copyWith(color: const Color.fromARGB(255, 206, 211, 255));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MapCubit, MapState>(
        listener: (context, state) {
          state.maybeWhen(
            updatedMapObjectStatus: (country, status) => setState(() {}),
            orElse: () {},
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.paddingDouble,
            right: AppSizes.paddingDouble,
            top: kToolbarHeight,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSizes.paddingQuadruple),
                  child: _buildMap(context),
                ),
                _buildAreaSelectButton(context),
                _buildCountryList(context,
                    countries: countries
                        .where((c) => area == Area.world || c.area == area)
                        .toList()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: Navigator.of(context).pop,
        label: SizedBox(
          width: 50,
          child: Text(
            tr('core.dialog.ok'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAreaSelectButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingQuadruple),
      margin: const EdgeInsets.only(bottom: AppSizes.paddingDouble),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...AreaExtension.fixedValues.map(
              (a) => _areaSelectButton(label: a.name, value: a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaSelectButton({required String label, required Area value}) {
    return GestureDetector(
      onTap: () {
        area = value;
        mapController.animateTo(dest: area.center, zoom: area.zoom);
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingDouble),
        child: Text(
          label,
          style: area == value
              ? Theme.of(context).primaryTextTheme.bodyMedium
              : nonSelectedText,
        ),
      ),
    );
  }

  Widget _buildCountryList(
    BuildContext context, {
    required List<Country> countries,
  }) {
    return Column(
      children: [
        SizedBox(
          width: context.width(0.7),
          child: SegmentedButton<MOStatus>(
            segments: ([...MOStatus.values]..remove(MOStatus.none))
                .map((s) => ButtonSegment(
                      value: s,
                      label: Text(s.name),
                    ))
                .toList(),
            selected: {status},
            style: ButtonStyle(
              textStyle: MaterialStatePropertyAll(
                  Theme.of(context).textTheme.titleSmall),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.black;
                }
                return Theme.of(context).colorScheme.outline;
              }),
              padding: const MaterialStatePropertyAll(EdgeInsets.zero),
              alignment: Alignment.center,
            ),
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => status = value.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSizes.paddingDouble,
          ),
          child: Text(countries.isEmpty
              ? 'No results'
              : '${countries.length} countries'),
        ),
        if (countries.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              left: AppSizes.paddingDouble,
              right: AppSizes.paddingDouble,
              top: AppSizes.paddingDouble,
              bottom: context.height(0.15),
            ),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              border: Border.all(
                color: borderColor,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusHalf),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: countries.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final country = countries[index];
                return ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MapObjectManagementPage(mapObject: country),
                    ),
                  ),
                  leading: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                      ),
                      color: borderColor,
                    ),
                    child: country.flag(scale: 0.5),
                  ),
                  title: Text(
                    country.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    country.area.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMap(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: context.height(0.3),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: MapBuilder().buildWorldMapSummary(
            context,
            countries: _cubit.countries,
            getCountryColor: (status) =>
                status.color(context).withMultipliedOpacity(0.4),
            getCountryBorderColor: (_) => Theme.of(context).colorScheme.outline,
            getCountryBorderStrokeWidth: (status) {
              if (area == Area.world) {
                return status == MOStatus.none ? 0.1 : 0.3;
              }
              return status == MOStatus.none ? 0.3 : 0.6;
            },
            controller: mapController.mapController,
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(AppSizes.radius),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: IconButton(
              onPressed: () {
                showGeneralDialog(
                  barrierColor: Colors.black.withOpacity(0.5),
                  context: context,
                  pageBuilder: (context, animation1, animation2) =>
                      const ShareWorldDataDialog(),
                );
              },
              icon: const Icon(FontAwesomeIcons.share),
            ),
          ),
        )
      ],
    );
  }
}
