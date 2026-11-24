import 'nutrition_label_parser.dart';

/// Reconocimiento de texto en una foto (OCR). La implementación vive en la
/// capa de datos (ML Kit, en el dispositivo y sin internet); en tests se
/// sustituye.
abstract class LabelTextRecognizer {
  /// Líneas reconocidas en la imagen de [imagePath], con sus cajas.
  Future<List<RecognizedLine>> recognize(String imagePath);
}
