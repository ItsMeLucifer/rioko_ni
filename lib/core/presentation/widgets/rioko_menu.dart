import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/about_app_dialog.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/widgets/change_theme_page.dart';
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
  String get l10n => 'menu';

  final _revenueCatCubit = locator<RevenueCatCubit>();
  final _themeCubit = locator<ThemeCubit>();

  bool loadingPurchase = false;

  Widget divider(BuildContext context) => SizedBox(
        width: context.width(0.62),
        child: Divider(
          color: Theme.of(context).dividerColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          bottom: AppSizes.paddingSeptuple,
          top: AppSizes.paddingQuadruple,
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(context),
                if (!_revenueCatCubit.isPremium) ...[
                  divider(context),
                  _buildTile(
                    context,
                    iconData: FontAwesomeIcons.gem,
                    onTap: () {
                      setState(() => loadingPurchase = true);
                      _revenueCatCubit.purchasePremium().then((_) => setState(
                            () => loadingPurchase = false,
                          ));
                    },
                    trailing: loadingPurchase
                        ? const CircularProgressIndicator.adaptive()
                        : null,
                    label: tr('$l10n.labels.buyPremium'),
                  ),
                ],
                divider(context),
                _buildTile(
                  context,
                  iconData: FontAwesomeIcons.chartPie,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const InfoPage(),
                      ),
                    );
                  },
                  label: tr('$l10n.labels.showStatistics'),
                ),
                const SizedBox(height: AppSizes.padding),
                _buildTile(
                  context,
                  iconData: FontAwesomeIcons.shareNodes,
                  onTap: () {
                    showGeneralDialog(
                      barrierColor: Colors.black.withOpacity(0.5),
                      context: context,
                      pageBuilder: (context, animation1, animation2) =>
                          const ShareWorldDataDialog(),
                    );
                  },
                  label: tr('$l10n.labels.shareStatistics'),
                ),
                const SizedBox(height: AppSizes.padding),
                _buildTile(
                  context,
                  iconData: FontAwesomeIcons.paintRoller,
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ChangeThemePage(
                          restartMapKeys: widget.restartMapKeys,
                        ),
                      ),
                    );
                  },
                  label: tr('$l10n.labels.changeTheme'),
                ),
                divider(context),
                _buildTile(
                  context,
                  iconData: FontAwesomeIcons.circleInfo,
                  onTap: () {
                    Scaffold.of(context).closeDrawer();
                    const AboutAppDialog().show(context);
                  },
                  label: tr('$l10n.labels.aboutApp'),
                ),
                const SizedBox(height: AppSizes.padding),
                _buildTile(
                  context,
                  iconData: FontAwesomeIcons.shieldHalved,
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
                  label: tr('$l10n.labels.privacyPolicy'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        label: SizedBox(
          width: 100,
          child: Text(
            tr('core.dialog.close'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required void Function() onTap,
    required IconData iconData,
    required String label,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: context.width(0.62),
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(iconData),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: context.width(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTextLogo(context),
          Text(
            tr('$l10n.labels.title'),
            style: Theme.of(context).primaryTextTheme.bodyMedium,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppSizes.paddingDouble),
            child: Text(
              tr('$l10n.labels.subtitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextLogo(BuildContext context) {
    if (_themeCubit.isLight) {
      return Text(
        'RIOKO',
        style: Theme.of(context).primaryTextTheme.headlineLarge,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingQuadruple,
          vertical: AppSizes.paddingDouble),
      child: Image.asset(
        AssetsHandler.textLogoDark,
        colorBlendMode: BlendMode.modulate,
        color: Theme.of(context).primaryTextTheme.headlineLarge!.color,
      ),
    );
  }
}
