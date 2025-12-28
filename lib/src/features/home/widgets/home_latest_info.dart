import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:provider/provider.dart';

class HomeLatestInfo extends StatelessWidget {
  const HomeLatestInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalSettingsModel>(
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
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      infoText,
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
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
    );
  }
}
