import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';

class StatsUI extends StatelessWidget {
  final int been;
  final int want;
  final int lived;
  final void Function() toggleTopBehindDrawer;
  final bool lowerTopUI;

  const StatsUI({
    required this.been,
    required this.want,
    required this.lived,
    required this.toggleTopBehindDrawer,
    required this.lowerTopUI,
    super.key,
  });

  TextStyle get style => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      );

  double getTopMargin(BuildContext context) =>
      AppSizes.paddingTriple +
      (lowerTopUI ? MediaQuery.of(context).size.height * 0.3 : 0);

  String get l10n => 'map.statsUI';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: AnimatedContainer(
            duration: Duration(milliseconds: lowerTopUI ? 500 : 700),
            curve: Curves.fastEaseInToSlowEaseOut,
            margin: EdgeInsets.symmetric(
              vertical: getTopMargin(context),
              horizontal: AppSizes.paddingDouble,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    alignment: Alignment.topCenter,
                    margin: const EdgeInsets.only(right: AppSizes.padding),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.padding,
                      horizontal: AppSizes.paddingTriple,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.7), width: 1),
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "${tr('$l10n.labels.been')}: $been",
                            style: style,
                          ),
                          Text(
                            "${tr('$l10n.labels.want')}: $want",
                            style: style,
                          ),
                          Text(
                            "${tr('$l10n.labels.lived')}: $lived",
                            style: style,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: toggleTopBehindDrawer,
                  child: Container(
                    height: 50,
                    width: 50,
                    margin: const EdgeInsets.only(left: AppSizes.padding),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.7), width: 1),
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                    ),
                    padding: const EdgeInsets.only(bottom: 1),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.chartPie,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
