import 'package:flutter/material.dart';

class AnnouncementSettingsCard extends StatelessWidget {
  final TextEditingController latestInfoController;
  final TextEditingController webBaseUrlController;

  const AnnouncementSettingsCard({
    super.key,
    required this.latestInfoController,
    required this.webBaseUrlController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: latestInfoController,
            decoration: const InputDecoration(
              labelText: 'Info Terkini',
              hintText: 'Contoh: Batas klaim pulsa bulan ini: Tgl 25.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.info_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: webBaseUrlController,
            decoration: const InputDecoration(
              labelText: 'URL Dasar Web App',
              hintText: 'https://kbm-group-app.web.app',
              helperText: 'URL dasar untuk link Bio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
        ],
      ),
    );
  }
}
