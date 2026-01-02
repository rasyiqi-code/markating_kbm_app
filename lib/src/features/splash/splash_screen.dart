import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigate after delay using Timer
    _timer = Timer(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    // Check if SplashScreen is still best route (e.g. hasn't been covered by deep link)
    if (ModalRoute.of(context)?.isCurrent == false) {
      debugPrint('SplashScreen: Not current route, skipping redirect.');
      return;
    }

    Navigator.of(context).pushReplacementNamed('/auth_wrapper');
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent unwanted redirect
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background for logos
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo_kbm_red.png',
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 30),
                        Image.asset(
                          'assets/logo_kbm_blue.png',
                          height: 120, // Slightly larger as it usually has text
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    color: Color(0xFFD32F2F), // KBM Red
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.1.1',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
