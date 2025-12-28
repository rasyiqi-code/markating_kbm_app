import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/services/data_seeder_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/announcement_settings_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/appearance_settings_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/bonus_pulsa_settings_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/commission_settings_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/danger_zone_settings_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/settings/withdrawal_settings_card.dart';
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
            double.tryParse(_minSalePulsaController.text) ?? 10000000,

        pulsaBonusAmountR2:
            double.tryParse(_pulsaBonusR2Controller.text) ?? 50000,
        // Sync R2 Min Sale with Global (R1) Controller
        minSaleForPulsaR2:
            double.tryParse(_minSalePulsaController.text) ?? 10000000,

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
          'PERINGATAN: Tindakan ini akan MENGHAPUS SEMUA data (Produk, Penjualan, Riwayat Saldo, Notifikasi, dan Reset Saldo Pengguna) secara permanen.\n\nData yang dihapus TIDAK BISA dipulihkan. Apakah Anda yakin?',
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                AppearanceSettingsCard(
                  enableR1: _enableR1,
                  enableR2: _enableR2,
                  onR1Changed: (val) => setState(() => _enableR1 = val),
                  onR2Changed: (val) => setState(() => _enableR2 = val),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Pengumuman & Link',
                  Icons.campaign_rounded,
                ),
                AnnouncementSettingsCard(
                  latestInfoController: _latestInfoController,
                  webBaseUrlController: _webBaseUrlController,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Komisi Penjualan (Tunai)',
                  Icons.monetization_on_rounded,
                ),
                CommissionSettingsCard(
                  enableR1Commission: _enableR1Commission,
                  enableR2Commission: _enableR2Commission,
                  bonusR1Controller: _bonusR1Controller,
                  bonusR2Controller: _bonusR2Controller,
                  onR1CommissionChanged: (val) =>
                      setState(() => _enableR1Commission = val),
                  onR2CommissionChanged: (val) =>
                      setState(() => _enableR2Commission = val),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Pengaturan Bonus Pulsa',
                  Icons.phonelink_ring_rounded,
                ),
                BonusPulsaSettingsCard(
                  enableR1PulsaBonus: _enableR1PulsaBonus,
                  enableR2PulsaBonus: _enableR2PulsaBonus,
                  pulsaBonusController: _pulsaBonusController,
                  pulsaBonusR2Controller: _pulsaBonusR2Controller,
                  onR1PulsaBonusChanged: (val) =>
                      setState(() => _enableR1PulsaBonus = val),
                  onR2PulsaBonusChanged: (val) =>
                      setState(() => _enableR2PulsaBonus = val),
                  enableMinSalesLimit: _enableMinSalesLimit,
                  minSalePulsaController: _minSalePulsaController,
                  onMinSalesLimitChanged: (val) =>
                      setState(() => _enableMinSalesLimit = val),
                  enableMaxPulsaBonusLimit: _enableMaxPulsaBonusLimit,
                  maxPulsaBonusCountController: _maxPulsaBonusCountController,
                  onMaxPulsaBonusLimitChanged: (val) =>
                      setState(() => _enableMaxPulsaBonusLimit = val),
                  enableMinCompletedSalesLimit: _enableMinCompletedSalesLimit,
                  minCompletedSalesCountController:
                      _minCompletedSalesCountController,
                  onMinCompletedSalesLimitChanged: (val) =>
                      setState(() => _enableMinCompletedSalesLimit = val),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Penarikan Dana (Withdrawal)',
                  Icons.account_balance_wallet_rounded,
                ),
                WithdrawalSettingsCard(
                  minPayoutController: _minPayoutController,
                  minPulsaWithdrawalController: _minPulsaWithdrawalController,
                  allowedWithdrawalDays: _allowedWithdrawalDays,
                  onDayToggle: (day) {
                    setState(() {
                      if (_allowedWithdrawalDays.contains(day)) {
                        _allowedWithdrawalDays.remove(day);
                      } else {
                        _allowedWithdrawalDays.add(day);
                      }
                    });
                  },
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
                DangerZoneSettingsCard(
                  isLoading: _isLoading,
                  onSeedData: _seedData,
                  onResetData: _resetData,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface; // Colors.black87
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
