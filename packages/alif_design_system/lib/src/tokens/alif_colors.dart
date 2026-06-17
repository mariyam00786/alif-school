import 'package:flutter/material.dart';

/// Centralized color tokens.
///
/// TODO: replace palette from brand logo when the final logo asset is provided.
/// Current values align with FRD and paper chart readability constraints.
abstract final class AlifColors {
  static const Color primary = Color(0xFF1F6D45);
  static const Color primaryContainer = Color(0xFFD7F0E2);
  static const Color secondary = Color(0xFFC68B1F);
  static const Color secondaryContainer = Color(0xFFFFE7BF);
  static const Color accent = Color(0xFF2A8E5B);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE09A00);
  static const Color danger = Color(0xFFCC3D2D);
  static const Color neutral = Color(0xFF64727D);

  static const Color bg = Color(0xFFF7FBF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF172026);
  static const Color textSecondary = Color(0xFF4A5861);
  static const Color border = Color(0xFFD6E1DA);

  static const Color ratingExcellent = Color(0xFF3FA34D);
  static const Color ratingSatisfactory = Color(0xFFF1B500);
  static const Color ratingNeedsImprovement = Color(0xFFE07A11);
  static const Color ratingNotDone = Color(0xFF9CA3AF);
}
