import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/models/link_bio_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/link_bio/link_bio_preview_screen.dart';

class LinkBioLoadingScreen extends StatelessWidget {
  final String userId;

  const LinkBioLoadingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: firestore.resolveUser(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError ||
              !userSnapshot.hasData ||
              userSnapshot.data == null) {
            return const Center(child: Text('User Not Found'));
          }

          final user = userSnapshot.data!;

          return StreamBuilder<List<LinkBioModel>>(
            stream: firestore.getLinks(user.id),
            builder: (context, linkSnapshot) {
              if (linkSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final links = linkSnapshot.data ?? [];

              return LinkBioPreviewScreen(
                user: user,
                links: links,
                isPublicView: true, // New flag to hide close button
              );
            },
          );
        },
      ),
    );
  }
}
