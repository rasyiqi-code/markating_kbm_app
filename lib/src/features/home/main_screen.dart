import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // If we can't load user data (e.g. Permission Denied means Zombie Account)
          // we should force logout to prevent infinite spin.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Provider.of<FirestoreService>(context, listen: false).signOut(); // Invalid
            // Sign out via FirebaseAuth instance directly to clear zombie state
            FirebaseAuth.instance.signOut();
          });

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
          bottomNavigationBar: _buildBottomBar(isAdmin),
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

  Widget _buildBottomBar(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. Home
            _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),

            // 2. Bio
            _buildNavItem(1, Icons.link_rounded, Icons.link),

            // 3. Gap for FAB
            const SizedBox(width: 48),

            // 4. Catalog / Manage Catalog
            _buildNavItem(
              2,
              isAdmin ? Icons.edit_note_rounded : Icons.menu_book_rounded,
              isAdmin ? Icons.edit_note_outlined : Icons.menu_book_outlined,
            ),

            // 5. Profile
            _buildNavItem(
              3,
              Icons.person_rounded,
              Icons.person_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
  ) {
    // Note: pages list has 4 items. Index 0,1 are Left. Index 2,3 are Right.
    // FAB is visually "Index 2.5", effectively splitting them.
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        width: 50,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).unselectedWidgetColor,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _showMarketingFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Sale',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'Penerbitan',
                      Icons.book_rounded,
                      Colors.blue,
                      '/sales/r1',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'KBM Creator',
                      Icons.brush_rounded,
                      Colors.purple,
                      '/sales/r2',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Admin Quick Actions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Placeholder routes for admin transactions
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'Trans Penerbitan',
                      Icons.assignment_rounded,
                      Colors.blue,
                      '/admin/transactions/r1',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'Trans Creator',
                      Icons.assignment_ind_rounded,
                      Colors.purple,
                      '/admin/transactions/r2',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'Manage Agents',
                      Icons.people_alt_rounded,
                      Colors.teal,
                      '/admin/users',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFabOption(
                      context,
                      'Withdrawals',
                      Icons.account_balance_wallet_rounded,
                      Colors.orange,
                      '/admin/withdrawals',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFabOption(
    BuildContext context,
    String title,
    IconData icon,
    MaterialColor color,
    String route,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          route,
        ); // Handle named routes if not exist later
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? color.shade900.withValues(alpha: 0.3)
              : color.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? color.shade700
                : color.shade100,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? color.shade100
                    : color.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
