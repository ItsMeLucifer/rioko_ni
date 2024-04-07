import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/utils/assets_handler.dart';

class ChangeThemeDialog extends StatefulWidget {
  final void Function() updateMap;

  const ChangeThemeDialog({
    required this.updateMap,
    super.key,
  });

  @override
  State<ChangeThemeDialog> createState() => _ChangeThemeDialogState();

  void show(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => this,
      );
      return;
    }
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => this,
    );
  }
}

class _ChangeThemeDialogState extends State<ChangeThemeDialog> {
  final _themeCubit = locator<ThemeCubit>();
  String assetPath(ThemeDataType type) {
    switch (type) {
      case ThemeDataType.classic:
        return AssetsHandler.classicMapExample;
      case ThemeDataType.neoDark:
        return AssetsHandler.darkMapExample;
      case ThemeDataType.monochrome:
        return AssetsHandler.monochromeMapExample;
    }
  }

  List<int> freeIndices = [0];

  bool get isOptionAvailable {
    if (_revenueCatCubit.isPremium) return true;
    return freeIndices.contains(selectedIndex);
  }

  bool loadingPurchase = false;

  int selectedIndex = 0;

  final _revenueCatCubit = locator<RevenueCatCubit>();

  ThemeDataType get selectedTheme => ThemeDataType.values[selectedIndex];

  Color get textColor {
    if (selectedIndex == 0) return Colors.black;
    return Colors.white;
  }

  @override
  void initState() {
    selectedIndex = ThemeDataType.values.indexOf(_themeCubit.type);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RevenueCatCubit, RevenueCatState>(
      builder: (context, state) {
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSizes.paddingDouble),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(AppSizes.paddingDouble),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Theme',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingDouble),
                GridView.builder(
                  itemCount: ThemeDataType.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.paddingHalf,
                    mainAxisSpacing: AppSizes.paddingHalf,
                  ),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        child: Opacity(
                          opacity: selectedIndex == index ? 1.0 : 0.7,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.paddingDouble,
                              AppSizes.padding,
                              AppSizes.padding,
                              AppSizes.padding,
                            ),
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
                const SizedBox(height: AppSizes.paddingDouble),
                _buildSaveButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (!isOptionAvailable) {
          setState(() => loadingPurchase = true);
          _revenueCatCubit.purchase().then((_) => setState(
                () => loadingPurchase = false,
              ));
          return;
        }
        Navigator.of(context).pop();
        if (selectedTheme != _themeCubit.type) {
          _themeCubit.changeTheme(selectedTheme);
          widget.updateMap();
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
