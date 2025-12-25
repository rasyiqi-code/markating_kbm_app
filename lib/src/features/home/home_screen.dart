import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/home/widgets/dashboard_stats.dart';
import 'package:markating_kbm_app/src/features/home/widgets/wallet_card.dart';
import 'package:markating_kbm_app/src/features/sales/history/sales_history_screen.dart';
import 'package:markating_kbm_app/src/features/wallet/withdrawal_request_screen.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';
import 'package:markating_kbm_app/src/features/home/widgets/markup_balance_card.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_list_screen.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart'; // Added
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentUserDetails();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Switch to StreamBuilder to listen to Real-Time Balance Updates
    return StreamBuilder<UserModel>(
      stream: Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getUserStream(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _currentUser = snapshot.data; // Update local user with fresh data
        }

        final user = _currentUser!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name ?? (user.email).split('@')[0],
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      // Notification Bell
                      Consumer<NotificationController>(
                        builder: (context, controller, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                              color: Theme.of(context).cardColor,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationListScreen(),
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
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        controller.unreadCount > 9
                                            ? '9+'
                                            : controller.unreadCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                          color: Theme.of(context).cardColor,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            Provider.of<AuthService>(
                              context,
                              listen: false,
                            ).signOut();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Main Stats (Wallet)
              WalletCard(
                user: user,
                onClaimTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalRequestScreen(
                        user: user,
                        allowedType: 'commission',
                      ),
                    ),
                  );
                },
                onClaimPulsaTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalRequestScreen(
                        user: user,
                        allowedType: 'pulsa',
                      ),
                    ),
                  );
                },
              ),

              // 3. Markup Balance Card (NEW)
              MarkupBalanceCard(
                user: user,
                onWithdrawTap: () {
                  // Reuse withdrawal screen but for markup
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalRequestScreen(
                        user: user,
                        allowedType: 'markup',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4. Dashboard Stats (Sales Count, Total Rewards)
              DashboardStats(userId: user.id),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // 1.6 Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktifitas Terkini',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SalesHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Recent Activity List (From Sales)
              StreamBuilder<List<SaleModel>>(
                stream: Provider.of<FirestoreService>(
                  context,
                  listen: false,
                ).getUserSales(user.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sales = snapshot.data!;
                  if (sales.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi terbaru.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  // Take top 3
                  final recentSales = sales.take(3).toList();

                  return Column(
                    children: recentSales.map((sale) {
                      final isComplete =
                          sale.paymentStatus == SaleModel.statusComplete;
                      final isLunas =
                          sale.paymentStatus == SaleModel.statusLunas;
                      final isProblem =
                          sale.paymentStatus == SaleModel.statusProblem;

                      Color statusColor;
                      IconData statusIcon;

                      if (isComplete) {
                        statusColor = Colors.blue;
                        statusIcon = Icons.check_circle;
                      } else if (isLunas) {
                        statusColor = Colors.green;
                        statusIcon = Icons.verified;
                      } else if (isProblem) {
                        statusColor = Colors.red;
                        statusIcon = Icons.warning_amber_rounded;
                      } else {
                        statusColor = Colors.orange;
                        statusIcon = Icons.access_time_filled;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.1),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.details['product_name'] ?? 'Produk',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppFormatters.currency(sale.totalPrice)} • ${sale.paymentStatus}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTimeAgo(sale.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 2. Section Title
              Text(
                'Top Marketers',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Leaderboard Section (Top Marketers)
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
                      final isMe = agent.id == user.id;

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
                                  color: index < 3
                                      ? Colors.white
                                      : Colors.grey[600],
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
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
                                color: isFirst
                                    ? Colors.amber
                                    : Colors.grey[400],
                                size: 28,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 4. Info Terkini Section
              StreamBuilder<GlobalSettingsModel>(
                stream: Provider.of<FirestoreService>(
                  context,
                  listen: false,
                ).getGlobalSettings(),
                builder: (context, settingsSnapshot) {
                  final infoText =
                      settingsSnapshot.data?.latestInfo ??
                      'Batas klaim pulsa bulan ini: Tgl 25.';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Info Terkini',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                infoText,
                                style: GoogleFonts.outfit(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 120), // Bottom spacer for Nav
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}
