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
  late TextEditingController _minPulsaWithdrawalController; // New
  late TextEditingController _latestInfoController;
  late TextEditingController _webBaseUrlController;

  // New Controllers
  late TextEditingController _maxPulsaBonusCountController;
  late TextEditingController _minCompletedSalesCountController;

  bool _enableR1 = true;
  bool _enableR2 = true;

  // Granular Reward Toggles
  bool _enableR1Commission = true;
  bool _enableR1PulsaBonus = true;
  bool _enableR2Commission = true;

  bool _enableR2PulsaBonus = true;

  // New Limit Toggles
  bool _enableMaxPulsaBonusLimit = false;
  bool _enableMinCompletedSalesLimit = false;
  bool _enableMinSalesLimit = true;

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
    _minPulsaWithdrawalController = TextEditingController();
    _latestInfoController = TextEditingController();
    _webBaseUrlController = TextEditingController();
    _maxPulsaBonusCountController = TextEditingController();
    _minCompletedSalesCountController = TextEditingController();
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
          _minPulsaWithdrawalController.text = settings.minPulsaWithdrawal
              .toStringAsFixed(0);
          _latestInfoController.text = settings.latestInfo;
          _webBaseUrlController.text = settings.webBaseUrl;

          _enableR1 = settings.enableR1;
          _enableR2 = settings.enableR2;

          _enableR1Commission = settings.enableR1Commission;
          _enableR1PulsaBonus = settings.enableR1PulsaBonus;
          _enableR2Commission = settings.enableR2Commission;

          _enableR2PulsaBonus = settings.enableR2PulsaBonus;
          _allowedWithdrawalDays = List.from(settings.allowedWithdrawalDays);

          _enableMaxPulsaBonusLimit = settings.enableMaxPulsaBonusLimit;
          _maxPulsaBonusCountController.text = settings.maxPulsaBonusCount
              .toString();
          _enableMinCompletedSalesLimit = settings.enableMinCompletedSalesLimit;
          _minCompletedSalesCountController.text = settings
              .minCompletedSalesCount
              .toString();
          _enableMinSalesLimit = settings.enableMinSalesLimit;
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
        // Sync R2 Min Sale with Global (R1) Controller
        minSaleForPulsaR2:
            double.tryParse(_minSalePulsaController.text) ?? 5000000,

        minPayout: double.tryParse(_minPayoutController.text) ?? 0,
        minPulsaWithdrawal:
            double.tryParse(_minPulsaWithdrawalController.text) ?? 20000,

        enableR1: _enableR1,
        enableR2: _enableR2,

        enableR1Commission: _enableR1Commission,
        enableR1PulsaBonus: _enableR1PulsaBonus,
        enableR2Commission: _enableR2Commission,

        enableR2PulsaBonus: _enableR2PulsaBonus,
        allowedWithdrawalDays: _allowedWithdrawalDays,
        latestInfo: _latestInfoController.text,
        webBaseUrl: _webBaseUrlController.text,

        enableMaxPulsaBonusLimit: _enableMaxPulsaBonusLimit,
        maxPulsaBonusCount:
            int.tryParse(_maxPulsaBonusCountController.text) ?? 1,
        enableMinCompletedSalesLimit: _enableMinCompletedSalesLimit,
        minCompletedSalesCount:
            int.tryParse(_minCompletedSalesCountController.text) ?? 5,
        enableMinSalesLimit: _enableMinSalesLimit,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaturan Global'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(
                  'Tampilan & Menu',
                  Icons.dashboard_customize_rounded,
                ),
                _buildStyledCard(
                  children: [
                    SwitchListTile(
                      title: const Text('Menu Penerbitan Buku (R1)'),
                      subtitle: const Text('Tampilkan menu R1 di Dashboard'),
                      value: _enableR1,
                      onChanged: (val) => setState(() => _enableR1 = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Menu KBM Creator (R2)'),
                      subtitle: const Text('Tampilkan menu R2 di Dashboard'),
                      value: _enableR2,
                      onChanged: (val) => setState(() => _enableR2 = val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Pengumuman & Link',
                  Icons.campaign_rounded,
                ),
                _buildStyledCard(
                  children: [
                    TextFormField(
                      controller: _latestInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Info Terkini',
                        hintText:
                            'Contoh: Batas klaim pulsa bulan ini: Tgl 25.',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
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
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Komisi Penjualan (Tunai)',
                  Icons.monetization_on_rounded,
                ),
                _buildStyledCard(
                  children: [
                    SwitchListTile(
                      title: const Text('Aktifkan Komisi Tunai R1'),
                      value: _enableR1Commission,
                      onChanged: (val) =>
                          setState(() => _enableR1Commission = val),
                    ),
                    if (_enableR1Commission)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _bonusR1Controller,
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
                      value: _enableR2Commission,
                      onChanged: (val) =>
                          setState(() => _enableR2Commission = val),
                    ),
                    if (_enableR2Commission)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextFormField(
                          controller: _bonusR2Controller,
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
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Pengaturan Bonus Pulsa',
                  Icons.phonelink_ring_rounded,
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
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
                              value: _enableR1PulsaBonus,
                              onChanged: (val) =>
                                  setState(() => _enableR1PulsaBonus = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                            TextFormField(
                              controller: _pulsaBonusController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Nominal Bonus',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
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
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                          ),
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
                              value: _enableR2PulsaBonus,
                              onChanged: (val) =>
                                  setState(() => _enableR2PulsaBonus = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                            TextFormField(
                              controller: _pulsaBonusR2Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Nominal Bonus',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Global Rules
                      const Row(
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Aturan & Batasan (Global)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Wajib Mencapai Target Penjualan'),
                        subtitle: const Text(
                          'Bonus hanya cair jika penjualan > nominal tertentu',
                        ),
                        value: _enableMinSalesLimit,
                        onChanged: (val) =>
                            setState(() => _enableMinSalesLimit = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_enableMinSalesLimit)
                        TextFormField(
                          controller: _minSalePulsaController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target Minimal Penjualan',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                            helperText:
                                'Berlaku untuk paket R1 & R2 secara bersamaan',
                          ),
                        ),
                      const Divider(height: 32),
                      SwitchListTile(
                        title: const Text('Batasi Frekuensi Bulanan'),
                        subtitle: const Text(
                          'Maksimal kali dapat bonus per bulan',
                        ),
                        value: _enableMaxPulsaBonusLimit,
                        onChanged: (val) =>
                            setState(() => _enableMaxPulsaBonusLimit = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_enableMaxPulsaBonusLimit)
                        TextFormField(
                          controller: _maxPulsaBonusCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maksimal (Kali)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Syarat Riwayat Penjualan'),
                        subtitle: const Text(
                          'Minimal total transaksi sukses sebelumnya',
                        ),
                        value: _enableMinCompletedSalesLimit,
                        onChanged: (val) =>
                            setState(() => _enableMinCompletedSalesLimit = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_enableMinCompletedSalesLimit)
                        TextFormField(
                          controller: _minCompletedSalesCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimal Transaksi Selesai',
                            border: OutlineInputBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Penarikan Dana (Withdrawal)',
                  Icons.account_balance_wallet_rounded,
                ),
                _buildStyledCard(
                  children: [
                    TextFormField(
                      controller: _minPayoutController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min. Penarikan Bank',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minPulsaWithdrawalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min. Klaim Pulsa',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Jadwal Penarikan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final itemSize = (width - (6 * 8)) / 7;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final dayName = [
                              'S',
                              'S',
                              'R',
                              'K',
                              'J',
                              'S',
                              'M',
                            ][index];
                            final isSelected = _allowedWithdrawalDays.contains(
                              day,
                            );
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _allowedWithdrawalDays.remove(day);
                                  } else {
                                    _allowedWithdrawalDays.add(day);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: itemSize,
                                height: itemSize,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    dayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildSectionHeader(
                  'Area Berbahaya',
                  Icons.warning_rounded,
                  color: Colors.red,
                ),
                _buildStyledCard(
                  color: Colors.red[50],
                  children: [
                    const Text(
                      'Manajemen Data Demo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
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
                            onPressed: _isLoading ? null : _seedData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(
                                color: Colors.green,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Reset Data'),
                            onPressed: _isLoading ? null : _resetData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledCard({required List<Widget> children, Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
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
        children: children,
      ),
    );
  }
}
