import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Service to handle poster generation by compositing high-res overlays.
class PosterGeneratorService {
  /// Composites the high-resolution overlay over the original image.
  /// [dx], [dy] are relative positions (0.0 to 1.0) of the top-left corner.
  Future<Uint8List> generatePoster({
    required Uint8List imageBytes,
    required Uint8List overlayBytes,
    required double dx,
    required double dy,
  }) async {
    // Decode base image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Gagal membaca gambar utama');

    // Decode overlay image
    img.Image? overlay = img.decodeImage(overlayBytes);
    if (overlay == null) throw Exception('Gagal membaca overlay gambar');

    // Calculate pixel coordinates
    final x = (dx * image.width).toInt();
    final y = (dy * image.height).toInt();

    // Composite overlay over base image
    img.compositeImage(image, overlay, dstX: x, dstY: y);

    // Encode back to PNG
    return Uint8List.fromList(img.encodePng(image));
  }
}
