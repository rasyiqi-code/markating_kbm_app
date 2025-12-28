import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';

// Screens
import 'package:markating_kbm_app/src/features/home/home_screen.dart'; // Marketing Home
import 'package:markating_kbm_app/src/features/link_bio/link_bio_screen.dart';
import 'package:markating_kbm_app/src/features/catalog/catalog_screen.dart';
import 'package:markating_kbm_app/src/features/profile/profile_screen.dart';

// Admin Screens
import 'package:markating_kbm_app/src/features/admin/product_management_screen.dart'; // Manage Catalog
import 'package:markating_kbm_app/src/features/admin/admin_home_screen.dart'; // NEW Admin Home

// Widgets
import 'package:markating_kbm_app/src/features/home/widgets/main_bottom_nav_bar.dart';
import 'package:markating_kbm_app/src/features/home/widgets/marketing_fab_menu.dart';
import 'package:markating_kbm_app/src/features/home/widgets/admin_fab_menu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<UserModel>(
      stream: Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getUserStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // If permission denied (likely logout race condition), show loading while AuthWrapper redirects
          if (snapshot.error.toString().contains('permission-denied')) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading profile: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userModel = snapshot.data!;
        final isAdmin = userModel.role == 'admin';

        // Initialize Notification Listener
        Provider.of<NotificationController>(
          context,
          listen: false,
        ).listenToNotifications(userModel.id, isAdmin: isAdmin);

        final pages = isAdmin ? _getAdminPages() : _getMarketingPages();

        // Ensure index is valid when switching roles or pages change count
        if (_currentIndex >= pages.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          extendBody: true,
          body: pages[_currentIndex],
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (isAdmin) {
                _showAdminFabMenu(context);
              } else {
                _showMarketingFabMenu(context);
              }
            },
            backgroundColor: AppTheme.primaryColor,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: MainBottomNavigationBar(
            currentIndex: _currentIndex,
            isAdmin: isAdmin,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }

  List<Widget> _getMarketingPages() {
    return [
      const HomeScreen(), // 1. Home (Wallet & Stats)
      const LinkBioScreen(), // 2. Link Bio
      const CatalogScreen(), // 4. Catalog (Item 3 is FAB)
      const ProfileScreen(), // 5. Profile
    ];
  }

  List<Widget> _getAdminPages() {
    return [
      const AdminHomeScreen(), // 1. Admin Home (Stats & Quick Access)
      const LinkBioScreen(), // 2. Manage Bio (Reuse for now)
      const ProductManagementScreen(), // 4. Manage Catalog
      const ProfileScreen(), // 5. Profile
    ];
  }

  void _showMarketingFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const MarketingFabMenu(),
    );
  }

  void _showAdminFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdminFabMenu(),
    );
  }
}
