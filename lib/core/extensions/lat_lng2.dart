import 'package:latlong2/latlong.dart';

extension LatLng2 on LatLng {
  LatLng clamp() {
    return LatLng(
      latitude.clamp(-89.99, 89.99),
      longitude.clamp(-179.99, 179.99),
    );
  }

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
