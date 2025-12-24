import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveWebLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveWebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only apply on Web
    if (!kIsWeb) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Container(
            color: Colors.grey[200], // Background for empty space
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRect(child: child), // Clip to bounds
            ),
          );
        }
        return child;
      },
    );
  }
}
