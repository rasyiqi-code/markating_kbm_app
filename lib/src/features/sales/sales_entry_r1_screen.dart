import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/notification_service.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';
import 'package:markating_kbm_app/src/core/utils/currency_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/product_picker_field.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/markup_input_field.dart';

class SalesEntryR1Screen extends StatefulWidget {
  const SalesEntryR1Screen({super.key});

  @override
  State<SalesEntryR1Screen> createState() => _SalesEntryR1ScreenState();
}

class _SalesEntryR1ScreenState extends State<SalesEntryR1Screen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingProof = false;
  String? _transactionProofUrl;
  String _agentName = ''; // To display confirmed agent name

  // Common Fields
  ProductModel? _selectedProduct;
  final _unitPriceController = TextEditingController(); // Harga per buku
  final _qtyController = TextEditingController(text: '1'); // Default 1
  final _totalPriceController =
      TextEditingController(); // Total yang harus dibayar
  final _markupController = TextEditingController(); // Markup per item
  final _dpAmountController = TextEditingController(); // DP Input

  String _paymentStatus = 'DP'; // DP, LUNAS

  // Calculated values
  double _commissionAmount = 0;
  double _pulsaBonusAmount = 0;

  // Limits Logic
  int _userMonthlyBonusCount = 0;
  int _monthlySalesCount = 0; // Accumulated count
  double _monthlySalesTotal = 0; // Accumulated total

  // R1 Specific Fields
  final _penulisController = TextEditingController();
  final _judulNaskahController = TextEditingController();

  // Data Sources
  GlobalSettingsModel? _settings;
  late Stream<List<ProductModel>> _productsStream;

  @override
  void initState() {
    super.initState();
    // House Type 1 = Penerbit KBM
    _productsStream = Provider.of<FirestoreService>(
      context,
      listen: false,
    ).getProducts(1);
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
      _calculateValues(); // Recalculate once we have stats
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
        // Auto-fill unit price
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
    // R1 Commission
    if (_settings!.enableR1Commission) {
      _commissionAmount = total * (_settings!.bonusPercentR1 / 100);
    } else {
      _commissionAmount = 0;
    }

    // R1 Pulsa Bonus (Accumulated Logic with Crossing Threshold)
    if (_settings!.enableR1PulsaBonus) {
      // 1. Check strict limit first
      // Assuming 'enableMaxPulsaBonusLimit' is true by default now as per requirements
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
        // We only award bonus if this SPECIFIC transaction makes them cross the line.

        // Thresholds
        final double targetNominal = _settings!.minSaleForPulsa;
        final int targetCount = _settings!.minCompletedSalesCount;

        // Condition A: Crosses Nominal Threshold
        // Previous Total < Target AND New Total >= Target
        bool crossesNominal =
            (_monthlySalesTotal < targetNominal) &&
            ((_monthlySalesTotal + total) >= targetNominal);

        // Condition B: Crosses Count Threshold
        // Previous Count < Target AND New Count (Current + 1) >= Target
        bool crossesCount =
            (_monthlySalesCount < targetCount) &&
            ((_monthlySalesCount + 1) >= targetCount);

        if (crossesNominal || crossesCount) {
          _pulsaBonusAmount = _settings!.pulsaBonusAmount;
        } else {
          _pulsaBonusAmount = 0;
        }
      }
    } else {
      _pulsaBonusAmount = 0;
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploadingProof = true);
      try {
        final storage = Provider.of<StorageService>(context, listen: false);
        final bytes = await pickedFile.readAsBytes();
        final filename =
            'transaction_proof_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        final url = await storage.uploadBytes(bytes, filename, 'transactions');

        if (!mounted) return;

        setState(() {
          _transactionProofUrl = url;
          _isUploadingProof = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti transaksi berhasil diunggah!')),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingProof = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih produk/paket')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthService>(context, listen: false);

    // Validation: Check for Zero values
    final double unitPrice =
        double.tryParse(
          _unitPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final int qty = int.tryParse(_qtyController.text) ?? 0;

    if (unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga satuan tidak boleh 0'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah tidak boleh 0'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final double total =
        double.tryParse(
          _totalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total harga tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = await auth.getCurrentUserDetails();

      if (user == null) throw Exception('User not found');

      // Use explicit logic to get agent name

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
        if (paidAmount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Masukkan jumlah DP yang valid')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final sale = SaleModel(
        id: '', // Auto-gen
        userId: user.id,
        productId: _selectedProduct!.id,
        details: {
          'product_name': _selectedProduct!.name,
          'product_price': unitPrice,
          'quantity': qty,
          'penulis': _penulisController.text.trim(),
          'judul_naskah': _judulNaskahController.text.trim(),
          'bonus_multiplier': _userMonthlyBonusCount < 5 ? 0 : 1, // Example
          'markup_per_qty': markupPerQty,
          'house_type': 1, // Penerbitan
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
        paidAmount: _paymentStatus == 'LUNAS'
            ? double.parse(
                _totalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
              )
            : double.parse(
                _dpAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
              ),
        createdAt: DateTime.now(),
        transactionProofUrl: _transactionProofUrl,
      );

      // Add requested status for Admin visibility
      sale.details['requested_status'] = _paymentStatus;

      await firestore.addSale(sale);

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: 'Transaksi Baru (Penerbitan)',
        body:
            '${user.name ?? "Marketing"} baru saja submit naskah "${_judulNaskahController.text}". Total: ${AppFormatters.currency(sale.totalPrice)}',
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
            content: Text('Penjualan berhasil disimpan!'),
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
    const color = AppTheme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.post_add_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Input Penerbitan',
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
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: Colors.blueAccent, // Brighter for dark mode
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Login sebagai: $_agentName',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent, // Brighter for dark mode
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
              _buildSectionTitle('Detail Penjualan'),
              const SizedBox(height: 16),

              _buildTextField(
                _penulisController,
                'Nama Penulis',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _judulNaskahController,
                'Judul Naskah Masuk',
                Icons.book_outlined,
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
                    child: _buildTextField(
                      _unitPriceController,
                      'Harga Per Buku',
                      Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      prefixText: 'Rp ',
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => _calculateValues(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      _qtyController,
                      'Jumlah',
                      Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateValues(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _totalPriceController,
                'Total Yang Harus Dibayar',
                Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
                prefixText: 'Rp ',
                // inputFormatters: [CurrencyInputFormatter()], // Calculated field, usually read-only but editable here
                onChanged: (_) {},
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: _inputDecoration(
                  'Status Pembayaran',
                  Icons.payment_outlined,
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
                _buildTextField(
                  _dpAmountController,
                  'Jumlah DP yang Dibayar',
                  Icons.payments_outlined,
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
              GestureDetector(
                onTap: _pickAndUploadProof,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).cardColor, // Replaces Colors.grey[100]
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _transactionProofUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_transactionProofUrl ?? ''),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _transactionProofUrl == null
                      ? _isUploadingProof
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 40,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant, // Colors.grey[600]
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap untuk unggah bukti transaksi',
                                    style: GoogleFonts.outfit(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant, // Colors.grey[600]
                                    ),
                                  ),
                                ],
                              )
                      : null,
                ),
              ),
              if (_transactionProofUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton.icon(
                    onPressed: _pickAndUploadProof,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Ganti Bukti Transaksi'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
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
                          'Submit Penjualan',
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ), // Colors.grey[600]
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
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor:
          Theme.of(context).inputDecorationTheme.fillColor ??
          Theme.of(context).cardColor, // Fallback if theme null
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 16),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label, icon, prefixText: prefixText),
      onChanged: onChanged,
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  Widget _buildProductDropdown(Color color) {
    return ProductPickerField(
      stream: _productsStream,
      selectedProduct: _selectedProduct,
      onChanged: _onProductChanged,
      label: 'Pilih Paket Penerbitan',
      color: color,
    );
  }
}
