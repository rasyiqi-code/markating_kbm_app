import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart'; // Added
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/sales/widgets/transaction_timeline.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
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
            Row(
              children: [
                Expanded(child: _buildPendingClaimsCard(firestore)),
                const SizedBox(width: 16),
                Expanded(child: _buildTotalAgentsCard(firestore)),
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
            _buildTopAgentsList(firestore),
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
            _buildRecentTransactions(firestore),
            const SizedBox(height: 120), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildPendingClaimsCard(FirestoreService firestore) {
    return StreamBuilder<List<ClaimModel>>(
      stream: firestore.getPendingClaims(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: count > 0
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mark_email_unread_rounded,
                color: count > 0 ? Colors.red : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Permintaan Masuk',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalAgentsCard(FirestoreService firestore) {
    return StreamBuilder<List<UserModel>>(
      stream: firestore.getAllMarketingUsers(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Total Agen',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAgentsList(FirestoreService firestore) {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst
                      ? Colors.amber.withValues(alpha: 0.5)
                      : Colors.grey[200]!,
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
                      color: isFirst ? Colors.amber : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFirst ? Colors.white : Colors.grey[600],
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
                            color: Colors.grey[600],
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

  Widget _buildRecentTransactions(FirestoreService firestore) {
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
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
                              color: Colors.grey[600],
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

  void _showSaleDetailDialog(BuildContext context, SaleModel sale) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                    _buildDetailRow(
                      'Tanggal',
                      dateFormat.format(sale.createdAt),
                    ),
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
