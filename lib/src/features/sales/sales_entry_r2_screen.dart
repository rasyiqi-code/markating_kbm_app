import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
// import 'package:markating_kbm_app/src/core/services/storage_service.dart';
// import 'package:image_picker/image_picker.dart';

import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/notification_service.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';
import 'package:markating_kbm_app/src/core/utils/currency_input_formatter.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/product_picker_field.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/markup_input_field.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/sales_text_field.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/transaction_proof_input.dart';

class SalesEntryR2Screen extends StatefulWidget {
  const SalesEntryR2Screen({super.key});

  @override
  State<SalesEntryR2Screen> createState() => _SalesEntryR2ScreenState();
}

class _SalesEntryR2ScreenState extends State<SalesEntryR2Screen> {
  // ... (keep start of file) ...

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _transactionProofUrl;
  String _agentName = '';

  // Common Fields
  ProductModel? _selectedProduct;
  final _unitPriceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _totalPriceController = TextEditingController();
  final _markupController = TextEditingController(); // Markup per item
  final _dpAmountController = TextEditingController();

  String _paymentStatus = 'DP';

  // Calculated values
  double _commissionAmount = 0;
  double _pulsaBonusAmount = 0;

  // Limits Logic
  int _userMonthlyBonusCount = 0;
  int _monthlySalesCount = 0;
  double _monthlySalesTotal = 0;

  // R2 Specific Fields
  final _mitraController = TextEditingController();
  final _judulLayoutController = TextEditingController();
  final _ukuranController = TextEditingController();
  final _halamanController = TextEditingController();

  // Data Sources
  GlobalSettingsModel? _settings;
  late Stream<List<ProductModel>> _productsStream;

  @override
  void initState() {
    super.initState();
    // House Type 2 = KBM Kreator
    _productsStream = Provider.of<FirestoreService>(
      context,
      listen: false,
    ).getProducts(2);
    _loadSettings();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = await auth.getCurrentUserDetails();

    if (mounted && user != null) {
      // Fetch stats for limits
      final monthlyBonuses = await firestore.getUserBonusCountThisMonth(
        user.id,
      );
      // Fetch accumulated stats
      final monthlyStats = await firestore.getUserSalesStatsThisMonth(user.id);

      setState(() {
        _agentName = (user.name != null && user.name!.isNotEmpty)
            ? user.name!
            : user.email.split('@').first;
        _userMonthlyBonusCount = monthlyBonuses;
        _monthlySalesCount = monthlyStats['count'] as int;
        _monthlySalesTotal = monthlyStats['total'] as double;
      });
      _calculateValues();
    }
  }

