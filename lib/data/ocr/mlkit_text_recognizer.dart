import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/services/label_text_recognizer.dart';
import '../../domain/services/nutrition_label_parser.dart';

/// OCR con Google ML Kit (modelo latino incluido en la app: funciona sin
/// internet ni Google Play Services).
class MlKitLabelRecognizer implements LabelTextRecognizer {
  @override
  Future<List<RecognizedLine>> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            RecognizedLine(
              line.text,
              left: line.boundingBox.left,
              top: line.boundingBox.top,
              right: line.boundingBox.right,
              bottom: line.boundingBox.bottom,
            ),
      ];
    } finally {
      await recognizer.close();
    }
  }
}
