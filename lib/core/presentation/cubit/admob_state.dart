part of 'admob_cubit.dart';

@freezed
class AdmobState with _$AdmobState {
  const factory AdmobState.initial() = _Initial;
  const factory AdmobState.loadingAds() = _LoadingAds;
  const factory AdmobState.loadedAds(List<Ad> ads) = _LoadedAds;
  const factory AdmobState.error(String message) = _Error;
}
