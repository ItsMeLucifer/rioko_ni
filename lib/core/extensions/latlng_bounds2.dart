import 'dart:math';

import 'package:flutter/material.dart';
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

  LatLngBounds toSquare({bool shorter = false}) {
    // Calculate center of the bounds
    final centerLat = (north + south) / 2;
    final centerLng = (east + west) / 2;

    // Calculate new distances from center
    final latDiff = (north - south).abs() / 2;
    final lngDiff = (east - west).abs() / 2;

    // Determine the shorter or longer side
    final newDiff = shorter ? min(latDiff, lngDiff) : max(latDiff, lngDiff);

    // Calculate new bounds
    final newBounds = LatLngBounds.fromPoints([
      LatLng(centerLat - newDiff, centerLng - newDiff),
      LatLng(centerLat + newDiff, centerLng + newDiff),
    ]);

    return newBounds;
  }

  double zoom(
    Size mapSize,
  ) {
    final double east = northEast.longitude;
    final double west = southWest.longitude;
    final double north = northEast.latitude;
    final double south = southWest.latitude;

    final double lngFraction = (east - west);
    final double latFraction = (north - south);

    final double latZoom = _zoom(mapSize.height, latFraction);
    final double lngZoom = _zoom(mapSize.width, lngFraction);

    final double zoom = (latZoom < lngZoom ? latZoom : lngZoom).floorToDouble();

    return zoom;
  }

  static double _zoom(double mapSize, double fraction) {
    return log(mapSize / fraction) / ln2;
  }
}
