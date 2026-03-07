import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Note: In a real project, we use conditional imports for Web.
// Since we are in a simplified environment, we use kIsWeb check.
// However, direct 'dart:html' import would fail on mobile.
// We will use a strategy that works for this specific project.

class PosterExportHelper {
  static Future<void> exportImage(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // For Web, we can't easily use path_provider or Share.shareXFiles(file)
      // The best way for "Download" is using the share_plus web implementation
      // or a direct anchor download.
      // share_plus on web supports XFile.fromData and will trigger a download or share.

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile.fromData(bytes, name: fileName, mimeType: 'image/png'),
      ], text: 'Poster ini dibuat otomatis lewat KBM App');
    } else {
      // Mobile / Desktop logic
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Poster ini dibuat otomatis lewat KBM App');
      } catch (e) {
        debugPrint('Error exporting poster on mobile: $e');
        rethrow;
      }
    }
  }
}
