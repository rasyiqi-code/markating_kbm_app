import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:provider/provider.dart';

class TransactionUpdateDialog extends StatefulWidget {
  final SaleModel sale;

  const TransactionUpdateDialog({super.key, required this.sale});

  static Future<void> show(BuildContext context, SaleModel sale) {
    return showDialog(
      context: context,
      builder: (context) => TransactionUpdateDialog(sale: sale),
    );
  }

  @override
  State<TransactionUpdateDialog> createState() =>
      _TransactionUpdateDialogState();
}

class _TransactionUpdateDialogState extends State<TransactionUpdateDialog> {
  final TextEditingController _noteController = TextEditingController();
  String? _currentProofUrl;
  bool _hasProof = false;

  @override
  void initState() {
    super.initState();
    _currentProofUrl = widget.sale.transactionProofUrl;
    _hasProof = _currentProofUrl != null;

    if (widget.sale.paymentStatus == SaleModel.statusDp && _hasProof) {
      // Check if proof was uploaded DURING the DP phase
      final hasUploadDuringDp = widget.sale.history.any(
        (h) =>
            h.status == SaleModel.statusDp && h.note == 'Admin uploaded proof',
      );
      _hasProof = hasUploadDuringDp;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  Future<void> _updateStatus(
    SaleModel sale,
    String newStatus, {
    String? note,
  }) async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final Map<String, dynamic> extraData = {};
      if (newStatus == SaleModel.statusLunas ||
          newStatus == SaleModel.statusComplete) {
        extraData['paid_amount'] = sale.totalPrice;
      }

      await firestore.updateSaleStatus(
        sale,
        newStatus,
        note: note,
        actor: 'Admin',
        extraData: extraData,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Perbarui Transaksi'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Proof Section
          if (_hasProof && _currentProofUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _currentProofUrl!,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final newUrl = await _uploadProofForSale(
                  widget.sale,
                  oldUrl: _currentProofUrl,
                );
                if (newUrl != null) {
                  setState(() {
                    _currentProofUrl = newUrl;
                    _hasProof = true;
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
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                  Text(
                    'Wajib upload bukti sebelum update ke DP/LUNAS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final newUrl = await _uploadProofForSale(
                  widget.sale,
                  oldUrl: _currentProofUrl,
                );
                if (newUrl != null) {
                  setState(() {
                    _currentProofUrl = newUrl;
                    _hasProof = true;
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
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Catatan / Alasan (Opsional)',
              hintText: 'Contoh: Pembayaran oke...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          if (widget.sale.paymentStatus == SaleModel.statusPending)
            ListTile(
              title: const Text('Tandai sebagai DP'),
              subtitle: !_hasProof
                  ? const Text(
                      'Wajib bukti foto!',
                      style: TextStyle(color: Colors.red),
                    )
                  : null,
              enabled: _hasProof,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(
                  widget.sale,
                  SaleModel.statusDp,
                  note: _noteController.text,
                );
              },
            ),
          if (widget.sale.paymentStatus == SaleModel.statusPending ||
              widget.sale.paymentStatus == SaleModel.statusDp) ...[
            const Divider(),
            ListTile(
              title: const Text('Tandai LUNAS'),
              subtitle: Text(
                !_hasProof
                    ? 'Wajib bukti foto!'
                    : 'Status LUNAS belum mencairkan bonus. Bonus cair saat status COMPLETE.',
                style: TextStyle(
                  color: !_hasProof ? Colors.red : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.check_circle,
                color: _hasProof ? Colors.green : Colors.grey,
              ),
              enabled: _hasProof,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(
                  widget.sale,
                  SaleModel.statusLunas,
                  note: _noteController.text,
                );
              },
            ),
          ],
          if (widget.sale.paymentStatus == SaleModel.statusLunas) ...[
            const Divider(),
            ListTile(
              title: const Text('Tandai SELESAI (COMPLETE)'),
              subtitle: const Text('Pesanan diterima/selesai.'),
              trailing: const Icon(Icons.done_all, color: Colors.purple),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(
                  widget.sale,
                  SaleModel.statusComplete,
                  note: _noteController.text,
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            title: const Text('Tandai BERMASALAH'),
            subtitle: const Text('Ada masalah pembayaran/pesanan.'),
            trailing: const Icon(Icons.report_problem, color: Colors.red),
            textColor: Colors.red,
            onTap: () {
              if (_noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wajib isi catatan masalahnya ya'),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateStatus(
                widget.sale,
                SaleModel.statusProblem,
                note: _noteController.text,
              );
            },
          ),
        ],
      ),
    );
  }
}
