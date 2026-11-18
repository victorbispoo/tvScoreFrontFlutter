import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Recolor only the wordmark; keep the star and blue gradients intact.
class LightLogoColorMapper extends ColorMapper {
  const LightLogoColorMapper();

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => color == const Color(0xFFFBF9FA) ? const Color(0xFF17263E) : color;
}
