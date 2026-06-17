import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AlifTypography {
  static TextTheme textTheme(Color color) {
    final base = GoogleFonts.poppinsTextTheme();
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: color,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: color,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  static TextStyle malayalam({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.black,
  }) {
    return GoogleFonts.notoSansMalayalam(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.45,
    );
  }
}
