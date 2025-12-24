import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart'; // Import AppTheme

class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController for 2 tabs
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Withdrawal Management',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(children: [_RequestsTab(), _HistoryTab()]),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<ClaimModel>>(
      stream: firestoreService.getPendingClaims(),
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
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) {
            return _ClaimCard(claim: claims[index], isHistory: false);
          },
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return StreamBuilder<List<ClaimModel>>(
      stream: firestoreService.getClaimHistory(),
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
                Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No history found',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) {
            return _ClaimCard(claim: claims[index], isHistory: true);
          },
        );
      },
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  final bool isHistory;

  const _ClaimCard({required this.claim, required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final isPulsa = claim.type == ClaimModel.typePulsa;

    // Status config
    Color statusColor = Colors.grey;
    String statusText = claim.status;
    IconData statusIcon = Icons.access_time_rounded;

    if (claim.status == ClaimModel.statusPaid) {
      statusColor = Colors.green;
      statusText = 'BERHASIL';
      statusIcon = Icons.check_circle_rounded;
    } else if (claim.status == ClaimModel.statusRejected) {
      statusColor = Colors.red;
      statusText = 'DITOLAK';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusText = 'MENUNGGU';
    }

    final bankName =
        (isPulsa
            ? (claim.bankDetails['phone'])
            : (claim.bankDetails['bank_name'])) ??
        (claim.bankDetails['info'] ?? '-');

    final accNumber = claim.bankDetails['account_number'];
    final accHolder = claim.bankDetails['account_holder'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header: Type & Date
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPulsa
                        ? Colors.blue.shade50
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPulsa
                            ? Icons.phone_android_rounded
                            : Icons.account_balance_rounded,
                        size: 14,
                        color: isPulsa ? Colors.blue : Colors.purple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPulsa ? 'PULSA' : 'TRANSFER BANK',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPulsa
                              ? Colors.blue.shade700
                              : Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(claim.createdAt),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Body: Amount & Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Amount
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Penarikan',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(claim.amount),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (isHistory) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Right: Target Info
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tujuan Transfer',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildCopyableText(
                        context,
                        bankName,
                        isBold: true,
                        alignRight: true,
                        isCopyable: claim.bankDetails['info'] != null,
                      ),
                      if (accNumber != null)
                        _buildCopyableText(
                          context,
                          accNumber,
                          alignRight: true,
                          isCopyable: true,
                          color: Colors.black87,
                        ),
                      if (accHolder != null)
                        Text(
                          accHolder.toUpperCase(),
                          textAlign: TextAlign.end,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions (Only for Requests)
          if (!isHistory) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAction(
                        context,
                        firestoreService,
                        'Tolak',
                        'Saldo akan dikembalikan ke user. Lanjutkan?',
                        () async {
                          await firestoreService.rejectClaim(claim);

                          // Notify
                          final notification = NotificationModel(
                            id: '',
                            title: 'Permintaan Ditolak',
                            body:
                                'Claim ${claim.type} sebesar ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(claim.amount)} ditolak.',
                            type: NotificationModel.typeWarning,
                            recipientId: claim.userId,
                            relatedId: claim.id,
                            createdAt: DateTime.now(),
                          );
                          await firestoreService.sendNotification(notification);
                        },
                        Colors.red,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAction(
                        context,
                        firestoreService,
                        'Setujui',
                        'Pastikan Anda sudah transfer dana/pulsa. Lanjutkan?',
                        () async {
                          await firestoreService.approveClaim(claim.id);

                          // Notify
                          final notification = NotificationModel(
                            id: '',
                            title: 'Permintaan Disetujui',
                            body:
                                'Claim ${claim.type} sebesar ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(claim.amount)} telah dibayar/dikirim.',
                            type: NotificationModel.typeSuccess,
                            recipientId: claim.userId,
                            relatedId: claim.id,
                            createdAt: DateTime.now(),
                          );
                          await firestoreService.sendNotification(notification);
                        },
                        Colors.green,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCopyableText(
    BuildContext context,
    String text, {
    bool isBold = false,
    bool alignRight = false,
    bool isCopyable = false,
    Color? color,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();

    Widget content = Text(
      text,
      textAlign: alignRight ? TextAlign.end : TextAlign.start,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
        color: color, // Use optional color
        decoration: isCopyable ? TextDecoration.underline : null,
        decorationStyle: TextDecorationStyle.dotted,
      ),
    );

    if (!isCopyable) return content;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $text'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Tooltip(message: 'Tap to copy', child: content),
    );
  }

  void _confirmAction(
    BuildContext context,
    FirestoreService service,
    String action,
    String message,
    Future<void> Function() onConfirm,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Request'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await onConfirm();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$action success'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: Text('Confirm', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
