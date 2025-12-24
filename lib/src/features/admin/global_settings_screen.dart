import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/services/data_seeder_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:provider/provider.dart';

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bonusR1Controller;
  late TextEditingController _bonusR2Controller;
  late TextEditingController _pulsaBonusController;
  late TextEditingController _minSalePulsaController;
  late TextEditingController _minSalePulsaR2Controller; // New
  late TextEditingController _pulsaBonusR2Controller; // New
  late TextEditingController _minPayoutController;
  late TextEditingController _latestInfoController;
  late TextEditingController _webBaseUrlController;

  bool _enableR1 = true;
  bool _enableR2 = true;

  // Granular Reward Toggles
  bool _enableR1Commission = true;
  bool _enableR1PulsaBonus = true;
  bool _enableR2Commission = true;

  bool _enableR2PulsaBonus = true;

  List<int> _allowedWithdrawalDays = [1, 2, 3, 4, 5, 6, 7];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bonusR1Controller = TextEditingController();
    _bonusR2Controller = TextEditingController();
    _pulsaBonusController = TextEditingController();
    _minSalePulsaController = TextEditingController();
    _minSalePulsaR2Controller = TextEditingController();
    _pulsaBonusR2Controller = TextEditingController();
    _minPayoutController = TextEditingController();
    _latestInfoController = TextEditingController();
    _webBaseUrlController = TextEditingController();
    _loadSettings();
  }

  void _loadSettings() {
    // Initial fetch to populate fields
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    firestore.getGlobalSettings().first.then((settings) {
      if (mounted) {
        setState(() {
          _bonusR1Controller.text = settings.bonusPercentR1.toString();
          _bonusR2Controller.text = settings.bonusPercentR2.toString();
          _pulsaBonusController.text = settings.pulsaBonusAmount
              .toStringAsFixed(0);
          _minSalePulsaController.text = settings.minSaleForPulsa
              .toStringAsFixed(0);
          _minSalePulsaR2Controller.text = settings.minSaleForPulsaR2
              .toStringAsFixed(0);
          _pulsaBonusR2Controller.text = settings.pulsaBonusAmountR2
              .toStringAsFixed(0);
          _minPayoutController.text = settings.minPayout.toStringAsFixed(0);
          _latestInfoController.text = settings.latestInfo;
          _webBaseUrlController.text = settings.webBaseUrl;

          _enableR1 = settings.enableR1;
          _enableR2 = settings.enableR2;

          _enableR1Commission = settings.enableR1Commission;
          _enableR1PulsaBonus = settings.enableR1PulsaBonus;
          _enableR2Commission = settings.enableR2Commission;

          _enableR2PulsaBonus = settings.enableR2PulsaBonus;
          _allowedWithdrawalDays = List.from(settings.allowedWithdrawalDays);
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final settings = GlobalSettingsModel(
        bonusPercentR1: double.tryParse(_bonusR1Controller.text) ?? 0,
        bonusPercentR2: double.tryParse(_bonusR2Controller.text) ?? 10,
        pulsaBonusAmount: double.tryParse(_pulsaBonusController.text) ?? 50000,
        minSaleForPulsa:
            double.tryParse(_minSalePulsaController.text) ?? 5000000,

        pulsaBonusAmountR2:
            double.tryParse(_pulsaBonusR2Controller.text) ?? 50000,
        minSaleForPulsaR2:
            double.tryParse(_minSalePulsaR2Controller.text) ?? 5000000,

        minPayout: double.tryParse(_minPayoutController.text) ?? 0,

        enableR1: _enableR1,
        enableR2: _enableR2,

        enableR1Commission: _enableR1Commission,
        enableR1PulsaBonus: _enableR1PulsaBonus,
        enableR2Commission: _enableR2Commission,

        enableR2PulsaBonus: _enableR2PulsaBonus,
        allowedWithdrawalDays: _allowedWithdrawalDays,
        latestInfo: _latestInfoController.text,
        webBaseUrl: _webBaseUrlController.text,
      );
      await firestore.updateGlobalSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seedData() async {
    setState(() => _isLoading = true);
    try {
      await DataSeederService().seedDemoData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data demo berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error seeding: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Semua Data?'),
        content: const Text(
          'Tindakan ini akan MENGHAPUS semua Produk dan Riwayat Penjualan dan tidak dapat dibatalkan.\n\nApakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Semuanya'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await DataSeederService().clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data berhasil dihapus!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Global')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tampilan Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Menu Penerbitan Buku (R1)'),
                  subtitle: const Text(
                    'Tampilkan/Sembunyikan Menu R1 di Dashboard',
                  ),
                  value: _enableR1,
                  onChanged: (val) => setState(() => _enableR1 = val),
                ),
                SwitchListTile(
                  title: const Text('Menu KBM Creator (R2)'),
                  subtitle: const Text(
                    'Tampilkan/Sembunyikan Menu R2 di Dashboard',
                  ),
                  value: _enableR2,
                  onChanged: (val) => setState(() => _enableR2 = val),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengumuman Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _latestInfoController,
                  decoration: const InputDecoration(
                    labelText: 'Info Terkini',
                    hintText: 'Contoh: Batas klaim pulsa bulan ini: Tgl 25.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _webBaseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL Dasar Web App',
                    hintText: 'https://kbm-group-app.web.app',
                    helperText: 'URL dasar untuk link Bio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Aturan Komisi & Bonus R1',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Aktifkan Komisi Tunai R1'),
                  value: _enableR1Commission,
                  onChanged: (val) => setState(() => _enableR1Commission = val),
                ),
                SwitchListTile(
                  title: const Text('Aktifkan Bonus Pulsa R1'),
                  subtitle: const Text(
                    'Otomatis kirim Pulsa jika > Min Penjualan',
                  ),
                  value: _enableR1PulsaBonus,
                  onChanged: (val) => setState(() => _enableR1PulsaBonus = val),
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _bonusR1Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Komisi R1 %',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minSalePulsaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Penjualan R1 untuk Pulsa',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pulsaBonusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Bonus Pulsa R1',
                    prefixText: 'Rp ',
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Aturan Komisi & Bonus R2', // Modified this line
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Aktifkan Komisi Tunai R2'),
                  value: _enableR2Commission,
                  onChanged: (val) => setState(() => _enableR2Commission = val),
                ),
                SwitchListTile(
                  // Added this SwitchListTile
                  title: const Text('Aktifkan Bonus Pulsa R2'),
                  subtitle: const Text(
                    'Otomatis kirim Pulsa jika > Min Penjualan R2',
                  ),
                  value: _enableR2PulsaBonus,
                  onChanged: (val) => setState(() => _enableR2PulsaBonus = val),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bonusR2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Komisi R2 %',
                    suffixText: '%',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minSalePulsaR2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Penjualan R2 untuk Pulsa',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pulsaBonusR2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal Bonus Pulsa R2',
                    prefixText: 'Rp ',
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // General / Withdrawal
                const Text(
                  'Pengaturan Penarikan (Withdrawal)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _minPayoutController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Batas Minimal Penarikan (Withdrawal)',
                    prefixText: 'Rp ',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 24),
                const Text(
                  'Jadwal Penarikan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Pilih hari dimana agen diizinkan melakukan penarikan.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...List.generate(7, (index) {
                  final day = index + 1;
                  final dayName = [
                    'Senin',
                    'Selasa',
                    'Rabu',
                    'Kamis',
                    'Jumat',
                    'Sabtu',
                    'Minggu',
                  ][index];
                  return CheckboxListTile(
                    title: Text(dayName),
                    value: _allowedWithdrawalDays.contains(day),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _allowedWithdrawalDays.add(day);
                        } else {
                          _allowedWithdrawalDays.remove(day);
                        }
                      });
                    },
                    dense: true,
                  );
                }),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Perubahan'),
                ),
                const SizedBox(height: 48),
                const Divider(thickness: 2),
                const SizedBox(height: 16),
                const Text(
                  'Manajemen Data Demo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan alat ini untuk mengisi data contoh atau menghapus data untuk produksi.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Isi Data Demo'),
                        onPressed: _isLoading ? null : _seedData,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Reset / Hapus Data'),
                        onPressed: _isLoading ? null : _resetData,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
