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

class SalesEntryR2Screen extends StatefulWidget {
  const SalesEntryR2Screen({super.key});

  @override
  State<SalesEntryR2Screen> createState() => _SalesEntryR2ScreenState();
}

class _SalesEntryR2ScreenState extends State<SalesEntryR2Screen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingProof = false;
  String? _transactionProofUrl;
  String _agentName = '';

  // Common Fields
  ProductModel? _selectedProduct;
  final _unitPriceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _totalPriceController = TextEditingController();
  final _dpAmountController = TextEditingController();

  String _paymentStatus = 'DP';

  // Calculated values
  double _commissionAmount = 0;
  double _pulsaBonusAmount = 0;

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
    final user = await auth.getCurrentUserDetails();
    if (mounted && user != null) {
      setState(() {
        _agentName = (user.name != null && user.name!.isNotEmpty)
            ? user.name!
            : user.email.split('@').first;
      });
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

    // R2 Pulsa Bonus
    if (_settings!.enableR2PulsaBonus &&
        total >= _settings!.minSaleForPulsaR2) {
      _pulsaBonusAmount = _settings!.pulsaBonusAmountR2;
    } else {
      _pulsaBonusAmount = 0;
    }
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
          ).showSnackBar(SnackBar(content: Text('Gagal mengunggah: $e')));
        }
      }
    }
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

      final agentName = (user.name != null && user.name!.isNotEmpty)
          ? user.name!
          : user.email.split('@').first;

      // Construct Details Map
      final details = <String, dynamic>{
        'house_type': 2, // Explicit R2
        'product_name': _selectedProduct?.name ?? 'Unknown Product',
        'buyer_name': agentName,
        'nama_mitra': _mitraController.text,
        'judul_layout': _judulLayoutController.text,
        'ukuran_naskah': _ukuranController.text,
        'jumlah_halaman': _halamanController.text,
        'qty': int.tryParse(_qtyController.text) ?? 1,
      };

      final total =
          double.tryParse(
            _totalPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      // Determine Paid Amount
      double paidAmount = 0;
      if (_paymentStatus == 'LUNAS') {
        paidAmount = total;
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
        details: details,
        totalPrice: total,
        paymentStatus: _paymentStatus,
        bonusAmount: _commissionAmount + _pulsaBonusAmount,
        commissionAmount: _commissionAmount,
        pulsaBonusAmount: _pulsaBonusAmount,
        paidAmount: paidAmount,
        createdAt: DateTime.now(),
        transactionProofUrl: _transactionProofUrl,
      );

      await firestore.addSale(sale);

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: 'Transaksi Baru (KBM Kreator)',
        body:
            '${user.name ?? "Marketing"} baru saja input transaksi sebesar ${AppFormatters.currency(total)}',
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
                'Data penjualan saved. Total: ${AppFormatters.currency(total)}',
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
                            color: Colors.purple[800],
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

              _buildTextField(
                _mitraController,
                'Nama Penerbit Kampus/Swasta',
                Icons.business_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _judulLayoutController,
                'Judul Naskah Layout / Desain Cover',
                Icons.design_services_outlined,
              ),
              const SizedBox(height: 16),
              // Logic: Hide Ukuran & Jml Halaman if product is Cover Jasa
              if (_selectedProduct != null &&
                  !_selectedProduct!.name.toLowerCase().contains('cover'))
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _ukuranController,
                        'Ukuran (Naskah/Cetak)',
                        Icons.aspect_ratio_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        _halamanController,
                        'Jml Halaman',
                        Icons.description_outlined,
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
                    flex: 2,
                    child: _buildTextField(
                      _unitPriceController,
                      'Harga Satuan',
                      Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      prefixText: 'Rp ',
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => _calculateValues(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      _qtyController,
                      'Jumlah (Judul/Ex)',
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
                // inputFormatters: [CurrencyInputFormatter()],
                onChanged: (_) {},
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16),
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
                            color: Colors.green[800],
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
                    color: Colors.grey[100],
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
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap untuk unggah bukti transaksi',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[600],
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
                      foregroundColor: AppTheme.secondaryColor,
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
      prefixIcon: Icon(icon, color: Colors.grey[600]),
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
          Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[50],
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
      validator: (v) => v!.isEmpty ? 'Wajib diisi ya' : null,
    );
  }

  Widget _buildProductDropdown(Color color) {
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;

        return DropdownButtonFormField<ProductModel>(
          initialValue: _selectedProduct,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration:
              _inputDecoration(
                'Pilih Layanan',
                Icons.shopping_bag_outlined,
              ).copyWith(
                fillColor: color.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.05,
                ),
              ),
          items: products.map((product) {
            return DropdownMenuItem(
              value: product,
              child: Text(product.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _onProductChanged,
          isExpanded: true,
        );
      },
    );
  }
}
