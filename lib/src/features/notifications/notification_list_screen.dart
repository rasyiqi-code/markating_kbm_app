import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';

import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/sale_detail_dialog.dart';
import 'package:provider/provider.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NotificationController>(context);
    final notifications = controller.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                // Potential future improvement: Mark all as read method in controller
                for (var n in notifications) {
                  if (!n.isRead) {
                    controller.markAsRead(n.id);
                  }
                }
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationTile(
                  context,
                  notification,
                  controller,
                );
              },
            ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
  ) {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case NotificationModel.typeSuccess:
        iconColor = Colors.green;
        iconData = Icons.check_circle_outline;
        break;
      case NotificationModel.typeWarning:
        iconColor = Colors.orange;
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationModel.typeError:
        iconColor = Colors.red;
        iconData = Icons.error_outline;
        break;
      default:
        iconColor = Colors.blue;
        iconData = Icons.info_outline;
    }

    return Container(
      color: notification.isRead
          ? Colors.transparent
          : Colors.blue.withValues(alpha: 0.05),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.outfit(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(context, notification, controller),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationController controller,
  ) async {
    // 1. Mark as read
    if (!notification.isRead) {
      controller.markAsRead(notification.id);
    }

    if (notification.relatedId == null) return;

    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Determine Type based on Title/Body keywords
      final title = notification.title.toLowerCase();

      if (title.contains('transaksi') ||
          title.contains('penjualan') ||
          title.contains('bukti')) {
        // Fetch Sale
        final sale = await firestore.getSale(notification.relatedId!);

        if (context.mounted) Navigator.pop(context); // Close loading

        if (sale != null && context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SaleDetailDialog(sale: sale),
          );
        } else if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Data transaksi tidak ditemukan')),
          );
        }
      } else if (title.contains('withdraw') ||
          title.contains('pulsa') ||
          title.contains('claim') ||
          title.contains('permintaan')) {
        // Fetch Claim (Just check if exists for now, maybe show simple dialog)
        final claim = await firestore.getClaim(notification.relatedId!);

        if (context.mounted) Navigator.pop(context); // Close loading

        if (claim != null && context.mounted) {
          // For now, just show a simple dialog since we didn't extract ClaimDetail
          // Or just SnackBar saying "See Withdrawal History"
          // Ideally navigate to WithdrawalScreen history tab if possible
          // But showing a dialog is consistent.
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Detail Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${claim.status}'),
                  Text('Amount: Rp ${claim.amount}'),
                  Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(claim.createdAt)}',
                  ),
                  if (claim.status == 'REJECTED') Text('Refunded to balance.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Data claim tidak ditemukan')),
          );
        }
      } else {
        if (context.mounted) Navigator.pop(context); // Close loading
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}
