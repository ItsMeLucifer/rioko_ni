import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/map.dart' as map;
import 'package:rioko_ni/core/presentation/widgets/toast.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:rioko_ni/core/extensions/double2.dart';

class ShareWorldDataDialog extends StatefulWidget {
  const ShareWorldDataDialog({super.key});

  @override
  State<ShareWorldDataDialog> createState() => _ShareWorldDataDialogState();
}

class _ShareWorldDataDialogState extends State<ShareWorldDataDialog> {
  // WidgetsToImageController to access widget
  List<WidgetsToImageController> controllers =
      List.generate(11, (index) => WidgetsToImageController());

  List<GlobalKey> keys = List.generate(11, (index) => GlobalKey());

  final _cubit = locator<MapCubit>();
  final _revenueCatCubit = locator<RevenueCatCubit>();

  String get l10n => 'areas';

  double imageHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.8;

  int currentIndex = 0;

  List<int> freeOptions = [0, 1];

  bool get isOptionAvailable {
    if (freeOptions.contains(currentIndex)) return true;
    return _revenueCatCubit.isPremium;
  }

  bool loadingPurchase = false;

  Future<ShareResultStatus> _shareImage() async {
    final bytes = await controllers[currentIndex].capture();
    if (bytes == null) return ShareResultStatus.unavailable;
    final dir = await getTemporaryDirectory();
    String filePath = '${dir.path}/rioko_statistics.png';
    File file = File(filePath);
    await file.writeAsBytes(bytes);
    final result = await Share.shareXFiles([XFile(file.path)]);

    if (result.status == ShareResultStatus.success) {
      file.delete();
    }
    return result.status;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black26,
      child: BlocBuilder<RevenueCatCubit, RevenueCatState>(
        builder: (context, state) => _buildBody(context),
      ),
    );
  }

  List<Map<String, dynamic>> get graphicsData => [
        {
          "backgroundColor": Colors.black,
          "primaryColor": Colors.white,
          "textColor": Colors.white,
        },
        {
          "backgroundColor": Colors.white,
          "primaryColor": Colors.black,
          "textColor": Colors.black,
        },
        {
          "primaryColor": Colors.tealAccent,
          "textColor": Colors.white,
          "fontFamily": 'Nasalization',
        },
        {
          "backgroundColor": Colors.black,
          "primaryColor": Colors.blue,
          "textColor": Colors.white,
          "fontFamily": 'Nasalization',
        },
        {
          "backgroundColor": Colors.black,
          "primaryColor": Colors.red,
          "textColor": Colors.white,
          "fontFamily": 'Nasalization',
        },
        {
          "backgroundColor": Colors.grey[300]!,
          "primaryColor": Colors.black,
          "textColor": Colors.black,
          "fontFamily": 'Caveat',
          "textScale": 1.5,
        },
        {
          "backgroundColor": Colors.black,
          "primaryColor": Colors.white,
          "textColor": Colors.white,
          "fontFamily": 'Caveat',
          "textScale": 1.5,
        },
        {
          "primaryColor": Colors.black,
          "textColor": Colors.black,
          "fontFamily": 'Caveat',
          "textScale": 1.7,
          "image": const AssetImage('assets/paper.jpg'),
        },
        {
          "backgroundColor": const Color.fromARGB(255, 241, 250, 238),
          "primaryColor": const Color.fromARGB(255, 29, 53, 87),
          "textColor": const Color.fromARGB(255, 29, 53, 87),
          "fontFamily": 'Rajdhani',
          "textScale": 1.2,
          "secondaryColor": const Color.fromARGB(255, 230, 57, 70),
        },
        {
          "backgroundColor": const Color.fromARGB(255, 237, 242, 244),
          "primaryColor": const Color.fromARGB(255, 43, 45, 66),
          "textColor": const Color.fromARGB(255, 43, 45, 66),
          "fontFamily": 'Rajdhani',
          "textScale": 1.2,
          "secondaryColor": const Color.fromARGB(255, 239, 35, 60),
        },
        {
          "backgroundColor": const Color.fromARGB(255, 244, 241, 222),
          "primaryColor": const Color.fromARGB(255, 71, 122, 106),
          "textColor": const Color.fromARGB(255, 61, 64, 91),
          "fontFamily": 'Rajdhani',
          "textScale": 1.2,
          "secondaryColor": const Color.fromARGB(255, 224, 122, 95),
        }
      ];

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: graphicsData.length,
          itemBuilder:
              (BuildContext context, int itemIndex, int pageViewIndex) {
            final data = graphicsData[itemIndex];
            return _buildGraphic(
              context,
              index: itemIndex,
              textColor: data['textColor'],
              primaryColor: data['primaryColor'],
              backgroundColor: data['backgroundColor'],
              secondaryColor: data['secondaryColor'],
              textScale: data['textScale'],
              fontFamily: data['fontFamily'],
              image: data['image'],
            );
          },
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            initialPage: 0,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
            enlargeFactor: 0.3,
            onPageChanged: (index, reason) =>
                setState(() => currentIndex = index),
            scrollDirection: Axis.horizontal,
          ),
        ),
        Align(
          alignment: const Alignment(0.9, -0.85),
          child: GestureDetector(
            onTap: Navigator.of(context).pop,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingQuarter,
                0.7,
                AppSizes.paddingQuarter,
                AppSizes.paddingQuarter,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: const Icon(
                FontAwesomeIcons.circleXmark,
                size: 30,
              ),
            ),
          ),
        ),
        _buildShareButton(context),
      ],
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingQuintuple),
        child: ElevatedButton(
          onPressed: () {
            if (!isOptionAvailable) {
              setState(() => loadingPurchase = true);
              _revenueCatCubit.purchasePremium().then((_) => setState(
                    () => loadingPurchase = false,
                  ));
              return;
            }
            _shareImage().then((result) {
              if (result == ShareResultStatus.success) {
                return Navigator.of(context).pop();
              }
              if (result == ShareResultStatus.unavailable) {
                ToastBuilder(message: tr('core.errors.shareUnavailable'))
                    .show(context);
              }
            });
          },
          child: isOptionAvailable
              ? Text(tr('shareDialog.labels.share'))
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
        ),
      ),
    );
  }

  Widget _buildGraphic(
    BuildContext context, {
    required int index,
    required Color textColor,
    required Color primaryColor,
    Color? secondaryColor,
    String? fontFamily,
    Color? backgroundColor,
    double? textScale,
    ImageProvider<Object>? image,
  }) {
    textScale ??= 1;
    backgroundColor ??= Colors.black;
    return Center(
      child: WidgetsToImage(
        key: keys[index],
        controller: controllers[index],
        child: Container(
          height: imageHeight(context),
          decoration: BoxDecoration(
            color: image == null ? backgroundColor : null,
            image: image != null
                ? DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: imageHeight(context) * 0.33,
                child: Stack(
                  children: [
                    Container(
                      height: imageHeight(context) * 0.33,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingHalf),
                      child: map.MapBuilder().buildWorldMapSummary(
                        context,
                        countries: _cubit.noAntarcticCountries,
                        zoom: 0.25,
                        withAntarctic: false,
                        getCountryBorderColor: (status) {
                          if (status == MOStatus.lived) {
                            return backgroundColor!.withOpacity(0.6);
                          }
                          return primaryColor;
                        },
                        getCountryColor: (status) {
                          if (status == MOStatus.none) {
                            return Colors.transparent;
                          }
                          return primaryColor
                              .withOpacity(status == MOStatus.been ? 0.6 : 1);
                        },
                        getCountryBorderStrokeWidth: (status) => 0.3,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.padding),
                        child: Text(
                          'Rioko app',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: primaryColor.withOpacity(0.5),
                                    fontSize: 10,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.northAmerica'),
                percentage: _cubit.beenNorthAmericaPercentage,
                number: _cubit.beenNorthAmericaCountriesNumber,
                all: _cubit.allNorthAmericaCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.southAmerica'),
                percentage: _cubit.beenSouthAmericaPercentage,
                number: _cubit.beenSouthAmericaCountriesNumber,
                all: _cubit.allSouthAmericaCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.europe'),
                percentage: _cubit.beenEuropePercentage,
                number: _cubit.beenEuropeCountriesNumber,
                all: _cubit.allEuropeCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.africa'),
                percentage: _cubit.beenAfricaPercentage,
                number: _cubit.beenAfricaCountriesNumber,
                all: _cubit.allAfricaCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.asia'),
                percentage: _cubit.beenAsiaPercentage,
                number: _cubit.beenAsiaCountriesNumber,
                all: _cubit.allAsiaCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
              _buildContinentSummaryRow(
                context,
                label: tr('$l10n.oceania'),
                percentage: _cubit.beenOceaniaPercentage,
                number: _cubit.beenOceaniaCountriesNumber,
                all: _cubit.allOceaniaCountriesNumber,
                textColor: textColor,
                fontFamily: fontFamily,
                primaryColor: primaryColor,
                textScale: textScale,
                secondaryColor: secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinentSummaryRow(
    BuildContext context, {
    required String label,
    required double percentage,
    required int number,
    required int all,
    required Color textColor,
    required String? fontFamily,
    required Color primaryColor,
    required double textScale,
    required Color? secondaryColor,
  }) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: (imageHeight(context) * 0.11) - 1,
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingDouble,
          vertical: AppSizes.padding,
        ),
        child: Row(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CircularPercentIndicator(
                key: Key(label),
                radius: 32.0,
                lineWidth: 5.0,
                percent: percentage / 100,
                center: Text(
                  "${percentage.toPrettyString()} %",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13 * textScale * .8,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                progressColor: secondaryColor ?? primaryColor,
                circularStrokeCap: CircularStrokeCap.round,
                animation: false,
                addAutomaticKeepAlive: false,
                arcType: ArcType.FULL,
                arcBackgroundColor:
                    (secondaryColor ?? primaryColor).withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingDouble),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: fontFamily,
                      fontSize: (width / 32) * textScale,
                      color: textColor,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                '$number/$all',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: fontFamily,
                      color: textColor,
                    ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
