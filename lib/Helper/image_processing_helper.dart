import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageResizeParams {
  final Uint8List bytes;
  final int width;
  final int height;

  ImageResizeParams(this.bytes, this.width, this.height);
}

class ImageProcessingHelper {
  /// يتم تشغيل معالجة الصور داخل isolate منفصل لتفادي تجميد الواجهة
  static Future<Uint8List?> resizeImageInIsolate(
      Uint8List bytes, int width, int height) async {
    return await compute(_resizeImageTask, ImageResizeParams(bytes, width, height));
  }

  static Uint8List? _resizeImageTask(ImageResizeParams params) {
    try {
      final img.Image? decoded = img.decodeImage(params.bytes);
      if (decoded == null) return null;

      final img.Image resized = img.copyResize(
        decoded,
        width: params.width,
        height: params.height,
        interpolation: img.Interpolation.average,
      );

      final List<int> jpgBytes = img.encodeJpg(resized, quality: 90);
      return Uint8List.fromList(jpgBytes);
    } catch (e) {
      debugPrint("Resize error: $e");
      return null;
    }
  }

  static img.Image? decodeImageSync(Uint8List bytes) {
    return img.decodeImage(bytes);
  }
}