import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

part 'map_object.g.dart';

@HiveType(typeId: 2)
enum MOStatus {
  @HiveField(0)
  none,
  @HiveField(1)
  been,
  @HiveField(2)
  want,
  @HiveField(3)
  lived,
}

extension MOStatusExtension on MOStatus {
  Color color(
    BuildContext context, {
    Color? customDefaultColor,
    ThemeData? otherTheme,
  }) {
    final scheme = otherTheme?.colorScheme ?? Theme.of(context).colorScheme;
    switch (this) {
      case MOStatus.been:
        return scheme.onPrimary;
      case MOStatus.want:
        return scheme.onSecondary;
      case MOStatus.lived:
        return scheme.onTertiary;
      default:
        return customDefaultColor ?? Colors.transparent;
    }
  }
}

abstract class MapObject extends HiveObject {
  MOStatus status;
  final String name;
  final List<List<LatLng>> polygons;

  MapObject({
    this.status = MOStatus.none,
    this.name = '',
    this.polygons = const [],
  });

  LatLngBounds bounds();
  Widget flag({
    double scale = 1,
    double borderRadius = 0,
    Color? borderColor,
  });
  LatLng get center;
}
