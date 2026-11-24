import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/styles.dart';
import '../../core/utils.dart';
import '../../domain/entities/nutrition_facts.dart';
import '../../domain/services/nutrition_label_parser.dart';
import '../providers/core_providers.dart';
import 'food_widgets.dart';

/// Resultado de leer una etiqueta nutricional.
class LabelReading {
  final NutritionFacts nutricion;

  /// Contenido neto leído del envase ("500 g" → 500), si se encontró.
  final double? contenido;

  /// 'g' o 'ml' si la etiqueta lo indica ("por 100 ml").
  final String? unidad;

  const LabelReading({required this.nutricion, this.contenido, this.unidad});
}

/// Lectura de la tabla nutricional con la cámara: foto → OCR en el
/// dispositivo (ML Kit) → interpretación → revisión. Nunca se guarda nada
/// sin que el usuario lo confirme (los valores pasan al formulario).
class LabelReader {
  LabelReader._();

  /// Devuelve los valores leídos, o null si se cancela.
  static Future<LabelReading?> read(
    BuildContext context, {
    String unidad = 'g',
  }) async {
    final recognizer = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(labelRecognizerProvider);
    while (true) {
      if (!context.mounted) return null;
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Encuadra solo la tabla nutricional, de frente, sin '
                  'brillos y con buena luz.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Hacer una foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null || !context.mounted) return null;

      final XFile? img;
      try {
        img = await ImagePicker().pickImage(
          source: source,
          maxWidth: 2400,
          imageQuality: 92,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir la cámara: $e')),
          );
        }
        return null;
      }
      if (img == null || !context.mounted) return null;

      List<RecognizedLine> lines;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Leyendo la etiqueta...')),
            ],
          ),
        ),
      );
      try {
        lines = await recognizer.recognize(img.path);
      } catch (e) {
        lines = const [];
      }
      if (!context.mounted) return null;
      Navigator.of(context, rootNavigator: true).pop();

      final result = NutritionLabelParser.parse(lines);
      final action = await LabelReviewSheet.show(
        context,
        imagePath: img.path,
        result: result,
        unidad: result.unidad ?? unidad,
      );
      if (action == LabelReviewAction.usar) {
        return LabelReading(
          nutricion: result.nutricion,
          contenido: result.contenido,
          unidad: result.unidad,
        );
      }
      if (action != LabelReviewAction.repetir) return null;
    }
  }
}

enum LabelReviewAction { usar, repetir }

/// Revisión de lo leído: foto, valores con su fiabilidad, lo que falta y
/// avisos de coherencia.
class LabelReviewSheet extends StatelessWidget {
  final String? imagePath;
  final LabelParseResult result;
  final String unidad;

  const LabelReviewSheet({
    super.key,
    this.imagePath,
    required this.result,
    required this.unidad,
  });

  static Future<LabelReviewAction?> show(
    BuildContext context, {
    String? imagePath,
    required LabelParseResult result,
    required String unidad,
  }) => showModalBottomSheet<LabelReviewAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        LabelReviewSheet(imagePath: imagePath, result: result, unidad: unidad),
  );

  @override
  Widget build(BuildContext context) {
    final n = result.nutricion;
    final nada = result.encontrados == 0;
    final dudosos = result.dudosos.toSet();
    final path = imagePath;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            'Lectura de la etiqueta',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (path != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                child: Image.file(
                  File(path),
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (nada)
            const InfoBanner(
              color: AppStyles.semaphRed,
              icon: Icons.error_outline,
              text:
                  'No se reconoció la tabla nutricional. Prueba otra foto: '
                  'más cerca, de frente y con buena luz.',
            )
          else ...[
            Text(
              'Por 100 $unidad · revisa los marcados con ⚠ antes de guardar.',
              style: AppStyles.labelText,
            ),
            const SizedBox(height: 8),
            for (final nut in Nutrient.values)
              Padding(
                padding: EdgeInsets.only(
                  left: nut.esSubcategoria ? 16 : 0,
                  top: 3,
                  bottom: 3,
                ),
                child: Row(
                  children: [
                    Icon(
                      n[nut] == null
                          ? Icons.remove
                          : (dudosos.contains(nut)
                                ? Icons.warning_amber
                                : Icons.check_circle),
                      size: 18,
                      color: n[nut] == null
                          ? AppStyles.neutral
                          : (dudosos.contains(nut)
                                ? AppStyles.semaphOrange
                                : AppStyles.semaphGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(nut.etiqueta)),
                    Text(
                      n[nut] == null
                          ? 'no leído'
                          : '${AppUtils.formatNumero(n[nut]!)} ${nut.unidad}',
                      style: TextStyle(
                        fontWeight: nut.esencial ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
            if (result.porcion != null)
              InfoBanner(
                color: AppStyles.semaphBlue,
                icon: Icons.calculate_outlined,
                text:
                    'La etiqueta daba valores por ración '
                    '(${AppUtils.formatNumero(result.porcion!)} g): se han '
                    'convertido a 100 g.',
              ),
            if (result.contenido != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Contenido neto: ${AppUtils.formatNumero(result.contenido!)} '
                  '$unidad',
                ),
              ),
            for (final a in result.avisos)
              InfoBanner(
                color: AppStyles.semaphOrange,
                icon: Icons.rule,
                text: a,
              ),
          ],
          const SizedBox(height: 16),
          if (!nada)
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, LabelReviewAction.usar),
              icon: const Icon(Icons.check),
              label: const Text('Usar estos valores'),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, LabelReviewAction.repetir),
            icon: const Icon(Icons.refresh),
            label: const Text('Repetir la foto'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (result.filas.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Texto reconocido'),
              children: [
                Text(result.filas.join('\n'), style: AppStyles.labelText),
              ],
            ),
        ],
      ),
    );
  }
}
