import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markating_kbm_app/src/features/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AuthService>(
          create: (_) => AuthService(),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('KBM Group'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
