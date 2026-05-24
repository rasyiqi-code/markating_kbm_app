import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class NetworkImageWeb extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const NetworkImageWeb({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Clean URL if it's an old presigned one
    String finalUrl = imageUrl;
    if (imageUrl.contains('r2.cloudflarestorage.com')) {
      try {
        final uri = Uri.parse(imageUrl);
        final segments = uri.pathSegments;
        if (segments.length > 1) {
          // Skip bucket name, get the rest
          final objectPath = segments.sublist(1).join('/').split('?').first;
          finalUrl = 'https://poster.librarypenerbitkbm.science/$objectPath';
        }
      } catch (_) {
        // Fallback to original
      }
    }

    final String viewID = 'img-view-${finalUrl.hashCode}';

    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      final web.HTMLImageElement img =
          web.document.createElement('img') as web.HTMLImageElement;
      img.src = finalUrl;
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = _getFitString(fit);
      
      // Add crossOrigin to help with R2/CORS if needed
      img.crossOrigin = 'anonymous';
      
      // Fallback for CORS issues if image fails to load with anonymous
      img.onerror = ((web.Event e) {
        img.crossOrigin = ''; // Reset CORS and try again as normal
        img.src = finalUrl;
      }.toJS);

      return img;
    });

    return SizedBox(
      width: width,
      height: height,
      child: IgnorePointer(
        child: HtmlElementView(viewType: viewID),
      ),
    );
  }

  String _getFitString(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
        return 'fit-width';
      case BoxFit.fitHeight:
        return 'fit-height';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }
}
