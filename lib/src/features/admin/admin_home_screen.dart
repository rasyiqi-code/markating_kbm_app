import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_list_screen.dart';

// New Widgets
import 'package:markating_kbm_app/src/features/admin/widgets/admin_pending_claims_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/admin_total_agents_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/admin_top_agents_list.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/admin_recent_transactions_list.dart';

import 'package:provider/provider.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationListScreen(),
                        ),
                      );
                    },
                  ),
                  if (controller.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          controller.unreadCount > 9
                              ? '9+'
                              : controller.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Section
            const Row(
              children: [
                Expanded(child: AdminPendingClaimsCard()),
                SizedBox(width: 16),
                Expanded(child: AdminTotalAgentsCard()),
              ],
            ),
            const SizedBox(height: 32),

            // Top Agents Section
            Text(
              'Agen Terbaik',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const AdminTopAgentsList(),
            const SizedBox(height: 32),

            // Recent Transactions Section
            Text(
              'Transaksi Terkini',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const AdminRecentTransactionsList(),
            const SizedBox(height: 120), // Bottom padding
          ],
        ),
      ),
    );
  }
}
