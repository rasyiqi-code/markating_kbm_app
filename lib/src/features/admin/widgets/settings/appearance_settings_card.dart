import 'package:flutter/material.dart';

class AppearanceSettingsCard extends StatelessWidget {
  final bool enableR1;
  final bool enableR2;
  final ValueChanged<bool> onR1Changed;
  final ValueChanged<bool> onR2Changed;

  const AppearanceSettingsCard({
    super.key,
    required this.enableR1,
    required this.enableR2,
    required this.onR1Changed,
    required this.onR2Changed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: const Text('Menu Penerbitan Buku (R1)'),
            subtitle: const Text('Tampilkan menu R1 di Dashboard'),
            value: enableR1,
            onChanged: onR1Changed,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Menu KBM Creator (R2)'),
            subtitle: const Text('Tampilkan menu R2 di Dashboard'),
            value: enableR2,
            onChanged: onR2Changed,
          ),
        ],
      ),
    );
  }
}
