import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class CountryManagementPage extends StatefulWidget {
  final Country country;
  final void Function(String) fetchRegions;

  const CountryManagementPage({
    required this.country,
    required this.fetchRegions,
    super.key,
  });

  @override
  State<CountryManagementPage> createState() => _CountryManagementPageState();
}

class _CountryManagementPageState extends State<CountryManagementPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late MapController _previewMapController;

  bool isPopping = false;

  String get l10n => 'map.countryManagement';

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _previewMapController = MapController();
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
    _previewMapController.dispose();
    super.dispose();
  }

  final _cubit = locator<MapCubit>();

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildContryMiniature(context),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingDouble,
                vertical: AppSizes.paddingQuadruple,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.country.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.paddingHalf),
                  Text(
                    widget.country.region.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  widget.country.flag(
                    scale: 0.3,
                    borderColor: Theme.of(context).iconTheme.color,
                    borderRadius: 3,
                  ),
                  const SizedBox(height: AppSizes.paddingQuintuple),
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
                              child: Opacity(
                                  opacity: _animation.value, child: child),
                            );
                          },
                          child: _buildButton(
                            context,
                            icon: FontAwesomeIcons.trophy,
                            onPressed: () {
                              if (widget.country.status == CountryStatus.been) {
                                widget.country.status = CountryStatus.none;
                              } else {
                                widget.country.status = CountryStatus.been;
                              }
                              setState(() {});
                            },
                            label: tr('$l10n.labels.been'),
                            color: CountryStatus.been.color(context),
                            selected:
                                widget.country.status == CountryStatus.been,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                50 * (1 - _animation.value),
                              ),
                              child: Opacity(
                                  opacity: _animation.value, child: child),
                            );
                          },
                          child: _buildButton(
                            context,
                            icon: FontAwesomeIcons.suitcase,
                            onPressed: () {
                              if (widget.country.status == CountryStatus.want) {
                                widget.country.status = CountryStatus.none;
                              } else {
                                widget.country.status = CountryStatus.want;
                              }
                              setState(() {});
                            },
                            label: tr('$l10n.labels.want'),
                            color: CountryStatus.want.color(context),
                            selected:
                                widget.country.status == CountryStatus.want,
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
                              child: Opacity(
                                  opacity: _animation.value, child: child),
                            );
                          },
                          child: _buildButton(
                            context,
                            icon: FontAwesomeIcons.houseFlag,
                            onPressed: () {
                              if (widget.country.status ==
                                  CountryStatus.lived) {
                                widget.country.status = CountryStatus.none;
                              } else {
                                widget.country.status = CountryStatus.lived;
                              }
                              setState(() {});
                            },
                            label: tr('$l10n.labels.lived'),
                            color: CountryStatus.lived.color(context),
                            selected:
                                widget.country.status == CountryStatus.lived,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingQuintuple),
                  OutlinedButton(
                    onPressed: () {
                      pop(context, short: true);
                      widget.fetchRegions(widget.country.alpha3);
                    },
                    child: const Text('Fetch regions'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pop(context, short: true),
        label: SizedBox(
          width: 50,
          child: Text(
            tr('core.dialog.ok'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void pop(BuildContext context, {bool short = false}) {
    if (isPopping) return;
    _cubit.updateCountryStatus(
        country: widget.country, status: widget.country.status);
    isPopping = true;
    _controller.reverse();
    Future.delayed(
      Duration(milliseconds: short ? 100 : 300),
      Navigator.of(context).pop,
    );
  }

  Widget _buildContryMiniature(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: MapBuilder().buildCountryMapPreview(
        context,
        country: widget.country,
        controller: _previewMapController,
      ),
    );
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
      onTap: onPressed,
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
              const SizedBox(height: AppSizes.paddingTriple),
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 35,
              ),
              const SizedBox(height: AppSizes.padding),
              Expanded(
                child: AnimatedOpacity(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
