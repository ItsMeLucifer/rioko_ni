import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  }) {
    final scheme = Theme.of(context).colorScheme;
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

  MapObject({required this.status});
}
