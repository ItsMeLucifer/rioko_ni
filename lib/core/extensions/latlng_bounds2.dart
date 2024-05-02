import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension LatLngBounds2 on LatLngBounds {
  LatLngBounds scale(double factor) {
    // Calculate center of the bounds
    final centerLat = (north + south) / 2;
    final centerLng = (east + west) / 2;

    // Calculate new distances from center
    final latDiff = (north - south) * factor / 2;
    final lngDiff = (east - west) * factor / 2;

    // Create new extended bounds
    final newBounds = LatLngBounds(
      LatLng(centerLat - latDiff, centerLng - lngDiff),
      LatLng(centerLat + latDiff, centerLng + lngDiff),
    );

    return newBounds;
  }
}
