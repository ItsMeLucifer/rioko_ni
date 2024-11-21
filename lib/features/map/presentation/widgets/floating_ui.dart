import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/widgets/search_map_object_dialog.dart';

class FloatingUI extends StatelessWidget {
  final void Function(MapObject) onSelectMapObject;
  const FloatingUI({
    required this.onSelectMapObject,
    super.key,
  });

  MapCubit get _cubit => locator<MapCubit>();

  double get topMargin => AppSizes.paddingTriple;

  String get l10n => 'map.statsUI';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.paddingQuadruple),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  barrierColor: Colors.black.withOpacity(0.5),
                  transitionBuilder: (context, a1, a2, widget) {
                    return Opacity(
                      opacity: a1.value,
                      child: widget,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 200),
                  barrierDismissible: true,
                  barrierLabel: '',
                  context: context,
                  pageBuilder: (context, animation1, animation2) =>
                      SearchMapObjectDialog(
                          onSelectMapObject: onSelectMapObject),
                );
              },
              child: Container(
                height: 50,
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingDouble),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.onPrimary, width: 1),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Center(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.padding,
                            horizontal: AppSizes.paddingDouble),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                                color: Theme.of(context).colorScheme.onPrimary,
                                width: 1),
                          ),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.padding,
                              horizontal: AppSizes.paddingDouble),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(),
                              Text(
                                "${tr('$l10n.labels.been')}: ${_cubit.beenCountries.length}",
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${tr('$l10n.labels.want')}: ${_cubit.wantCountries.length}",
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${tr('$l10n.labels.lived')}: ${_cubit.livedCountries.length}",
                              ),
                              const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
