import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/transaction_detail_modal.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/transaction_update_dialog.dart';
import 'package:provider/provider.dart';

class TransactionCard extends StatelessWidget {
  final SaleModel sale;

  const TransactionCard({super.key, required this.sale});

  Future<void> _cancelTransaction(BuildContext context, SaleModel sale) async {
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      await firestore.updateSaleStatus(
        sale,
        SaleModel.statusCanceled,
        note: 'Dibatalkan oleh Admin via tombol Batalkan',
        actor: 'Admin',
      );

      final notification = NotificationModel(
        id: '',
        title: 'Transaksi Dibatalkan',
        body:
            'Transaksi #${sale.id.substring(0, 8).toUpperCase()} telah dibatalkan oleh Admin',
        type: NotificationModel.typeWarning,
        recipientId: sale.userId,
        relatedId: sale.id,
        createdAt: DateTime.now(),
      );

      await firestore.sendNotification(notification);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dibatalkan')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => TransactionDetailModal.show(context, sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(sale.createdAt),
                    style: GoogleFonts.outfit(
                      fontSize: 11, // Reduced font size
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                        fontSize: 11, // Reduced font size
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sale.details['product_name'] ?? '-',
                style: GoogleFonts.outfit(
                  fontSize: 15, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sale.details['judul_naskah'] != null)
                Text(
                  'Title: ${sale.details['judul_naskah']}',
                  style: TextStyle(
                    fontSize: 12, // Reduced font size
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Agent: ${sale.details['agent_name'] ?? sale.details['buyer_name'] ?? '-'}',
                style: GoogleFonts.outfit(
                  fontSize: 12, // Reduced font size
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              // Compact Bottom Row: Price + Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currencyFormat.format(sale.totalPrice),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Actions Row (if applicable)
                  if (!isComplete &&
                      sale.paymentStatus != SaleModel.statusCanceled &&
                      sale.paymentStatus != SaleModel.statusProblem)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _cancelTransaction(context, sale),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Batalkan',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              TransactionUpdateDialog.show(context, sale),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32), // Compact height
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Update',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
