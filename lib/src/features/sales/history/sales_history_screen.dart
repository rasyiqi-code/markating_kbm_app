import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/transaction_timeline.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:provider/provider.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.getCurrentUserDetails();
    if (mounted && user != null) {
      setState(() => _userId = user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firestore = Provider.of<FirestoreService>(context);
    // Use Activity History Title
    const title = 'Riwayat Aktivitas';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(title),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Penjualan'),
              Tab(text: 'Penarikan'),
            ],
          ),
        ),
        backgroundColor: Colors.grey[50],
        body: TabBarView(
          children: [
            // Tab 1: Sales (Existing Logic)
            StreamBuilder<List<SaleModel>>(
              stream: firestore.getUserSales(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sales = snapshot.data ?? [];

                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada penjualan',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return _buildSaleCard(sale);
                  },
                );
              },
            ),

            // Tab 2: Claims (New Logic)
            StreamBuilder<List<ClaimModel>>(
              stream: firestore.getUserClaims(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final claims = snapshot.data ?? [];

                if (claims.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat penarikan',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: claims.length,
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    return _buildClaimCard(claim);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimCard(ClaimModel claim) {
    // Used AppFormatters instead

    Color statusColor;
    String statusText;

    switch (claim.status) {
      case ClaimModel.statusPaid:
        statusColor = Colors.green;
        statusText = 'BERHASIL';
        break;
      case ClaimModel.statusRejected:
        statusColor = Colors.red;
        statusText = 'DITOLAK';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'DIPROSES';
    }

    final isPulsa = claim.type == ClaimModel.typePulsa;
    final isMarkup = claim.type == 'markup';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPulsa
                    ? Colors.orange.shade50
                    : isMarkup
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPulsa
                    ? Icons.phone_android_rounded
                    : isMarkup
                    ? Icons.trending_up_rounded
                    : Icons.account_balance_rounded,
                color: isPulsa
                    ? Colors.orange
                    : isMarkup
                    ? Colors.green
                    : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPulsa
                        ? 'Klaim Pulsa'
                        : isMarkup
                        ? 'Penarikan Markup'
                        : 'Penarikan Komisi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(claim.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currency(claim.amount),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    final isLunas = sale.paymentStatus.toUpperCase() == 'LUNAS';
    final isComplete = sale.paymentStatus.toUpperCase() == 'COMPLETE';
    // Used AppFormatters instead
    final details = sale.details;
    final houseName = details['house_type'] == 1
        ? 'Penerbitan Buku'
        : 'KBM Creator';

    // Attempt to extract product name from details or fallback
    final productName =
        details['product_name'] ??
        details['book_title'] ??
        'Product #${sale.productId.substring(0, 4)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showDetailModal(context, sale);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLunas ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLunas ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      isLunas
                          ? 'PAID'
                          : sale.paymentStatus, // Use actual status (DP/PENDING)
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLunas ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(sale.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                productName,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                houseName,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Harga',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    AppFormatters.currency(sale.totalPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isComplete ? 'Masuk Saldo' : 'Estimasi Potensi Bonus',
                        style: TextStyle(
                          fontSize: 12,
                          color: isComplete
                              ? Colors.grey[600]
                              : Colors.orange[800],
                          fontWeight: isComplete
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(sale.bonusAmount),
                        style: GoogleFonts.outfit(
                          color: isComplete
                              ? AppTheme.primaryColor
                              : Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isComplete ? null : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              if ((sale.totalMarkup ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keuntungan Markup',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                    Text(
                      AppFormatters.currency(sale.totalMarkup ?? 0),
                      style: GoogleFonts.outfit(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              if (sale.paymentStatus == 'DP' && sale.paidAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DP Terbayar: ${AppFormatters.currency(sale.paidAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPelunasanDialog(context, sale),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Lunasi Sekarang & Upload Bukti'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPelunasanDialog(
    BuildContext context,
    SaleModel sale,
  ) async {
    final remainingAmount = sale.totalPrice - sale.paidAmount;
    // Used AppFormatters instead

    await showDialog(
      context: context,
      builder: (dialogContext) => _PelunasanDialog(
        remainingAmount: remainingAmount,
        // formatter removed
        onConfirm: (file) async {
          Navigator.pop(dialogContext);
          await _processPelunasan(sale, file, remainingAmount);
        },
      ),
    );
  }

  Future<void> _processPelunasan(
    SaleModel sale,
    XFile file,
    double remainingAmount,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // 1. Upload Proof
      // We need StorageService instance
      // But StorageService is not in provider usually? It is in core/services.
      // Usually we use Provider.of<StorageService>.
      // Let's assume it is provided or we allow creating instance.
      // Wait, in SalesEntryR1Screen it was imported.
      // I'll check how it's used.
      // Assuming Provider:
      // Assuming Provider:
      final storage = Provider.of<StorageService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      // Upload
      // storage.uploadImage usually takes File? Or XFile?
      // If web, bytes. If IO, File.
      // Since specific windows environment:
      final bytes = await file.readAsBytes();
      final filename =
          'pelunasan_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final url = await storage.uploadBytes(
        bytes,
        filename,
        'transaction_proofs',
      );

      if (!mounted) return;

      // 2. Update Sale Status
      await firestore.updateSaleStatus(
        sale,
        SaleModel.statusLunas, // Mark as LUNAS (Pending Admin Review)
        note: 'Pelunasan by Marketing via App',
        actor: 'Marketing',
        extraData: {
          'transaction_proof_url':
              url, // Update proof URL (Logic needed in Backend or just rely on this overwrite?)
          // Wait, 'transaction_proof_url' is in SaleModel.
          // FirestoreService updateSaleStatus merges extraData?
          // I implemented `...?extraData` in `updateSaleStatus` specifically for this!
          'paid_amount': sale.totalPrice, // Full Payment
        },
      );

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: 'Bukti Pelunasan Baru',
        body:
            'Marketing upload bukti pelunasan #${sale.id.substring(0, 8).toUpperCase()}',
        type: NotificationModel.typeInfo,
        recipientId: 'role:admin',
        relatedId: sale.id,

        createdAt: DateTime.now(),
      );
      await firestore.sendNotification(notification);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Pelunasan berhasil dikirim! Menunggu verifikasi admin.',
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDetailModal(BuildContext context, SaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Detail Transaksi',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDetailRow(
                      'ID Transaksi',
                      sale.id.substring(0, 8).toUpperCase(),
                    ),
                    _buildDetailRow(
                      'Tanggal',
                      DateFormat('dd MMM yyyy, HH:mm').format(sale.createdAt),
                    ),
                    _buildDetailRow('Status', sale.paymentStatus),
                    _buildDetailRow(
                      'Total Transaksi',
                      AppFormatters.currency(sale.totalPrice),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Rincian Item',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Paket',
                      sale.details['product_name'] ?? '-',
                    ),
                    if (sale.details['judul_naskah'] != null)
                      _buildDetailRow(
                        'Judul Naskah',
                        sale.details['judul_naskah'],
                      ),
                    if (sale.details['judul_layout'] != null)
                      _buildDetailRow(
                        'Judul Layout',
                        sale.details['judul_layout'],
                      ),
                    if (sale.details['nama_penulis'] != null)
                      _buildDetailRow(
                        'Nama Penulis',
                        sale.details['nama_penulis'],
                      ),
                    if (sale.details['nama_mitra'] != null)
                      _buildDetailRow('Nama Mitra', sale.details['nama_mitra']),
                    if (sale.details['ukuran_naskah'] != null)
                      _buildDetailRow('Ukuran', sale.details['ukuran_naskah']),
                    if (sale.details['jumlah_halaman'] != null)
                      _buildDetailRow(
                        'Jumlah Halaman',
                        sale.details['jumlah_halaman'],
                      ),

                    const Divider(height: 32),
                    if (sale.transactionProofUrl != null) ...[
                      const Text(
                        'Bukti Transaksi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          sale.transactionProofUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Text('Gagal memuat gambar'),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 32),
                    ],
                    const Text(
                      'Info Agen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Nama Agen',
                      sale.details['buyer_name'] ?? '-',
                    ),
                    const Divider(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (sale.paymentStatus == 'COMPLETE')
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (sale.paymentStatus == 'COMPLETE')
                                ? 'Masuk Saldo'
                                : 'Potensi Bonus',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppFormatters.currency(sale.bonusAmount),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: (sale.paymentStatus == 'COMPLETE')
                                  ? AppTheme.primaryColor
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TransactionTimeline(history: sale.history),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PelunasanDialog extends StatefulWidget {
  final double remainingAmount;
  // final NumberFormat formatter;
  final Function(XFile) onConfirm;

  const _PelunasanDialog({
    required this.remainingAmount,
    // required this.formatter,
    required this.onConfirm,
  });

  @override
  State<_PelunasanDialog> createState() => _PelunasanDialogState();
}

class _PelunasanDialogState extends State<_PelunasanDialog> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pelunasan Transaksi'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sisa Pembayaran: ${AppFormatters.currency(widget.remainingAmount)}',
          ),
          const SizedBox(height: 16),
          if (_imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Image.network(
                      _imageFile!.path,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_imageFile!.path),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _pickImage, child: const Text('Ganti Foto')),
          ] else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Bukti Transfer'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _imageFile != null
              ? () => widget.onConfirm(_imageFile!)
              : null,
          child: const Text('Kirim Pelunasan'),
        ),
      ],
    );
  }
}
