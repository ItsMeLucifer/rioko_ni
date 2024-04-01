import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/iterable2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/widgets/share_dialog.dart';
import 'package:rioko_ni/main.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class RiokoDrawer extends StatelessWidget {
  final bool showWorldStatistics;
  final void Function() openTopBehindDrawer;

  RiokoDrawer({
    required this.openTopBehindDrawer,
    required this.showWorldStatistics,
    super.key,
  });

  String get l10n => 'drawer';

  final _cubit = locator<MapCubit>();
  final _themeCubit = locator<ThemeCubit>();

  Widget get divider => const Divider(
        endIndent: AppSizes.paddingDouble,
        indent: AppSizes.paddingDouble,
      );

  Color mapBorderColor(BuildContext context) {
    switch (_themeCubit.type) {
      case ThemeDataType.classic:
        return Colors.black;
      case ThemeDataType.dark:
      case ThemeDataType.monochrome:
        return Theme.of(context).colorScheme.onPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSizes.paddingSeptuple,
          top: AppSizes.paddingQuadruple,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: SimpleMap(
                instructions: SMapWorld.instructionsMercator,
                defaultColor: Theme.of(context).colorScheme.background,
                countryBorder: CountryBorder(color: mapBorderColor(context)),
                colors: _cubit.countries
                    .where((c) => c.status != CountryStatus.none)
                    .map(
                      (c) => {
                        c.alpha2.toLowerCase(): c.status.color.withOpacity(0.3),
                      },
                    )
                    .reduceOrNull((value, element) => {...value, ...element}),
              ),
            ),
            divider,
            ListTile(
              leading: const Icon(FontAwesomeIcons.chartPie),
              title: Text(
                tr('$l10n.labels.showStatistics'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onTap: () {
                Navigator.of(context).pop();
                openTopBehindDrawer();
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.shareNodes),
              title: Text(
                tr('$l10n.labels.shareStatistics'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onTap: () {
                Navigator.of(context).pop();
                showGeneralDialog(
                  barrierColor: Colors.black.withOpacity(0.5),
                  context: context,
                  pageBuilder: (context, animation1, animation2) =>
                      const ShareDialog(),
                );
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.paintRoller),
              title: Text(
                tr('$l10n.labels.changeTheme'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            divider,
            ListTile(
              leading: const Icon(FontAwesomeIcons.shieldHalved),
              title: Text(
                tr('$l10n.labels.privacyPolicy'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              onTap: () async {
                final success = await launchUrl(Uri.parse(
                    'https://www.dropbox.com/scl/fi/zdfck2mcc2e8p46ve74ak/rioko_privacy_policy.pdf?rlkey=fzphc0bux0gn07ccjrgnilcir&dl=0'));
                if (success) {
                  toastification.show(
                    context: RiokoNi.navigatorKey.currentContext!,
                    type: ToastificationType.error,
                    style: ToastificationStyle.minimal,
                    title: Text(tr('core.errorMessageTitle')),
                    description: Text(tr('core.errors.launchUrl',
                        args: [tr('$l10n.labels.privacyPolicy')])),
                    autoCloseDuration: const Duration(seconds: 5),
                    alignment: Alignment.topCenter,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
