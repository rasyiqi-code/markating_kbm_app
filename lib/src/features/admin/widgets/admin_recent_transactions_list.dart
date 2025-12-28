import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/transaction_detail_modal.dart';
import 'package:provider/provider.dart';

class AdminRecentTransactionsList extends StatelessWidget {
  const AdminRecentTransactionsList({super.key});

  void _showSaleDetailDialog(BuildContext context, SaleModel sale) {
    TransactionDetailModal.show(context, sale);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder(
      stream: firestore.getSales(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = snapshot.data!;
        if (sales.isEmpty) {
          return const Text('Belum ada transaksi baru.');
        }

        return Column(
          children: sales.map((sale) {
            final isLunas = sale.paymentStatus == 'LUNAS';
            return InkWell(
              onTap: () => _showSaleDetailDialog(context, sale),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLunas ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: isLunas ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.details['product_name'] ?? 'Product',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            sale.details['buyer_name'] ?? 'Buyer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sale.paymentStatus == SaleModel.statusComplete
                            ? Colors.purple[50]
                            : (isLunas ? Colors.green[50] : Colors.orange[50]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sale.paymentStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: sale.paymentStatus == SaleModel.statusComplete
                              ? Colors.purple
                              : (isLunas ? Colors.green : Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
