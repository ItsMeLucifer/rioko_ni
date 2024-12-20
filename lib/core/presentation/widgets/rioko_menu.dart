import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/about_app_dialog.dart';
import 'package:rioko_ni/core/presentation/cubit/admob_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/widgets/change_theme_page.dart';
import 'package:rioko_ni/core/presentation/widgets/toast.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
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
  final _mapCubit = locator<MapCubit>();
  final _admobCubit = locator<AdmobCubit>();

  bool get umi => _mapCubit.mode == RiokoMode.umi;

  bool loadingPurchase = false;

  Widget divider(BuildContext context) => SizedBox(
        width: context.width(0.7),
        child: Divider(
          color: Theme.of(context).dividerColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: context.width(),
            height: context.height(),
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
                          _revenueCatCubit
                              .purchasePremium()
                              .then((_) => setState(
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
                      onTap: umi
                          ? null
                          : () {
                              showGeneralDialog(
                                barrierColor: Colors.black.withOpacity(0.5),
                                context: context,
                                pageBuilder:
                                    (context, animation1, animation2) =>
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
                    const SizedBox(height: AppSizes.padding),
                    _buildTile(
                      context,
                      iconData:
                          umi ? FontAwesomeIcons.plane : FontAwesomeIcons.water,
                      onTap: () => setState(() => _mapCubit.toggleMode()),
                      label: umi ? 'Rioko Classic' : 'Rioko UMI',
                    ),
                    divider(context),
                    _buildTile(
                      context,
                      iconData: FontAwesomeIcons.circleInfo,
                      onTap: () {
                        Navigator.of(context).pop();
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
                    const SizedBox(height: AppSizes.padding),
                    FloatingActionButton.extended(
                      onPressed: () => Navigator.of(context).pop(),
                      label: SizedBox(
                        width: 100,
                        child: Text(
                          tr('core.dialog.close'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          _buildAdBanner(context),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required void Function()? onTap,
    required IconData iconData,
    required String label,
    Widget? trailing,
  }) {
    bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: context.width(0.7),
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              iconData,
              color: Theme.of(context)
                  .iconTheme
                  .color!
                  .withOpacity(enabled ? 1 : 0.3),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .color!
                        .withOpacity(enabled ? 1 : 0.3),
                  ),
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
          SizedBox(
            height: 101,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildLogo(context),
                if (_mapCubit.mode == RiokoMode.umi)
                  Align(
                    alignment: const Alignment(1.2, 1),
                    child: Transform.scale(
                      scale: 0.5,
                      child: Transform.rotate(
                        angle: -0.55,
                        child: Image.asset(
                          AssetsHandler.umiLogo,
                          color: Colors.blue,
                          colorBlendMode: BlendMode.modulate,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
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

  Widget _buildLogo(BuildContext context) {
    Widget logo = Image.asset(AssetsHandler.textLogoLight);
    if (!_themeCubit.isLight) {
      logo = Image.asset(
        AssetsHandler.textLogoDark,
        colorBlendMode: BlendMode.modulate,
        color: Theme.of(context).primaryTextTheme.headlineLarge!.color,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingQuadruple,
          vertical: AppSizes.paddingDouble),
      child: logo,
    );
  }

  Widget _buildAdBanner(BuildContext context) {
    final banner = _admobCubit.riokoMenuBanner;
    if (banner == null) return const SizedBox.shrink();
    return BlocBuilder<AdmobCubit, AdmobState>(
      builder: (context, state) {
        return state.maybeWhen(
          loadingAds: () => const Center(
            child: SizedBox(
              height: 50,
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
          loadedAds: (_) => Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}
