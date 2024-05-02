import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class CountryManagementDialog extends StatefulWidget {
  final Country country;

  const CountryManagementDialog({
    required this.country,
    super.key,
  });

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

  @override
  State<CountryManagementDialog> createState() =>
      _CountryManagementDialogState();
}

class _CountryManagementDialogState extends State<CountryManagementDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool isPopping = false;

  String get l10n => 'map.countryManagement';

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });

    _animation.addListener(() {
      if (_animation.value >= 0.4) {
        setState(() {});
      }
    });
    isPopping = false;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final GlobalKey _dialogKey = GlobalKey();

  final _cubit = locator<MapCubit>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: onTapOutsideDialog,
      child: _buildDialog(context),
    );
  }

  Dialog _buildDialog(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingDouble),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingDouble),
        child: Column(
          key: _dialogKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.country.name,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingDouble),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          -50 * (1 - _animation.value),
                          0,
                        ),
                        child: Opacity(opacity: _animation.value, child: child),
                      );
                    },
                    child: _buildButton(
                      context,
                      icon: FontAwesomeIcons.trophy,
                      onPressed: () {
                        if (widget.country.status == MOStatus.been) {
                          widget.country.status = MOStatus.none;
                        } else {
                          widget.country.status = MOStatus.been;
                        }
                        setState(() {});
                      },
                      label: tr('$l10n.labels.been'),
                      color: MOStatus.been.color(context),
                      selected: widget.country.status == MOStatus.been,
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          50 * (1 - _animation.value),
                          0,
                        ),
                        child: Opacity(opacity: _animation.value, child: child),
                      );
                    },
                    child: _buildButton(
                      context,
                      icon: FontAwesomeIcons.suitcase,
                      onPressed: () {
                        if (widget.country.status == MOStatus.want) {
                          widget.country.status = MOStatus.none;
                        } else {
                          widget.country.status = MOStatus.want;
                        }
                        setState(() {});
                      },
                      label: tr('$l10n.labels.want'),
                      color: MOStatus.want.color(context),
                      selected: widget.country.status == MOStatus.want,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingHalf),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          50 * (1 - _animation.value),
                        ),
                        child: Opacity(opacity: _animation.value, child: child),
                      );
                    },
                    child: _buildButton(
                      context,
                      icon: FontAwesomeIcons.houseFlag,
                      onPressed: () {
                        if (widget.country.status == MOStatus.lived) {
                          widget.country.status = MOStatus.none;
                        } else {
                          widget.country.status = MOStatus.lived;
                        }
                        setState(() {});
                      },
                      label: tr('$l10n.labels.lived'),
                      color: MOStatus.lived.color(context),
                      selected: widget.country.status == MOStatus.lived,
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: AppSizes.paddingDouble),
            OutlinedButton(
              onPressed: () => pop(context, short: true),
              child: Text(tr('core.dialog.back')),
            ),
          ],
        ),
      ),
    );
  }

  void onTapOutsideDialog(TapDownDetails details) {
    final pos = details.globalPosition;
    final RenderBox renderBox =
        _dialogKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final globalSize = MediaQuery.of(context).size;
    final ({double min, double max}) x = (
      min: (globalSize.width - size.width) / 2,
      max: globalSize.width - (globalSize.width - size.width) / 2
    );
    final ({double min, double max}) y = (
      min: (globalSize.height - size.height) / 2,
      max: globalSize.height - (globalSize.height - size.height) / 2
    );
    final bool inside =
        pos.dx > x.min && pos.dx < x.max && pos.dy > y.min && pos.dy < y.max;
    if (!inside) pop(context);
  }

  void pop(BuildContext context, {bool short = false}) {
    if (isPopping) return;
    _cubit.updateCountryStatus(
        country: widget.country, status: widget.country.status);
    isPopping = true;
    _controller.reverse();
    Future.delayed(
        Duration(milliseconds: short ? 100 : 300), Navigator.of(context).pop);
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required void Function() onPressed,
    required String label,
    required Color color,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        onPressed();
        pop(context);
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.paddingDouble),
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 35,
              ),
              const SizedBox(height: AppSizes.paddingHalf),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _animation.value > 0.4 ? 1 : 0,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingDouble),
            ],
          ),
        ),
      ),
    );
  }
}
