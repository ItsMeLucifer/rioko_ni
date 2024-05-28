import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

part 'admob_state.dart';
part 'admob_cubit.freezed.dart';

class AdmobCubit extends Cubit<AdmobState> {
  AdmobCubit() : super(const AdmobState.initial());

  // Now test
  String get _testMenuBannerId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  String get _menuBannerId => Platform.isAndroid
      ? const String.fromEnvironment("menu_banner_android")
      : const String.fromEnvironment("menu_banner_ios");

  BannerAd? riokoMenuBanner;

  void loadAds({required int width}) {
    emit(const AdmobState.loadingAds());
    riokoMenuBanner = BannerAd(
      adUnitId: kDebugMode ? _testMenuBannerId : _menuBannerId,
      request: const AdRequest(),
      size: AdSize(width: width, height: 50),
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          emit(AdmobState.loadedAds([ad]));
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          // Dispose the ad here to free resources.
          ad.dispose();
          emit(AdmobState.error('Failed to load Ad.\n$err'));
        },
      ),
    )..load();
  }
}
