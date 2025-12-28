import 'package:flutter/material.dart';

class BonusPulsaSettingsCard extends StatelessWidget {
  final bool enableR1PulsaBonus;
  final bool enableR2PulsaBonus;
  final TextEditingController pulsaBonusController;
  final TextEditingController pulsaBonusR2Controller;
  final ValueChanged<bool> onR1PulsaBonusChanged;
  final ValueChanged<bool> onR2PulsaBonusChanged;

  final bool enableMinSalesLimit;
  final TextEditingController minSalePulsaController;
  final ValueChanged<bool> onMinSalesLimitChanged;

  final bool enableMaxPulsaBonusLimit;
  final TextEditingController maxPulsaBonusCountController;
  final ValueChanged<bool> onMaxPulsaBonusLimitChanged;

  final bool enableMinCompletedSalesLimit;
  final TextEditingController minCompletedSalesCountController;
  final ValueChanged<bool> onMinCompletedSalesLimitChanged;

  const BonusPulsaSettingsCard({
    super.key,
    required this.enableR1PulsaBonus,
    required this.enableR2PulsaBonus,
    required this.pulsaBonusController,
    required this.pulsaBonusR2Controller,
    required this.onR1PulsaBonusChanged,
    required this.onR2PulsaBonusChanged,
    required this.enableMinSalesLimit,
    required this.minSalePulsaController,
    required this.onMinSalesLimitChanged,
    required this.enableMaxPulsaBonusLimit,
    required this.maxPulsaBonusCountController,
    required this.onMaxPulsaBonusLimitChanged,
    required this.enableMinCompletedSalesLimit,
    required this.minCompletedSalesCountController,
    required this.onMinCompletedSalesLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // R1 Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Paket R1 (Penerbitan)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Aktifkan Bonus Pulsa R1'),
                  value: enableR1PulsaBonus,
                  onChanged: onR1PulsaBonusChanged,
                  contentPadding: EdgeInsets.zero,
                ),
                TextFormField(
                  controller: pulsaBonusController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Bonus',
                    prefixText: 'Rp ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // R2 Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Paket R2 (KBM Creator)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Aktifkan Bonus Pulsa R2'),
                  value: enableR2PulsaBonus,
                  onChanged: onR2PulsaBonusChanged,
                  contentPadding: EdgeInsets.zero,
                ),
                TextFormField(
                  controller: pulsaBonusR2Controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Bonus',
                    prefixText: 'Rp ',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Global Rules
          const Row(
            children: [
              Icon(Icons.gavel_rounded, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Aturan & Batasan (Global)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Wajib Mencapai Target Penjualan'),
            subtitle: const Text(
              'Bonus cair jika TOTAL penjualan bulan ini mencapai target',
            ),
            value: enableMinSalesLimit,
            onChanged: onMinSalesLimitChanged,
            contentPadding: EdgeInsets.zero,
          ),
          if (enableMinSalesLimit)
            TextFormField(
              controller: minSalePulsaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Akumulasi Penjualan (Bulanan)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                helperText:
                    'Min. total penjualan sebulan agar bonus cair (R1 & R2)',
              ),
            ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('Batasi Frekuensi Bulanan'),
            subtitle: const Text('Maksimal kali dapat bonus per bulan'),
            value: enableMaxPulsaBonusLimit,
            onChanged: onMaxPulsaBonusLimitChanged,
            contentPadding: EdgeInsets.zero,
          ),
          if (enableMaxPulsaBonusLimit)
            TextFormField(
              controller: maxPulsaBonusCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maksimal (Kali)',
                border: OutlineInputBorder(),
                helperText: 'Contoh: 1x sebulan',
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Syarat Riwayat Penjualan'),
            subtitle: const Text('Minimal total transaksi sukses bulan ini'),
            value: enableMinCompletedSalesLimit,
            onChanged: onMinCompletedSalesLimitChanged,
            contentPadding: EdgeInsets.zero,
          ),
          if (enableMinCompletedSalesLimit)
            TextFormField(
              controller: minCompletedSalesCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Min. Akumulasi Transaksi (Bulanan)',
                border: OutlineInputBorder(),
                helperText: 'Alternatif jika target nominal tidak tercapai',
              ),
            ),
        ],
      ),
    );
  }
}
