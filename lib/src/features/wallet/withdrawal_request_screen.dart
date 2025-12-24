import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart'; // Import Settings
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  final UserModel user;
  final String allowedType; // ClaimModel.typeBank or typePulsa

  const WithdrawalRequestScreen({
    super.key,
    required this.user,
    required this.allowedType,
  });

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  late TextEditingController _amountController;
  late TextEditingController _infoController;
  bool _isLoading = false;

  bool get isBank => widget.allowedType == ClaimModel.typeBank;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _infoController = TextEditingController(text: _getAutoFillText());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  String _getAutoFillText() {
    final user = widget.user;
    if (user.bankDetails == null || user.bankDetails!.isEmpty) return '';

    if (isBank) {
      final bankName = user.bankDetails!['bank_name'] ?? '';
      final accNum = user.bankDetails!['account_number'] ?? '';
      final holder = user.bankDetails!['account_holder'] ?? '';

      if (bankName.isNotEmpty && accNum.isNotEmpty) {
        return '$bankName $accNum a.n $holder'.trim();
      }
      if (bankName.isNotEmpty) return bankName;
      if (accNum.isNotEmpty) return accNum;
      return '';
    } else {
      return user.bankDetails!['phone'] ?? '';
    }
  }

  Future<void> _submitRequest(GlobalSettingsModel settings) async {
    final amount =
        int.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
      return;
    }

    if (amount < settings.minPayout) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimal penarikan adalah ${AppFormatters.currency(settings.minPayout)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_infoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isBank ? 'Isi data bank' : 'Isi nomor HP')),
      );
      return;
    }

    // Balance Check
    final currentBalance = isBank
        ? widget.user.commissionBalance
        : widget.user.pulsaBalance;
    if (amount > currentBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saldo tidak mencukupi')));
      return;
    }

    setState(() => _isLoading = true);

    final claim = ClaimModel(
      id: '',
      userId: widget.user.id,
      amount: amount,
      type: widget.allowedType,
      status: ClaimModel.statusPending,
      bankDetails: {'info': _infoController.text.trim()},
      createdAt: DateTime.now(),
    );

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final claimId = await firestore.requestClaim(claim);

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: isBank ? 'Permintaan Withdraw Baru' : 'Permintaan Pulsa Baru',
        body:
            '${widget.user.name ?? "User"} meminta ${isBank ? "withdraw" : "pulsa"} sebesar ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(amount)}',
        type: NotificationModel.typeInfo,
        recipientId: 'role:admin',
        relatedId: claimId,
        createdAt: DateTime.now(),
      );
      await firestore.sendNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permintaan terkirim!')));
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isBank ? 'Tarik Saldo Komisi' : 'Klaim Saldo Pulsa';
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<GlobalSettingsModel>(
        stream: firestore.getGlobalSettings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;
          final today = DateTime.now().weekday;
          final isAllowedDay = settings.allowedWithdrawalDays.contains(today);
          final dayName = [
            'Senin',
            'Selasa',
            'Rabu',
            'Kamis',
            'Jumat',
            'Sabtu',
            'Minggu',
          ][today - 1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isAllowedDay)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Penarikan tidak tersedia hari ini ($dayName). Silakan cek jadwal operasional.',
                            style: GoogleFonts.outfit(
                              color: Colors.red[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Balance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isBank
                          ? [Colors.blue.shade700, Colors.blue.shade500]
                          : [Colors.orange.shade700, Colors.orange.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isBank ? Colors.blue : Colors.orange)
                            .withValues(alpha: 0.3),
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Saldo Tersedia',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.currency(
                          isBank
                              ? widget.user.commissionBalance
                              : widget.user.pulsaBalance,
                        ),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isBank
                      ? 'Dana akan ditransfer ke rekening bank Anda.'
                      : 'Pulsa akan dikirim ke nomor HP Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),

                if (settings.minPayout > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Minimal penarikan: ${AppFormatters.currency(settings.minPayout)}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Form
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  enabled: isAllowedDay,
                  decoration: InputDecoration(
                    labelText: 'Nominal Penarikan',
                    border: const OutlineInputBorder(),
                    prefixText: 'Rp ',
                    suffixIcon: TextButton(
                      onPressed: isAllowedDay
                          ? () {
                              final max = isBank
                                  ? widget.user.commissionBalance
                                  : widget.user.pulsaBalance;
                              setState(() {
                                _amountController.text = max.toStringAsFixed(0);
                              });
                            }
                          : null,
                      child: const Text('Tarik Semua'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _infoController,
                  readOnly: true, // User request: ReadOnly
                  enabled: isAllowedDay,
                  decoration: InputDecoration(
                    labelText: isBank ? 'Bank & No. Rekening' : 'Nomor HP',
                    border: const OutlineInputBorder(),
                    hintText: isBank ? 'Belum diset' : 'Belum diset',
                    filled: true,
                    fillColor: Colors.grey[100],
                    helperText: (_infoController.text.isNotEmpty)
                        ? 'Data dikunci. Ubah via Profile.'
                        : 'Mohon lengkapi data di menu Profile.',
                    helperStyle: TextStyle(
                      color: _infoController.text.isEmpty ? Colors.red : null,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Silakan ubah data di menu Profile'),
                          ),
                        );
                        // Optionally navigate to Profile
                      },
                      tooltip: 'Ubah di Profile',
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading ||
                            _infoController.text.isEmpty ||
                            !isAllowedDay)
                        ? null
                        : () => _submitRequest(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim Permintaan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
