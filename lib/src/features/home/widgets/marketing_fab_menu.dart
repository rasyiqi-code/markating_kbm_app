import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketingFabMenu extends StatelessWidget {
  const MarketingFabMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Sale',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildFabOption(
                  context,
                  'Penerbitan',
                  Icons.book_rounded,
                  Colors.blue,
                  '/sales/r1',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFabOption(
                  context,
                  'KBM Creator',
                  Icons.brush_rounded,
                  Colors.purple,
                  '/sales/r2',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFabOption(
                  context,
                  'Poster Generator',
                  Icons.auto_awesome_rounded,
                  Colors.orange,
                  '/poster_generator',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFabOption(
    BuildContext context,
    String title,
    IconData icon,
    MaterialColor color,
    String route,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? color.shade900.withValues(alpha: 0.3)
              : color.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? color.shade700
                : color.shade100,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? color.shade100
                    : color.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
