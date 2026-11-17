import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  OcrResult(this.rows);

  /// Text grouped into visual rows, top to bottom, each read left to right.
  final List<String> rows;

  String get text => rows.join('\n');
}

/// On-device text recognition (works offline).
class OcrService {
  Future<OcrResult> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final lines = [
        for (final block in result.blocks) ...block.lines,
      ]..sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

      // ML Kit returns the name and the price of one receipt row as separate
      // lines. Lines whose vertical centres are close belong to the same row.
      final rows = <List<TextLine>>[];
      for (final line in lines) {
        final box = line.boundingBox;
        if (rows.isNotEmpty) {
          final last = rows.last.last.boundingBox;
          final tolerance = (last.height + box.height) / 2 * 0.6;
          if ((box.center.dy - last.center.dy).abs() < tolerance) {
            rows.last.add(line);
            continue;
          }
        }
        rows.add([line]);
      }
      return OcrResult([
        for (final row in rows)
          (row..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left)))
              .map((l) => l.text)
              .join(' '),
      ]);
    } finally {
      await recognizer.close();
    }
  }
}
