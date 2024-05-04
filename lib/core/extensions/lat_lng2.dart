import 'package:latlong2/latlong.dart';

extension LatLng2 on LatLng {
  static clamped(double latitude, double longitude) {
    return LatLng(
      latitude.clamp(-89.99, 89.99),
      longitude.clamp(-179.99, 179.99),
    );
  }
}
