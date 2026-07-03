import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/login_account_view.dart';

void main() {
  testWidgets(
    'explains existing-site login without unsupported reset actions',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: LoginAccountView(
                isSubmitting: false,
                onLogin: (_) async {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('استخدم حساب موقع مجرة الروايات الحالي للدخول.'),
        findsOneWidget,
      );
      expect(find.textContaining('استعادة كلمة المرور'), findsNothing);
      expect(find.textContaining('نسيت كلمة المرور'), findsNothing);
    },
  );

  testWidgets('submits credentials without extra account endpoints', (
    tester,
  ) async {
    LoginCredentials? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: LoginAccountView(
              isSubmitting: false,
              onLogin: (credentials) async => submitted = credentials,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-username')),
      'reader',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      'secret',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(submitted?.username, 'reader');
    expect(submitted?.password, 'secret');
    expect(submitted?.rememberSession, isTrue);
  });
}
