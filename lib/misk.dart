import 'package:flutter/material.dart';

Color getHighContrastComplementaryColor(Color backgroundColor) {
  double luminance = (0.2126 * backgroundColor.red / 255) +
      (0.7152 * backgroundColor.green / 255) +
      (0.0722 * backgroundColor.blue / 255);
  return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}