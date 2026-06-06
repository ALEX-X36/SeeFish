/// Image utility helpers.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Compress an image file for upload (max 1024px on longest side, JPEG quality 85).
  static Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return file;

    // Resize if larger than 1024px
    img.Image resized = decoded;
    if (decoded.width > 1024 || decoded.height > 1024) {
      resized = img.copyResize(decoded, width: 1024, height: 1024);
    }

    final compressed = img.encodeJpg(resized, quality: 85);
    final compressedFile = File('${file.path}_compressed.jpg');
    await compressedFile.writeAsBytes(compressed);
    return compressedFile;
  }

  /// Get image dimensions from file.
  static Future<Size> getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const Size(0, 0);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}

/// Simple size class to avoid dependency on dart:ui in pure dart context.
class Size {
  final double width;
  final double height;
  const Size(this.width, this.height);
}
