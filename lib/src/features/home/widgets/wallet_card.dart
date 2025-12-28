import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/utils/app_formatters.dart';

class WalletCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onClaimTap; // For Commission
  final VoidCallback onClaimPulsaTap; // For Pulsa

  const WalletCard({
    super.key,
    required this.user,
    required this.onClaimTap,
    required this.onClaimPulsaTap,
  });

  @override
  Widget build(BuildContext context) {
    // Used AppFormatters instead

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark card for contrast
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Commission Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 300;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Text(
                              'Saldo Tunai',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Gabungan Komisi & Markup',
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.currency(
                            user.commissionBalance + user.markupBalance,
                          ),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.markupBalance > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '(Termasuk Markup ${AppFormatters.currency(user.markupBalance)})',
                              style: GoogleFonts.outfit(
                                color: Colors.greenAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onClaimTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text('Tarik'),
                      icon: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Saldo Tunai',
                              style: GoogleFonts.outfit(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Gabungan Komisi & Markup',
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.currency(
                            user.commissionBalance + user.markupBalance,
                          ),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.markupBalance > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '(Termasuk Markup ${AppFormatters.currency(user.markupBalance)})',
                              style: GoogleFonts.outfit(
                                color: Colors.greenAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onClaimTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text('Tarik'),
                    icon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                    ),
                  ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Colors.white12),
          ),

          // Pulsa Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    color: Colors.blue[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Pulsa',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(user.pulsaBalance),
                        style: GoogleFonts.outfit(
                          color: Colors.blue[100],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: onClaimPulsaTap,
                style: TextButton.styleFrom(foregroundColor: Colors.blue[200]),
                child: const Text('Klaim Pulsa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
