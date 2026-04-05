import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Safe wrapper around GoogleFonts.inter() that falls back gracefully
/// when fonts cannot be fetched (e.g., web offline mode).
class AppText {
  static TextStyle style({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        height: height,
      );
    }
  }
}
