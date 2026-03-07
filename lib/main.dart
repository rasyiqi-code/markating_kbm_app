import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Add this for cleaner URLs
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting initialization

import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/auth/login_screen.dart';
import 'package:markating_kbm_app/src/features/auth/register_screen.dart';
import 'package:markating_kbm_app/src/features/home/main_screen.dart';
import 'package:markating_kbm_app/src/features/home/poster_generator_screen.dart';

import 'package:markating_kbm_app/src/features/admin/product_management_screen.dart';
import 'package:markating_kbm_app/src/features/admin/add_edit_product_screen.dart';
import 'package:markating_kbm_app/src/features/admin/global_settings_screen.dart';
import 'package:markating_kbm_app/src/features/admin/admin_transactions_screen.dart';
import 'package:markating_kbm_app/src/features/admin/admin_withdrawals_screen.dart';
import 'package:markating_kbm_app/src/features/admin/admin_user_list_screen.dart';
import 'package:markating_kbm_app/src/features/catalog/catalog_screen.dart';
import 'package:markating_kbm_app/src/features/catalog/product_detail_screen.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/notification_service.dart';
import 'package:markating_kbm_app/src/features/sales/sales_entry_r1_screen.dart';
import 'package:markating_kbm_app/src/features/sales/sales_entry_r2_screen.dart';
import 'package:markating_kbm_app/src/features/link_bio/link_bio_loading_screen.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:markating_kbm_app/src/features/notifications/notification_controller.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:markating_kbm_app/src/core/utils/responsive_web_layout.dart';
import 'package:markating_kbm_app/src/features/splash/splash_screen.dart'; // Splash Screen Import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: "assets/env"); // Load environment variables
  await initializeDateFormatting('id_ID', null); // Initialize date formatting

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ), // Register StorageService
        ChangeNotifierProvider<NotificationController>(
          create: (context) => NotificationController(
            Provider.of<FirestoreService>(context, listen: false),
            Provider.of<NotificationService>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketing KBM',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Enable System Dark Mode

      routes: {
        // '/': (context) => const SplashScreen(), // Moved to onGenerateRoute
        '/auth_wrapper': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/sales/r1': (context) => const SalesEntryR1Screen(),
        '/sales/r2': (context) => const SalesEntryR2Screen(),
        '/catalog': (context) => const CatalogScreen(),
        '/catalog/detail': (context) => const ProductDetailScreen(),
        '/admin/products': (context) => const ProductManagementScreen(),
        '/admin/products/add': (context) => const AddEditProductScreen(),
        '/admin/settings': (context) => const GlobalSettingsScreen(),
        '/admin/transactions/r1': (context) =>
            const AdminTransactionsScreen(houseType: 1),
        '/admin/transactions/r2': (context) =>
            const AdminTransactionsScreen(houseType: 2),
        '/admin/withdrawals': (context) => const AdminWithdrawalsScreen(),
        '/admin/users': (context) => const AdminUserListScreen(),
        '/poster_generator': (context) => const PosterGeneratorScreen(),
      },
      onGenerateRoute: (settings) {
        // Debugging Route
        debugPrint('Routing: ${settings.name}');

        final uri = Uri.parse(settings.name ?? '');

        // 1. Check for Bio Link
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'bio') {
          // Removed length > 1 strict check to see if it catches partials
          if (uri.pathSegments.length > 1) {
            final userId = uri.pathSegments[1];
            if (userId.isNotEmpty) {
              return MaterialPageRoute(
                builder: (context) => LinkBioLoadingScreen(userId: userId),
              );
            }
          }
        }

        // 2. Default to Splash Screen for root '/'
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(builder: (context) => const SplashScreen());
        }

        // 3. Fallback for unknown routes (to prevent dropping to null/error silently)
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Page Not Found: ${settings.name}')),
          ),
        );
      },
      builder: (context, child) {
        return ResponsiveWebLayout(child: child ?? const SizedBox());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? const LoginScreen() : const MainScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
