import 'package:flutter/material.dart';

import 'alif_colors.dart';
import 'alif_typography.dart';

abstract final class AlifTextStyles {
  static TextStyle pageTitle(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(color: color) ??
        TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color ?? AlifColors.textPrimary,
        );
  }

  static TextStyle sectionTitle(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(color: color) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color ?? AlifColors.textPrimary,
        );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(color: color) ??
        TextStyle(
          fontSize: 14,
          height: 1.45,
          color: color ?? AlifColors.textPrimary,
        );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(color: color) ??
        TextStyle(
          fontSize: 12,
          height: 1.4,
          color: color ?? AlifColors.textSecondary,
        );
  }

  static TextStyle malayalamBody({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AlifColors.textSecondary,
  }) {
    return AlifTypography.malayalam(size: size, weight: weight, color: color);
  }
}
