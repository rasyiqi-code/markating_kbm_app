import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';
import 'package:provider/provider.dart';

class BonusEligibilityCard extends StatefulWidget {
  final String userId;

  const BonusEligibilityCard({super.key, required this.userId});

  @override
  State<BonusEligibilityCard> createState() => _BonusEligibilityCardState();
}

class _BonusEligibilityCardState extends State<BonusEligibilityCard> {
  int _userMonthlyBonusCount = 0;
  int _monthlySalesCount = 0;
  double _monthlySalesTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    // Fetch stats
    final monthlyBonuses = await firestore.getUserBonusCountThisMonth(
      widget.userId,
    );
    final monthlyStats = await firestore.getUserSalesStatsThisMonth(
      widget.userId,
    );

    if (mounted) {
      setState(() {
        _userMonthlyBonusCount = monthlyBonuses;
        _monthlySalesCount = monthlyStats['count'] as int;
        _monthlySalesTotal = monthlyStats['total'] as double;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalSettingsModel>(
      stream: Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getGlobalSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final settings = snapshot.data!;
        if (!settings.enableR1PulsaBonus) return const SizedBox.shrink();

        // Calculate eligibility based on ENABLED rules only
        final bool isTargetMet =
            settings.enableMinSalesLimit &&
            (_monthlySalesTotal >= settings.minSaleForPulsa);
        final bool isCountMet =
            settings.enableMinCompletedSalesLimit &&
            (_monthlySalesCount >= settings.minCompletedSalesCount);
        
        // Final eligibility: Must meet at least one ENABLED target
        final bool isEligible = (isTargetMet || isCountMet);
        final bool isBonusLimitReached =
            _userMonthlyBonusCount >= settings.maxPulsaBonusCount;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
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
            // border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isEligible && !isBonusLimitReached
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isEligible && !isBonusLimitReached
                            ? Icons.verified_rounded
                            : Icons.verified_user_outlined,
                        color: isEligible && !isBonusLimitReached
                            ? Colors.green
                            : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Kelayakan Bonus',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isBonusLimitReached)
                            Text(
                              'Bonus bulan ini sudah diterima',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (isEligible)
                            Text(
                              'Selamat! Anda berhak klaim bonus.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (settings.enableMinSalesLimit) ...[
                      _buildProgressItem(
                        icon: Icons.monetization_on_rounded,
                        label: 'Target Penjualan',
                        current: _monthlySalesTotal,
                        target: settings.minSaleForPulsa.toDouble(),
                        isCurrency: true,
                        isMet: isTargetMet,
                        accentColor: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (settings.enableMinCompletedSalesLimit) ...[
                      _buildProgressItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Jumlah Transaksi',
                        current: _monthlySalesCount.toDouble(),
                        target: settings.minCompletedSalesCount.toDouble(),
                        isCurrency: false,
                        isMet: isCountMet,
                        accentColor: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!settings.enableMinSalesLimit &&
                        !settings.enableMinCompletedSalesLimit)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              color: Colors.grey,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Program Bonus Sedang Nonaktif',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Saat ini belum ada target bonus yang aktif.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Capai salah satu target di atas untuk klaim bonus pulsa ${AppFormatters.currency(settings.pulsaBonusAmount)}.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required double current,
    required double target,
    required bool isCurrency,
    required bool isMet,
    required Color accentColor,
  }) {
    double progress = (current / target).clamp(0.0, 1.0);
    final color = isMet ? Colors.green : accentColor;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCurrency
                        ? '${AppFormatters.currency(current)} / ${AppFormatters.currency(target)}'
                        : '${current.toInt()} / ${target.toInt()} Transaksi',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isMet)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[100],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
