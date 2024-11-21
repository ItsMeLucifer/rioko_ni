import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rioko_ni/core/extensions/build_context2.dart';
import 'package:rioko_ni/core/injector.dart';
import 'package:rioko_ni/core/presentation/cubit/admob_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/revenue_cat_cubit.dart';
import 'package:rioko_ni/core/presentation/cubit/theme_cubit.dart';
import 'package:rioko_ni/core/presentation/widgets/toast.dart';
import 'package:rioko_ni/features/map/domain/entities/map_object.dart';
import 'package:rioko_ni/features/map/domain/entities/region.dart';
import 'package:rioko_ni/features/map/presentation/cubit/map_cubit.dart';
import 'package:rioko_ni/features/map/presentation/pages/map_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Hive.initFlutter();
  Hive.registerAdapter(ThemeDataTypeAdapter());
  await Hive.openBox('theme_data');
  await EasyLocalization.ensureInitialized();
  await registerDependencies();
  Hive.registerAdapter(RegionAdapter());
  Hive.registerAdapter(MOStatusAdapter());
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('pl')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MapCubit>(
            create: (BuildContext context) => locator<MapCubit>(),
          ),
          BlocProvider<RevenueCatCubit>(
            create: (BuildContext context) => locator<RevenueCatCubit>(),
          ),
          BlocProvider<ThemeCubit>(
            create: (BuildContext context) => locator<ThemeCubit>(),
          ),
          BlocProvider<AdmobCubit>(
            create: (BuildContext context) => locator<AdmobCubit>(),
          ),
        ],
        child: const RiokoNi(),
      ),
    ),
  );
}

class RiokoNi extends StatefulWidget {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  const RiokoNi({super.key});

  @override
  State<RiokoNi> createState() => _RiokoNiState();
}

class _RiokoNiState extends State<RiokoNi> {
  final _mapCubit = locator<MapCubit>();
  final _revenueCat = locator<RevenueCatCubit>();
  final _themeCubit = locator<ThemeCubit>();
  final _admobCubit = locator<AdmobCubit>();

  @override
  void initState() {
    _mapCubit.load();
    _revenueCat.initPlatformState().then((_) {
      _revenueCat.fetchProduct();
      _revenueCat.fetchCustomerInfo();
    });
    Future.delayed(const Duration(milliseconds: 200),
        () => _admobCubit.loadAds(width: context.width().round()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeDataType>(
      builder: (context, state) {
        return MaterialApp(
          navigatorKey: RiokoNi.navigatorKey,
          theme: _themeCubit.appThemeData(state),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const HomePage(),
          builder: (context, child) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => child!,
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RevenueCatCubit, RevenueCatState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (message) => ToastBuilder(message: message).show(context),
          purchasedPremium: (_) => ToastBuilder(
                  message: tr('core.purchaseSuccessfullMessage'),
                  type: ToastificationType.success)
              .show(context),
          orElse: () => debugPrint(state.toString()),
        );
      },
      builder: (context, state) {
        return const MapPage();
      },
    );
  }
}
