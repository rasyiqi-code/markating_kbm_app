import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/transaction_timeline.dart';

class SaleDetailDialog extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detail Transaksi',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sale.paymentStatus == SaleModel.statusComplete
                      ? Colors.purple[50]
                      : (sale.paymentStatus == 'LUNAS'
                            ? Colors.green[50]
                            : Colors.orange[50]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sale.paymentStatus == SaleModel.statusComplete
                        ? Colors.purple
                        : (sale.paymentStatus == 'LUNAS'
                              ? Colors.green
                              : Colors.orange),
                  ),
                ),
                child: Text(
                  sale.paymentStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sale.paymentStatus == SaleModel.statusComplete
                        ? Colors.purple
                        : (sale.paymentStatus == 'LUNAS'
                              ? Colors.green
                              : Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Tanggal', dateFormat.format(sale.createdAt)),
                  _buildDetailRow(
                    'Produk',
                    sale.details['product_name'] ?? 'Unknown Product',
                  ),
                  if (sale.details['judul_naskah'] != null)
                    _buildDetailRow('Naskah', sale.details['judul_naskah']),
                  _buildDetailRow(
                    'Nama Pembeli',
                    sale.details['buyer_name'] ?? '-',
                  ),
                  _buildDetailRow(
                    'No. Telepon',
                    sale.details['buyer_phone'] ?? '-',
                  ),
                  if (sale.transactionProofUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Bukti Transaksi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              fit: StackFit.loose,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: Image.network(
                                      sale.transactionProofUrl!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          image: DecorationImage(
                            image: NetworkImage(sale.transactionProofUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Rincian Keuangan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Total Harga',
                    currencyFormat.format(sale.totalPrice),
                  ),
                  _buildDetailRow(
                    'Jumlah Dibayar',
                    currencyFormat.format(sale.paidAmount),
                  ),
                  _buildDetailRow(
                    (sale.paymentStatus == SaleModel.statusComplete)
                        ? 'Komisi (Masuk Saldo)'
                        : 'Potensi Komisi',
                    currencyFormat.format(sale.commissionAmount),
                  ),
                  _buildDetailRow(
                    (sale.paymentStatus == SaleModel.statusComplete)
                        ? 'Bonus Pulsa (Masuk Saldo)'
                        : 'Potensi Bonus Pulsa',
                    currencyFormat.format(sale.pulsaBonusAmount),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Agen Lokal (Mitra)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Agent ID', sale.userId),
                  const SizedBox(height: 32),
                  TransactionTimeline(history: sale.history),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
