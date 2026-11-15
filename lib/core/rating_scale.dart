import 'package:flutter/material.dart';

abstract final class RatingScale {
  static const bands = <(double, String)>[
    (9.5, 'Obra-prima'),
    (8.5, 'Excepcional'),
    (7.5, 'Excelente'),
    (6.5, 'Muito bom'),
    (5.5, 'Bom'),
    (4.5, 'Regular'),
    (2.5, 'Fraco'),
    (0.0, 'Horrível'),
  ];

  static String label(double rating) =>
      bands.firstWhere((band) => rating >= band.$1).$2;
  static Color color(double? rating) {
    if (rating == null) {
      return const Color(0xFF64748B);
    }

    final value = rating.clamp(0.0, 10.0).toDouble();
    if (value >= 9.5) {
      return const Color(0xFF8B3DFF);
    }
    const stops = <(double, Color)>[
      (0.0, Color(0xFFC21842)),
      (3.0, Color(0xFFDF4936)),
      (5.0, Color(0xFFE87513)),
      (6.0, Color(0xFFC29B00)),
      (7.0, Color(0xFF79A500)),
      (7.5, Color(0xFF24A66A)),
      (8.0, Color(0xFF009BBD)),
      (8.5, Color(0xFF246BDD)),
      (9.5, Color(0xFF3654C7)),
    ];

    for (int i = 0; i < stops.length - 1; i++) {
      final (start, startColor) = stops[i];
      final (end, endColor) = stops[i + 1];

      if (value <= end) {
        final t = (value - start) / (end - start);

        return Color.lerp(startColor, endColor, t)!;
      }
    }

    return stops.last.$2;
  }
}
