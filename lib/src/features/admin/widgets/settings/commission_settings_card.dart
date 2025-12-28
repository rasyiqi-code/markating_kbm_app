import 'package:flutter/material.dart';

class CommissionSettingsCard extends StatelessWidget {
  final bool enableR1Commission;
  final bool enableR2Commission;
  final TextEditingController bonusR1Controller;
  final TextEditingController bonusR2Controller;
  final ValueChanged<bool> onR1CommissionChanged;
  final ValueChanged<bool> onR2CommissionChanged;

  const CommissionSettingsCard({
    super.key,
    required this.enableR1Commission,
    required this.enableR2Commission,
    required this.bonusR1Controller,
    required this.bonusR2Controller,
    required this.onR1CommissionChanged,
    required this.onR2CommissionChanged,
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
            title: const Text('Aktifkan Komisi Tunai R1'),
            value: enableR1Commission,
            onChanged: onR1CommissionChanged,
          ),
          if (enableR1Commission)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: bonusR1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Persentase Komisi R1',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Aktifkan Komisi Tunai R2'),
            value: enableR2Commission,
            onChanged: onR2CommissionChanged,
          ),
          if (enableR2Commission)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: bonusR2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Persentase Komisi R2',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
