import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/iterable2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/pages/country_management_page.dart';
import 'package:rioko_ni/features/map/presentation/pages/info_page.dart';
import 'package:rioko_ni/features/map/presentation/widgets/share_dialog.dart';

class WorldStatisticsMap extends StatelessWidget {
  final double naPercentage;
  final double saPercentage;
  final double euPercentage;
  final double afPercentage;
  final double asPercentage;
  final double ocPercentage;
  final void Function() onTapButton;

  WorldStatisticsMap({
    required this.naPercentage,
    required this.saPercentage,
    required this.euPercentage,
    required this.afPercentage,
    required this.asPercentage,
    required this.ocPercentage,
    required this.onTapButton,
    super.key,
  });

  String get l10n => 'worldStatisticsMap';

  final _mapCubit = locator<MapCubit>();

  final _themeCubit = locator<ThemeCubit>();

  Color primaryColor(BuildContext context) {
    switch (_themeCubit.type) {
      case ThemeDataType.classic:
      case ThemeDataType.humani:
      case ThemeDataType.neoDark:
        return Theme.of(context).colorScheme.onPrimary;
      case ThemeDataType.monochrome:
        return Colors.white;
    }
  }

  double get countryOpacity {
    switch (_themeCubit.type) {
      case ThemeDataType.classic:
      case ThemeDataType.humani:
        return 0.4;
      case ThemeDataType.neoDark:
      case ThemeDataType.monochrome:
        return 0.3;
    }
  }

  void displayInfoPage(BuildContext context) {
    onTapButton();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InfoPage(
          onTapCountry: (country) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CountryManagementPage(country: country),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Stack(
        children: [
          Container(
            color: Theme.of(context).colorScheme.background,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(
              top: AppSizes.paddingQuintuple,
              bottom: AppSizes.paddingQuadruple,
              left: AppSizes.paddingSextuple,
              right: AppSizes.paddingQuadruple,
            ),
            child: SimpleMap(
              instructions: SMapWorld.instructionsMercator,
              defaultColor: Theme.of(context).colorScheme.background,
              countryBorder: CountryBorder(color: MOStatus.been.color(context)),
              callback: (id, name, tapDetails) => displayInfoPage(context),
              colors: [..._mapCubit.beenCountries, ..._mapCubit.livedCountries]
                  .map(
                    (c) => {
                      c.alpha2.toLowerCase(): Theme.of(context)
                          .colorScheme
                          .onPrimary
                          .withOpacity(c.status == MOStatus.been
                              ? countryOpacity
                              : countryOpacity * 2),
                    },
                  )
                  .reduceOrNull((value, element) => {...value, ...element}),
            ),
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(-0.9, -0.3),
            label: tr('$l10n.northAmerica'),
            percentage: naPercentage,
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(-0.6, 1),
            label: tr('$l10n.southAmerica'),
            percentage: saPercentage,
            footer: true,
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(0.05, -0.7),
            label: tr('$l10n.europe'),
            percentage: euPercentage,
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(0.15, 1),
            label: tr('$l10n.africa'),
            percentage: afPercentage,
            footer: true,
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(0.5, -0.4),
            label: tr('$l10n.asia'),
            percentage: asPercentage,
          ),
          _buildContinentSummary(
            context,
            alignment: const Alignment(0.85, 1),
            label: tr('$l10n.oceania'),
            percentage: ocPercentage,
            footer: true,
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: GestureDetector(
              onTap: () {
                onTapButton();
                showGeneralDialog(
                  barrierColor: Colors.black.withOpacity(0.5),
                  context: context,
                  pageBuilder: (context, animation1, animation2) =>
                      const ShareDialog(),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.paddingDouble),
                child: Icon(FontAwesomeIcons.shareNodes),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => displayInfoPage(context),
                child: const Padding(
                  padding: EdgeInsets.all(AppSizes.paddingDouble),
                  child: Icon(FontAwesomeIcons.expand),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContinentSummary(
    BuildContext context, {
    required Alignment alignment,
    required String label,
    required double percentage,
    bool footer = false,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingDouble),
        child: CircularPercentIndicator(
          key: Key(label),
          radius: 30.0,
          lineWidth: 5.0,
          percent: percentage / 100,
          center: Text(
            "${percentage.toStringAsPrecision(3)}%",
            style: TextStyle(
              color: Theme.of(context).snackBarTheme.actionTextColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          progressColor: primaryColor(context),
          backgroundColor:
              Theme.of(context).colorScheme.onPrimary.withOpacity(0.15),
          circularStrokeCap: CircularStrokeCap.round,
          curve: Curves.fastEaseInToSlowEaseOut,
          animationDuration: 1000,
          animation: true,
          restartAnimation: true,
          header: footer
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.padding),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          footer: footer
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSizes.padding),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
