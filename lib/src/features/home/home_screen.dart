import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/home/widgets/dashboard_stats.dart';
import 'package:markating_kbm_app/src/features/home/widgets/wallet_card.dart';
import 'package:markating_kbm_app/src/features/wallet/withdrawal_request_screen.dart';

import 'package:markating_kbm_app/src/features/home/widgets/bonus_eligibility_card.dart';
import 'package:markating_kbm_app/src/features/home/widgets/home_header.dart';
import 'package:markating_kbm_app/src/features/home/widgets/recent_sales_list.dart';
import 'package:markating_kbm_app/src/features/home/widgets/top_marketers_list.dart';
import 'package:markating_kbm_app/src/features/home/widgets/home_latest_info.dart';

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

    return StreamBuilder<UserModel>(
      stream: Provider.of<FirestoreService>(
        context,
        listen: false,
      ).getUserStream(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _currentUser = snapshot.data;
        }

        final user = _currentUser!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(user: user),
              const SizedBox(height: 24),
              WalletCard(
                user: user,
                onClaimTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalRequestScreen(
                        user: user,
                        allowedType: ClaimModel.typeBank,
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
                        allowedType: ClaimModel.typePulsa,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              BonusEligibilityCard(userId: user.id),
              DashboardStats(userId: user.id),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              RecentSalesList(userId: user.id),
              const SizedBox(height: 24),
              TopMarketersList(currentUserId: user.id),
              const SizedBox(height: 32),
              const HomeLatestInfo(),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }
}
