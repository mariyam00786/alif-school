import 'package:flutter/material.dart';

import '../tokens/alif_colors.dart';
import '../tokens/alif_typography.dart';

abstract final class AlifTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: AlifColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AlifColors.primaryContainer,
      onPrimaryContainer: AlifColors.textPrimary,
      secondary: AlifColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AlifColors.secondaryContainer,
      onSecondaryContainer: AlifColors.textPrimary,
      error: AlifColors.danger,
      onError: Colors.white,
      surface: AlifColors.surface,
      onSurface: AlifColors.textPrimary,
      outline: AlifColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AlifColors.bg,
      colorScheme: colorScheme,
      textTheme: AlifTypography.textTheme(AlifColors.textPrimary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AlifColors.textPrimary,
        contentTextStyle: AlifTypography.textTheme(Colors.white).bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return 0;
            }
            if (states.contains(WidgetState.hovered)) {
              return 1;
            }
            return 0;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            return null;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AlifColors.neutral.withValues(alpha: 0.4);
            }
            return AlifColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AlifColors.primary, width: 1.4);
            }
            return const BorderSide(color: AlifColors.border);
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          foregroundColor: const WidgetStatePropertyAll(AlifColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlifColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlifColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AlifColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
