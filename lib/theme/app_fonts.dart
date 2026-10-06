import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const String ibm = 'IBMPlexSansArabic';

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

}
