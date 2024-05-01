import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/map.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class CountryManagementPage extends StatefulWidget {
  final Country country;
  final void Function(Country) fetchRegions;

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
  late MapController _countryPreviewMapController;
  late MapController _regionsPreviewMapController;

  bool isPopping = false;

  String get l10n => 'map.countryManagement';

  Region? _region;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _countryPreviewMapController = MapController();
    _regionsPreviewMapController = MapController();
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
    _countryPreviewMapController.dispose();
    _regionsPreviewMapController.dispose();
    super.dispose();
  }

  final _cubit = locator<MapCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(context),
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

  Widget _buildBody(BuildContext context) {
    if (widget.country.displayRegions) {
      return _buildRegionsContent(context);
    }
    return _buildCountryContent(context);
  }

  Widget _buildRegionsContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingDouble,
        vertical: AppSizes.paddingQuadruple,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildCountryInfo(context),
              _buildRegionsPreview(context),
              if (_region != null) _buildRegionInfo(context),
              if (_region != null) _buildCountryStatusButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryContent(BuildContext context) {
    return Stack(
      children: [
        _buildCountryMiniature(context),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingDouble,
            vertical: AppSizes.paddingQuadruple,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                _buildCountryInfo(context),
                Expanded(child: _buildCountryStatusButtons(context)),
                OutlinedButton(
                  onPressed: () {
                    widget.fetchRegions(widget.country);
                  },
                  child: const Text('Fetch regions'),
                ),
                SizedBox(
                  height: context.height(0.07),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryInfo(BuildContext context) {
    return Column(children: [
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
    ]);
  }

  Widget _buildRegionInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          _region!.name,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingHalf),
        Text(
          _region!.engType,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCountryStatusButtons(BuildContext context) {
    return Row(
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
                if (widget.country.status == CountryStatus.been) {
                  widget.country.status = CountryStatus.none;
                } else {
                  widget.country.status = CountryStatus.been;
                }
                setState(() {});
              },
              label: tr('$l10n.labels.been'),
              color: CountryStatus.been.color(context),
              selected: widget.country.status == CountryStatus.been,
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
                child: Opacity(opacity: _animation.value, child: child),
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
              selected: widget.country.status == CountryStatus.want,
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
              icon: FontAwesomeIcons.houseFlag,
              onPressed: () {
                if (widget.country.status == CountryStatus.lived) {
                  widget.country.status = CountryStatus.none;
                } else {
                  widget.country.status = CountryStatus.lived;
                }
                setState(() {});
              },
              label: tr('$l10n.labels.lived'),
              color: CountryStatus.lived.color(context),
              selected: widget.country.status == CountryStatus.lived,
            ),
          ),
        ),
      ],
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

  Widget _buildCountryMiniature(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: MapBuilder().buildCountryMapPreview(
        context,
        country: widget.country,
        controller: _countryPreviewMapController,
      ),
    );
  }

  Widget _buildRegionsPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingQuadruple),
      height: context.width(0.8),
      child: MapBuilder().buildRegionsMapPreview(
        context,
        country: widget.country,
        regions: widget.country.regions,
        controller: _regionsPreviewMapController,
        onTap: (tapPosition, latLng) {
          _region = widget.country.regions
              .firstWhereOrNull((region) => region.contains(latLng));
          setState(() {});
        },
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
