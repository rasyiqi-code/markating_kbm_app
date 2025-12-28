import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:provider/provider.dart';

class TopMarketersList extends StatelessWidget {
  final String currentUserId;

  const TopMarketersList({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Marketers',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UserModel>>(
          stream: Provider.of<FirestoreService>(
            context,
            listen: false,
          ).getAllMarketingUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var users = snapshot.data!;
            // Sort by Total Sales Descending
            users.sort(
              (a, b) => b.totalSalesCount.compareTo(a.totalSalesCount),
            );
            // Take top 5
            final topUsers = users.take(5).toList();

            if (topUsers.isEmpty) {
              return const Text('Belum ada data agen.');
            }

            return Column(
              children: topUsers.asMap().entries.map((entry) {
                final index = entry.key;
                final agent = entry.value;
                final isFirst = index == 0;
                final isMe = agent.id == currentUserId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[50] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFirst
                          ? Colors.amber.withValues(alpha: 0.5)
                          : (isMe
                                ? Colors.blue.withValues(alpha: 0.3)
                                : Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.2)),
                      width: isFirst || isMe ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? Colors.amber
                              : (index < 3
                                    ? Colors.grey[800]
                                    : Colors.grey[100]),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.white : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Agent Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name ?? agent.email.split('@')[0],
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${agent.totalSalesCount} Penjualan',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Medal/Icon for Top 3
                      if (index < 3)
                        Icon(
                          Icons.emoji_events_rounded,
                          color: isFirst ? Colors.amber : Colors.grey[400],
                          size: 28,
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
