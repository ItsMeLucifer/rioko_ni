import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/about_app_dialog.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/widgets/change_theme_dialog.dart';
import 'package:rioko_ni/core/presentation/widgets/toast.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/features/map/presentation/pages/info_page.dart';
import 'package:rioko_ni/features/map/presentation/widgets/share_world_data_dialog.dart';
import 'package:rioko_ni/main.dart';
import 'package:url_launcher/url_launcher.dart';

class RiokoMenu extends StatefulWidget {
  final void Function() restartMapKeys;

  const RiokoMenu({
    required this.restartMapKeys,
    super.key,
  });

  @override
  State<RiokoMenu> createState() => _RiokoMenuState();
}

class _RiokoMenuState extends State<RiokoMenu> {
  String get l10n => 'drawer';

  final _revenueCatCubit = locator<RevenueCatCubit>();

  bool loadingPurchase = false;

  Widget get divider => const Divider(
        endIndent: AppSizes.paddingDouble,
        indent: AppSizes.paddingDouble,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
          bottom: AppSizes.paddingSeptuple,
          top: AppSizes.paddingQuadruple,
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_revenueCatCubit.isPremium) ...[
                  divider,
                  ListTile(
                    leading: const Icon(FontAwesomeIcons.gem),
                    title: Text(
                      tr('$l10n.labels.buyPremium'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    trailing: loadingPurchase
                        ? const CircularProgressIndicator.adaptive()
                        : null,
                    onTap: () {
                      setState(() => loadingPurchase = true);
                      _revenueCatCubit.purchasePremium().then((_) => setState(
                            () => loadingPurchase = false,
                          ));
                    },
                  ),
                ],
                divider,
                ListTile(
                  leading: const Icon(FontAwesomeIcons.chartPie),
                  title: Text(
                    tr('$l10n.labels.showStatistics'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InfoPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.shareNodes),
                  title: Text(
                    tr('$l10n.labels.shareStatistics'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  onTap: () {
                    showGeneralDialog(
                      barrierColor: Colors.black.withOpacity(0.5),
                      context: context,
                      pageBuilder: (context, animation1, animation2) =>
                          const ShareWorldDataDialog(),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.paintRoller),
                  title: Text(
                    tr('$l10n.labels.changeTheme'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangeThemePage(
                          restartMapKeys: widget.restartMapKeys,
                        ),
                      ),
                    );
                  },
                ),
                divider,
                ListTile(
                  leading: const Icon(FontAwesomeIcons.circleInfo),
                  title: Text(
                    tr('$l10n.labels.aboutApp'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    const AboutAppDialog().show(context);
                  },
                ),
                ListTile(
                  leading: const Icon(FontAwesomeIcons.shieldHalved),
                  title: Text(
                    tr('$l10n.labels.privacyPolicy'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  onTap: () async {
                    try {
                      await launchUrl(Uri.parse(
                          'https://www.freeprivacypolicy.com/live/a5ed11ff-966d-4ba8-97f7-ede0a81bfb62'));
                    } catch (e) {
                      ToastBuilder(
                        message: tr(
                          'core.errors.launchUrl',
                          args: [tr('$l10n.labels.privacyPolicy')],
                        ),
                      ).show(RiokoNi.navigatorKey.currentContext!);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: context.width(0.5),
          child: Image.asset(AssetsHandler.textLogo),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingDouble),
          child: Text('Odkryj świat!'),
        ),
      ],
    );
  }
}
