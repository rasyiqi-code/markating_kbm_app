import 'package:image_picker/image_picker.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';

class AdminTransactionsScreen extends StatefulWidget {
  final int houseType; // 1 for Penerbitan, 2 for Creator

  const AdminTransactionsScreen({super.key, required this.houseType});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  String? _selectedStatus; // null = All
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final title = widget.houseType == 1
        ? 'Penerbitan (Buku)'
        : 'KBM Creator (Mitra)';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: widget.houseType == 1
            ? AppTheme.primaryColor
            : Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _selectedStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Tampilkan Semua')),
              const PopupMenuItem(
                value: SaleModel.statusPending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: SaleModel.statusDp,
                child: Text('DP Only'),
              ),
              const PopupMenuItem(
                value: SaleModel.statusLunas,
                child: Text('Lunas'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<SaleModel>>(
        stream: Provider.of<FirestoreService>(
          context,
        ).getSales(houseType: widget.houseType, status: _selectedStatus),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada transaksi nih',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final sales = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildTransactionCard(sale);
            },
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(SaleModel sale) {
    final isLunas = sale.paymentStatus == SaleModel.statusLunas;
    final isComplete = sale.paymentStatus == SaleModel.statusComplete;
    final isPending = sale.paymentStatus == SaleModel.statusPending;

    Color statusColor;
    if (isComplete) {
      statusColor = Colors.purple;
    } else if (isLunas) {
      statusColor = Colors.green;
    } else if (isPending) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(sale.createdAt),
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    sale.paymentStatus,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sale.details['product_name'] ?? '-',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sale.details['judul_naskah'] != null)
              Text(
                'Title: ${sale.details['judul_naskah']}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            if (sale.details['judul_layout'] != null)
              Text(
                'Title: ${sale.details['judul_layout']}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),

            const SizedBox(height: 8),
            if (sale.details['nama_penulis'] != null)
              Text(
                'Author: ${sale.details['nama_penulis']}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            if (sale.details['nama_mitra'] != null)
              Text(
                'Partner: ${sale.details['nama_mitra']}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),

            const SizedBox(height: 4),
            Text(
              'Agent: ${sale.details['buyer_name'] ?? '-'}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currencyFormat.format(sale.totalPrice),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (sale.paymentStatus == SaleModel.statusComplete)
                            ? 'Sudah Masuk Saldo'
                            : 'Potensi Bonus',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color:
                              (sale.paymentStatus == SaleModel.statusComplete)
                              ? Colors.grey
                              : Colors.orange[800],
                          fontWeight:
                              (sale.paymentStatus == SaleModel.statusComplete)
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        currencyFormat.format(
                          (sale.paymentStatus == SaleModel.statusComplete)
                              ? sale.commissionAmount
                              : sale.bonusAmount, // Show potential bonus
                        ),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color:
                              (sale.paymentStatus == SaleModel.statusComplete)
                              ? Colors.green
                              : Colors.orange[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sale.paymentStatus == 'DP' && sale.paidAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sudah Bayar (DP)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          currencyFormat.format(sale.paidAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sisa Tagihan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[900],
                          ),
                        ),
                        Text(
                          currencyFormat.format(
                            sale.totalPrice - sale.paidAmount,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (!isComplete) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        _updateStatus(sale, SaleModel.statusCanceled),
                    child: const Text(
                      'Batalkan',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showUpdateDialog(sale),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProofForSale(SaleModel sale, {String? oldUrl}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      try {
        if (!mounted) return null;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengunggah bukti...')));

        final storage = Provider.of<StorageService>(context, listen: false);
        final bytes = await picked.readAsBytes();
        final filename =
            'proof_admin_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final url = await storage.uploadBytes(bytes, filename, 'transactions');

        if (!mounted) return null;

        // Update Sale Document Immediately
        await Provider.of<FirestoreService>(
          context,
          listen: false,
        ).updateSaleStatus(
          sale,
          sale.paymentStatus, // Keep status same
          note: 'Admin uploaded proof',
          actor: 'Admin',
          extraData: {'transaction_proof_url': url},
        );

        // Delete old file if exists
        if (oldUrl != null && oldUrl != url) {
          storage.deleteFileByUrl(oldUrl);
        }

        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti berhasil diunggah!')),
        );
        // Navigator.pop(context); // Don't close dialog
        return url;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
        }
        return null;
      }
    }
    return null;
  }

  void _showUpdateDialog(SaleModel sale) {
    final noteController = TextEditingController();

    // Logic to ensure fresh proof for LUNAS (Status DP -> LUNAS)
    String? currentProofUrl = sale.transactionProofUrl;
    bool hasProof = currentProofUrl != null;

    if (sale.paymentStatus == SaleModel.statusDp && hasProof) {
      // Check if proof was uploaded DURING the DP phase
      final hasUploadDuringDp = sale.history.any(
        (h) =>
            h.status == SaleModel.statusDp && h.note == 'Admin uploaded proof',
      );
      hasProof = hasUploadDuringDp;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Perbarui Transaksi'),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Proof Section
                  if (hasProof && currentProofUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        currentProofUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final newUrl = await _uploadProofForSale(
                          sale,
                          oldUrl: currentProofUrl,
                        );
                        if (newUrl != null) {
                          setStateDialog(() {
                            currentProofUrl = newUrl;
                            hasProof = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Ubah Bukti Transaksi'),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bukti Pembayaran Belum Ada',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Wajib upload bukti sebelum update ke DP/LUNAS.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newUrl = await _uploadProofForSale(
                          sale,
                          oldUrl: currentProofUrl,
                        );
                        if (newUrl != null) {
                          setStateDialog(() {
                            currentProofUrl = newUrl;
                            hasProof = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Bukti Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  const Divider(height: 32),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Alasan (Opsional)',
                      hintText: 'Contoh: Pembayaran oke...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (sale.paymentStatus == SaleModel.statusPending)
                    ListTile(
                      title: const Text('Tandai sebagai DP'),
                      subtitle: !hasProof
                          ? const Text(
                              'Wajib bukti foto!',
                              style: TextStyle(color: Colors.red),
                            )
                          : null,
                      enabled: hasProof,
                      onTap: () {
                        Navigator.pop(context);
                        _updateStatus(
                          sale,
                          SaleModel.statusDp,
                          note: noteController.text,
                        );
                      },
                    ),
                  if (sale.paymentStatus == SaleModel.statusPending ||
                      sale.paymentStatus == SaleModel.statusDp) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Tandai LUNAS'),
                      subtitle: Text(
                        !hasProof
                            ? 'Wajib bukti foto!'
                            : 'Ini akan mencairkan bonus ke agen lokal.',
                        style: TextStyle(
                          color: !hasProof ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.check_circle,
                        color: hasProof ? Colors.green : Colors.grey,
                      ),
                      enabled: hasProof,
                      onTap: () {
                        Navigator.pop(context);
                        _updateStatus(
                          sale,
                          SaleModel.statusLunas,
                          note: noteController.text,
                        );
                      },
                    ),
                  ],
                  if (sale.paymentStatus == SaleModel.statusLunas) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Tandai SELESAI (COMPLETE)'),
                      subtitle: const Text('Pesanan diterima/selesai.'),
                      trailing: const Icon(
                        Icons.done_all,
                        color: Colors.purple,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _updateStatus(
                          sale,
                          SaleModel.statusComplete,
                          note: noteController.text,
                        );
                      },
                    ),
                  ],
                  const Divider(),
                  ListTile(
                    title: const Text('Tandai BERMASALAH'),
                    subtitle: const Text('Ada masalah pembayaran/pesanan.'),
                    trailing: const Icon(
                      Icons.report_problem,
                      color: Colors.red,
                    ),
                    textColor: Colors.red,
                    onTap: () {
                      if (noteController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wajib isi catatan masalahnya ya'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _updateStatus(
                        sale,
                        SaleModel.statusProblem,
                        note: noteController.text,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateStatus(
    SaleModel sale,
    String newStatus, {
    String? note,
  }) async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      await firestore.updateSaleStatus(
        sale,
        newStatus,
        note: note,
        actor: 'Admin',
      );

      // Trigger Notification
      final notification = NotificationModel(
        id: '',
        title: 'Update Status Transaksi',
        body:
            'Status transaksi #${sale.id.substring(0, 8).toUpperCase()} berubah menjadi $newStatus',
        type: newStatus == SaleModel.statusProblem
            ? NotificationModel.typeWarning
            : NotificationModel.typeSuccess,
        recipientId: sale.userId,
        relatedId: sale.id,
        createdAt: DateTime.now(),
      );

      await firestore.sendNotification(notification);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status berhasil diubah jadi $newStatus')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