  void _loadSettings() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    firestore.getGlobalSettings().listen((settings) {
      if (mounted) {
        setState(() => _settings = settings);
        _calculateValues();
      }
    });
  }

  void _onProductChanged(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _unitPriceController.text = AppFormatters.formatNumber(product.price);
      }
      _calculateValues();
    });
  }

  void _calculateValues() {
    // 1. Calculate Total
    double unitPrice =
        double.tryParse(
          _unitPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    int qty = int.tryParse(_qtyController.text) ?? 1;
    double total = unitPrice * qty;
    _totalPriceController.text = AppFormatters.formatNumber(total);

    if (_settings == null) return;

    // 2. Calculate Commission & Bonus
    // R2 Commission
    if (_settings!.enableR2Commission) {
      _commissionAmount = total * (_settings!.bonusPercentR2 / 100);
    } else {
      _commissionAmount = 0;
    }

    // R2 Pulsa Bonus (Accumulated Logic with Crossing Threshold)
    if (_settings!.enableR2PulsaBonus) {
      // 1. Check strict limit first
      bool limitReached = false;
      if (_settings!.enableMaxPulsaBonusLimit) {
        if (_userMonthlyBonusCount >= _settings!.maxPulsaBonusCount) {
          limitReached = true;
        }
      }

      if (limitReached) {
        _pulsaBonusAmount = 0;
      } else {
        // 2. Check Crossing Logic

        // Thresholds (Use R2 specific if available, or fallback/sync)
        final double targetNominal = _settings!.minSaleForPulsaR2;
        final int targetCount =
            _settings!.minCompletedSalesCount; // Shared count target

        // Condition A: Crosses Nominal
        bool crossesNominal = false;
        if (_settings!.enableMinSalesLimit) {
          crossesNominal = (_monthlySalesTotal < targetNominal) &&
              ((_monthlySalesTotal + total) >= targetNominal);
        }

        // Condition B: Crosses Count
        bool crossesCount = false;
        if (_settings!.enableMinCompletedSalesLimit) {
          crossesCount = (_monthlySalesCount < targetCount) &&
              ((_monthlySalesCount + 1) >= targetCount);
        }

        if (crossesNominal || crossesCount) {
          _pulsaBonusAmount = _settings!.pulsaBonusAmountR2;
        } else {
          _pulsaBonusAmount = 0;
        }
      }
    } else {
      _pulsaBonusAmount = 0;
    }

    if (mounted) setState(() {});
  }



  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih produk/paket terlebih dahulu ya'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = await auth.getCurrentUserDetails();

      if (user == null) throw Exception('Pengguna tidak ditemukan');

      // Construct Details Map
      final qty = int.parse(_qtyController.text);
      final markupPerQty =
          int.tryParse(
            _markupController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final totalMarkup = markupPerQty * qty;

      double unitPrice =
          double.tryParse(
            _unitPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      // Determine Paid Amount
      double paidAmount = 0;
      if (_paymentStatus == 'LUNAS') {
        paidAmount =
            double.tryParse(
              _totalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
      } else {
        // DP
        paidAmount =
            double.tryParse(
              _dpAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
      }

      final sale = SaleModel(
        id: '', // Auto-gen
        userId: user.id,
        productId: _selectedProduct!.id,
        details: {
          'product_name': _selectedProduct!.name,
          'product_price': unitPrice,
          'quantity': qty,
          'mitra': _mitraController.text.trim(),
          'judul_layout': _judulLayoutController.text.trim(),
          'ukuran': _ukuranController.text.trim(),
          'halaman': _halamanController.text.trim(),
          'bonus_multiplier': _userMonthlyBonusCount < 5 ? 0 : 1, // Example
          'markup_per_qty': markupPerQty,
          'house_type': 2, // Creator
          'agent_name': user.name ?? 'Unknown',
        },
        totalPrice: double.parse(
          _totalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ),
        paymentStatus: SaleModel.statusPending, // Force Pending
        bonusAmount: 0, // Calculated by server/admin later or here
        commissionAmount: _commissionAmount,
        commissionEarned: _commissionAmount.toInt(), // Save as int for legacy
        markupPerQty: markupPerQty,
        totalMarkup: totalMarkup,
        pulsaBonusAmount: _pulsaBonusAmount,
        paidAmount: paidAmount,
        createdAt: DateTime.now(),
        transactionProofUrl: _transactionProofUrl,
      );

      // Add requested status for Admin visibility
      sale.details['requested_status'] = _paymentStatus;

      await firestore.addSale(sale);

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: 'Transaksi Baru (KBM Kreator)',
        body:
            '${user.name ?? "Marketing"} baru saja submit naskah "${_judulLayoutController.text}". Total: ${AppFormatters.currency(sale.totalPrice)}',
        type: NotificationModel.typeInfo,
        recipientId: 'role:admin',
        createdAt: DateTime.now(),
      );
      await firestore.sendNotification(notification);

      if (mounted) {
        try {
          final notificationService = Provider.of<NotificationService>(
            context,
            listen: false,
          );
          await notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Penjualan Berhasil!',
            body:
                'Data penjualan saved. Total: ${AppFormatters.currency(sale.totalPrice)}',
          );
        } catch (e) {
          debugPrint('Notification error: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
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

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.secondaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.post_add_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Input Jasa Creator',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.creatorGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_agentName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Login sebagai: $_agentName',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color:
                                Colors.purpleAccent, // Brighter for dark mode
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              _buildSectionTitle('Informasi Produk'),
              const SizedBox(height: 16),
              _buildProductDropdown(color),

              const SizedBox(height: 32),
              _buildSectionTitle('Detail Pesanan'),
              const SizedBox(height: 16),

              SalesTextField(
                controller: _mitraController,
                label: 'Nama Penerbit Kampus/Swasta',
                icon: Icons.business_rounded,
              ),
              const SizedBox(height: 16),
              SalesTextField(
                controller: _judulLayoutController,
                label: 'Judul Naskah Layout / Desain Cover',
                icon: Icons.design_services_outlined,
              ),
              const SizedBox(height: 16),
              // Logic: Hide Ukuran & Jml Halaman if product is Cover Jasa
              if (_selectedProduct != null &&
                  !_selectedProduct!.name.toLowerCase().contains('cover'))
                Row(
                  children: [
                    Expanded(
                      child: SalesTextField(
                        controller: _ukuranController,
                        label: 'Ukuran (Naskah/Cetak)',
                        icon: Icons.aspect_ratio_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SalesTextField(
                        controller: _halamanController,
                        label: 'Jml Halaman',
                        icon: Icons.description_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 32),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 32),

              _buildSectionTitle('Pembayaran & Kalkulasi'),
              const SizedBox(height: 16),

              // Unit Price & Qty
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SalesTextField(
                      controller: _unitPriceController,
                      label: 'Harga Satuan',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      prefixText: 'Rp ',
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => _calculateValues(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SalesTextField(
                      controller: _qtyController,
                      label: 'Jumlah (Judul/Ex)',
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateValues(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SalesTextField(
                controller: _totalPriceController,
                label: 'Total Yang Harus Dibayar',
                icon: Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
                prefixText: 'Rp ',
                // inputFormatters: [CurrencyInputFormatter()],
                onChanged: (_) {},
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Status Pembayaran',
                  labelStyle: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.payment_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                      Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'DP', child: Text('DP (Uang Muka)')),
                  DropdownMenuItem(
                    value: 'LUNAS',
                    child: Text('LUNAS (Bayar Penuh)'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _paymentStatus = val!;
                    _calculateValues();
                  });
                },
                isExpanded: true,
              ),

              const SizedBox(height: 16),

              // Markup Input (NEW)
              MarkupInputField(
                controller: _markupController,
                quantity: int.tryParse(_qtyController.text) ?? 1,
              ),

              if (_paymentStatus == 'DP') ...[
                const SizedBox(height: 16),
                SalesTextField(
                  controller: _dpAmountController,
                  label: 'Jumlah DP yang Dibayar',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  prefixText: 'Rp ',
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ],

              const SizedBox(height: 24),
              if (_paymentStatus == 'LUNAS')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pembayaran LUNAS. Komisi akan dihitung otomatis.',
                          style: GoogleFonts.outfit(
                            color: Colors.greenAccent, // Visible on dark
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              _buildSectionTitle('Bukti Transaksi'),
              const SizedBox(height: 12),
              TransactionProofInput(
                themeColor: color,
                initialUrl: _transactionProofUrl,
                onProofUploaded: (url) {
                  setState(() => _transactionProofUrl = url);
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: color.withValues(alpha: 0.4),
                  ),
                  onPressed: (_isLoading || _transactionProofUrl == null)
                      ? null
                      : _submitSale,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Buat Pesanan Sekarang',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }





  Widget _buildProductDropdown(Color color) {
    return ProductPickerField(
      stream: _productsStream,
      selectedProduct: _selectedProduct,
      onChanged: _onProductChanged,
      label: 'Pilih Layanan',
      color: color,
    );
  }
}
