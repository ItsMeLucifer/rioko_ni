import 'dart:math';

import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geobase/geobase.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;

class GeoUtils {
  /// returns the are of polygon in square kilometers
  static double calculatePolygonArea(List<LatLng> polygon) {
    return toolkit.SphericalUtil.computeArea(polygon
            .map((p) => toolkit.LatLng(p.latitude, p.longitude))
            .toList()) /
        1000000;
  }

  /// Function to calculate distance between two LatLng points
  static double calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double fromLatRadians = from.latitude * pi / 180;
    double toLatRadians = to.latitude * pi / 180;
    double latDiffRadians = (to.latitude - from.latitude) * pi / 180;
    double lngDiffRadians = (to.longitude - from.longitude) * pi / 180;

    // Haversine formula
    double a = sin(latDiffRadians / 2) * sin(latDiffRadians / 2) +
        cos(fromLatRadians) *
            cos(toLatRadians) *
            sin(lngDiffRadians / 2) *
            sin(lngDiffRadians / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static List<List<List<double>>> extractPolygonsFromFeatureCollection(
    FeatureCollection featureCollection,
  ) {
    List<List<List<double>>> result = [];

    // Iterate through each GeoJSON feature in the collection
    for (Feature feature in featureCollection.features) {
      result.addAll(extractPolygonsFromFeature(feature));
    }

    return result;
  }

  static List<List<List<double>>> extractPolygonsFromFeature(
    Feature feature,
  ) {
    List<List<LatLng>> result = [];
    List<Polygon> polygons = [];

    // Extract polygons from the feature's geometry
    if (feature.geometry is Polygon) {
      polygons.add(feature.geometry as Polygon);
    }
    if (feature.geometry is MultiPolygon) {
      var multiPolygon = feature.geometry as MultiPolygon;

      polygons = [...multiPolygon.polygons];
    }

    // Process each polygon
    for (Polygon polygon in polygons) {
      List<LatLng> points = [];

      // Skip polygons without exterior positions
      if (polygon.exterior == null) continue;

      // Convert GeoJSON positions to LatLng points
      polygon.exterior?.positions.forEach((position) {
        double latitude = position.y;
        double longitude = position.x;

        // Ensure longitude is within the valid range of flutter_map coordination system
        if (longitude <= -180 || longitude >= 180) {
          longitude = longitude.clamp(-179.999999, 179.999999);
        }

        points.add(LatLng(latitude, longitude));
      });

      // Skip invalid polygons
      if (points.isEmpty || points.length < 2 || points.first != points.last) {
        continue;
      }

      final area = GeoUtils.calculatePolygonArea(points);

      // Skip polygons that area is smaller that threshold
      if (result.isNotEmpty && area < 500) {
        continue;
      }
      // Apply simplification if the number of points exceeds the points number threshold
      if (points.length > 100) {
        points = simplifyPolygon(points.sublist(0, points.length - 2),
            tolerance: 0.02);
      }

      result = [
        ...result,
        points..add(points[0]),
      ];
    }
    return result
        .map((p) => p.map((p2) => [p2.latitude, p2.longitude]).toList())
        .toList();
  }

  // Function to calculate perpendicular distance of a point from a line segment
  static double perpendicularDistance(
      LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Calculate the area of the triangle formed by the point and the line segment
    double area = (0.5 *
            ((lineEnd.longitude - lineStart.longitude) *
                    (point.latitude - lineStart.latitude) -
                (point.longitude - lineStart.longitude) *
                    (lineEnd.latitude - lineStart.latitude)))
        .abs();
    // Calculate the length of the line segment
    double length = sqrt(pow(lineEnd.longitude - lineStart.longitude, 2) +
        pow(lineEnd.latitude - lineStart.latitude, 2));
    // Calculate and return the perpendicular distance
    return area / length;
  }

  // Function to simplify a polygon using the Douglas-Peucker algorithm
  static List<LatLng> simplifyPolygon(
    List<LatLng> polygon, {
    required double tolerance,
  }) {
    if (polygon.length <= 2) {
      return polygon; // Can't simplify further
    }

    double maxDistance = 0;
    late int farthestPointIndex;

    // Find the point farthest from the line segment connecting the start and end points
    for (int i = 1; i < polygon.length - 1; i++) {
      double distance = perpendicularDistance(
          polygon[i], polygon[0], polygon[polygon.length - 1]);
      if (distance > maxDistance) {
        maxDistance = distance;
        farthestPointIndex = i;
      }
    }

    // If the farthest point is within tolerance, simplify the polygon
    if (maxDistance <= tolerance) {
      return [polygon[0], polygon[polygon.length - 1]];
    } else {
      // Recursively simplify both parts of the polygon
      List<LatLng> leftPart = simplifyPolygon(
          polygon.sublist(0, farthestPointIndex + 1),
          tolerance: tolerance);
      List<LatLng> rightPart = simplifyPolygon(
          polygon.sublist(farthestPointIndex),
          tolerance: tolerance);
      // Combine the simplified parts and return
      return [...leftPart.sublist(0, leftPart.length - 1), ...rightPart];
    }
  }

  static fm.LatLngBounds calculateOverallBounds(List<fm.Polygon> polygons) {
    final allPoints = polygons
        .map((p) => [p.boundingBox.southWest, p.boundingBox.northEast])
        .reduce((value, element) => [
              ...value,
              ...element,
            ]);

    return fm.LatLngBounds.fromPoints(allPoints);
  }
}
