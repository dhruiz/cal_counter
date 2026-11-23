import 'package:flutter/material.dart';

import '../../domain/entities/nutrition_facts.dart';

/// Resultado de leer una etiqueta nutricional.
class LabelReading {
  final NutritionFacts nutricion;

  /// Contenido neto leído del envase ("500 g" → 500), si se encontró.
  final double? contenido;

  /// 'g' o 'ml' si la etiqueta lo indica ("por 100 ml").
  final String? unidad;

  const LabelReading({required this.nutricion, this.contenido, this.unidad});
}

/// Lectura de la tabla nutricional con la cámara (OCR en el dispositivo).
class LabelReader {
  LabelReader._();

  /// Abre la cámara, reconoce el texto y lo interpreta. Null si se cancela.
  static Future<LabelReading?> read(
    BuildContext context, {
    String unidad = 'g',
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lectura de etiquetas: próximamente.')),
    );
    return null;
  }
}
