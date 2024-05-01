import 'package:flutter/material.dart';

enum MOStatus {
  none,
  been,
  want,
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

abstract class MapObject {
  MOStatus status;

  MapObject({required this.status});
}
