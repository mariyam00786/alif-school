import 'package:flutter/widgets.dart';

abstract final class AlifSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );
}
