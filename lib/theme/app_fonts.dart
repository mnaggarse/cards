import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String ibm = 'IBMPlexSansArabic';
  static const String quran = 'UthmanTN';

  static TextStyle ibmStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: ibm,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
      );

  static TextStyle quranStyle({
    double? fontSize = 20,
    FontWeight? fontWeight,
    Color? color,
    double? height = 1.8,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: quran,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        fontStyle: fontStyle,
        decoration: decoration,
      );
}
