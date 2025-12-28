import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:provider/provider.dart';

class AdminTopAgentsList extends StatelessWidget {
  const AdminTopAgentsList({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<List<UserModel>>(
      stream: firestore.getAllMarketingUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var users = snapshot.data!;
        // Sort by Total Sales Descending
        users.sort((a, b) => b.totalSalesCount.compareTo(a.totalSalesCount));
        // Take top 3
        final topUsers = users.take(3).toList();

        if (topUsers.isEmpty) {
          return const Text('Belum ada agen nih.');
        }

        return Column(
          children: topUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final isFirst = index == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst
                      ? Colors.amber.withValues(alpha: 0.5)
                      : Theme.of(context).dividerColor,
                  width: isFirst ? 1.5 : 1,
                ),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? Colors.amber
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFirst
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? user.email.split('@')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${user.totalSalesCount} Penjualan',
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
                  Text(
                    NumberFormat.currency(
                      locale: 'en_US',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(user.totalCommissionEarned),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
