import 'package:flutter/material.dart';

extension BuildContext2 on BuildContext {
  double height([double factor = 1.0]) =>
      MediaQuery.of(this).size.height * factor;

  double width([double factor = 1.0]) =>
      MediaQuery.of(this).size.width * factor;
}
