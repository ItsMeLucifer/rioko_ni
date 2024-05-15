import 'package:flutter/material.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/presentation/widgets/share_world_data_dialog.dart';

class SharePage extends StatelessWidget {
  const SharePage({super.key});

  void showWorldDialog(BuildContext context) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      pageBuilder: (context, animation1, animation2) =>
          const ShareWorldDataDialog(),
    );
  }

  static const double shadowValue = 1.0;
  static const double shadowBlurRadius = 2.5;

  static const List<Shadow> shadows = [
    Shadow(
      offset: Offset(shadowValue, shadowValue),
      blurRadius: shadowBlurRadius,
    ),
    Shadow(
      offset: Offset(-shadowValue, shadowValue),
      blurRadius: shadowBlurRadius,
    ),
    Shadow(
      offset: Offset(shadowValue, -shadowValue),
      blurRadius: shadowBlurRadius,
    ),
    Shadow(
      offset: Offset(-shadowValue, -shadowValue),
      blurRadius: shadowBlurRadius,
    ),
  ];

  static const double indent = 10.0;

  Color buttonColor(BuildContext context) =>
      Theme.of(context).colorScheme.shadow.withOpacity(0.05);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: context.height(),
        width: context.width(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Share', style: Theme.of(context).textTheme.headlineLarge),
                Container(
                  width: context.width(),
                  height: 50,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingDouble,
                    vertical: AppSizes.paddingDouble,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor(context),
                    borderRadius: BorderRadius.circular(AppSizes.radiusHalf),
                    image: DecorationImage(
                      image: AssetImage(AssetsHandler.worldMiniature),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'All world',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(shadows: shadows),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Expanded(
                      child: Divider(
                        indent: indent,
                        endIndent: indent,
                      ),
                    ),
                    Text('Continents'),
                    Expanded(
                      child: Divider(
                        indent: indent,
                        endIndent: indent,
                      ),
                    ),
                  ],
                ),
                GridView.builder(
                  itemCount: Area.values.length - 1,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final continent =
                        ([...Area.values]..remove(Area.antarctic))[index];

                    return Container(
                      height: 200,
                      width: 200,
                      padding: const EdgeInsets.all(AppSizes.paddingTriple),
                      margin: const EdgeInsets.all(AppSizes.padding),
                      decoration: BoxDecoration(
                        color: buttonColor(context),
                        borderRadius:
                            BorderRadius.circular(AppSizes.enormousRadius),
                        image: DecorationImage(
                          image: AssetImage(continent.imagePath),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          continent.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(shadows: shadows),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
