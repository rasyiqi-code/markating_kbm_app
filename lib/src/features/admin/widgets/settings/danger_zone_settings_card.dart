import 'package:flutter/material.dart';

class DangerZoneSettingsCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSeedData;
  final VoidCallback onResetData;

  const DangerZoneSettingsCard({
    super.key,
    required this.isLoading,
    required this.onSeedData,
    required this.onResetData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
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
          const Text(
            'Manajemen Data Demo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan fitur ini hanya untuk keperluan testing.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Isi Demo'),
                  onPressed: isLoading ? null : onSeedData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset Data'),
                  onPressed: isLoading ? null : onResetData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
