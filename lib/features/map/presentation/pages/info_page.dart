import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/features/map/domain/entities/country.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';

class InfoPage extends StatefulWidget {
  final void Function(Country) onTapCountry;

  const InfoPage({
    required this.onTapCountry,
    super.key,
  });

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  MOStatus status = MOStatus.been;

  final _cubit = locator<MapCubit>();

  Color get borderColor {
    switch (status) {
      case MOStatus.been:
        return Theme.of(context).colorScheme.primary;
      case MOStatus.want:
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  List<Country> get countries {
    switch (status) {
      case MOStatus.been:
        return _cubit.beenCountries;
      case MOStatus.want:
        return _cubit.wantCountries;
      default:
        return _cubit.livedCountries;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MapCubit, MapState>(
        listener: (context, state) {
          state.maybeWhen(
            updatedCountryStatus: (country, status) => setState(() {}),
            orElse: () {},
          );
        },
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.paddingQuadruple,
                horizontal: AppSizes.paddingDouble,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: context.width(0.9),
                    child: SegmentedButton<MOStatus>(
                      segments: ([...MOStatus.values]..remove(MOStatus.none))
                          .map((s) => ButtonSegment(
                                value: s,
                                label: Text(s.name),
                              ))
                          .toList(),
                      selected: {status},
                      style: ButtonStyle(
                        textStyle: MaterialStatePropertyAll(
                            Theme.of(context).textTheme.titleMedium),
                        foregroundColor: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.outline),
                      ),
                      onSelectionChanged: (value) =>
                          setState(() => status = value.first),
                    ),
                  ),
                  _buildCountryList(context, countries: countries),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: Navigator.of(context).pop,
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

  Widget _buildCountryList(
    BuildContext context, {
    required List<Country> countries,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSizes.paddingQuadruple,
          ),
          child: Text(countries.isEmpty
              ? 'No results'
              : '${countries.length} countries'),
        ),
        if (countries.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.height(0.6)),
            child: Container(
              margin: const EdgeInsets.all(
                AppSizes.paddingDouble,
              ),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                border: Border.all(
                  color: borderColor,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusHalf),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return ListTile(
                    onTap: () => widget.onTapCountry(country),
                    leading: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor,
                        ),
                        color: borderColor,
                      ),
                      child: country.flag(scale: 0.5),
                    ),
                    title: Text(
                      country.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      country.area.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
