import 'package:flutter/material.dart';

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

    return Image.network(
      finalUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ??
          const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
    );
  }
}
