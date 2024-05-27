import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class ChangeThemePage extends StatefulWidget {
  final void Function() restartMapKeys;

  const ChangeThemePage({
    required this.restartMapKeys,
    super.key,
  });

  @override
  State<ChangeThemePage> createState() => _ChangeThemePageState();
}

class _ChangeThemePageState extends State<ChangeThemePage> {
  final _themeCubit = locator<ThemeCubit>();
  final _mapCubit = locator<MapCubit>();

  String assetPath(ThemeDataType type) {
    switch (type) {
      case ThemeDataType.classic:
        return AssetsHandler.classicMapExample;
      case ThemeDataType.humani:
        return AssetsHandler.humaniMapExample;
      case ThemeDataType.neoDark:
        return AssetsHandler.darkMapExample;
      case ThemeDataType.monochrome:
        return AssetsHandler.monochromeMapExample;
    }
  }

  List<int> freeIndices = [0, 1];

  bool get isOptionAvailable {
    if (_revenueCatCubit.isPremium) return true;
    return freeIndices.contains(selectedIndex);
  }

  bool loadingPurchase = false;

  int selectedIndex = 0;

  final _revenueCatCubit = locator<RevenueCatCubit>();

  ThemeDataType get selectedThemeType => ThemeDataType.values[selectedIndex];

  ThemeData get selectedTheme => _themeCubit.appThemeData(selectedThemeType);

  Color get textColor {
    if (selectedIndex == 0 || selectedIndex == 1) return Colors.black;
    return Colors.white;
  }

  @override
  void initState() {
    selectedIndex = ThemeDataType.values.indexOf(_themeCubit.type);
    if (kDebugMode) {
      freeIndices.addAll([2, 3]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RevenueCatCubit, RevenueCatState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              SizedBox(
                height: context.height(),
                width: context.width(),
                child: MapBuilder().buildThemePreview(
                  context,
                  urlTemplate:
                      _mapCubit.urlTemplate(otherTheme: selectedThemeType),
                  mock: _mapCubit.themePreviewCountries,
                  dir: _mapCubit.dir,
                  showRegionsBorders: !_themeCubit.isLight,
                  theme: selectedTheme,
                  themeType: selectedThemeType,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSaveButton(),
                    const SizedBox(height: AppSizes.paddingDouble),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingDouble),
                      color: Colors.black38,
                      child: GridView.builder(
                        itemCount: ThemeDataType.values.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: AppSizes.paddingHalf,
                        ),
                        padding: const EdgeInsets.only(
                          top: AppSizes.paddingDouble,
                          bottom: AppSizes.paddingQuadruple,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              selectedIndex = index;
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radius),
                                border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              child: Opacity(
                                opacity: selectedIndex == index ? 1.0 : 0.3,
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppSizes.padding),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radius),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        assetPath(ThemeDataType.values[index]),
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.bottomRight,
                                  child: selectedIndex == index
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            ThemeDataType.values[index].title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: textColor),
                                            maxLines: 1,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Theme selection',
                    style: selectedTheme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        if (!isOptionAvailable) {
          setState(() => loadingPurchase = true);
          _revenueCatCubit.purchasePremium().then((_) => setState(
                () => loadingPurchase = false,
              ));
          return;
        }
        Navigator.of(context).pop();
        if (selectedThemeType != _themeCubit.type) {
          _themeCubit.changeTheme(selectedThemeType);
          widget.restartMapKeys();
        }
      },
      child: isOptionAvailable
          ? Text(tr('changeThemeDialog.buttonName'))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('shareDialog.labels.buyPremium')),
                const SizedBox(width: AppSizes.padding),
                if (!loadingPurchase)
                  const Icon(FontAwesomeIcons.lock, size: 15),
                if (loadingPurchase)
                  const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  )
              ],
            ),
    );
  }
}
