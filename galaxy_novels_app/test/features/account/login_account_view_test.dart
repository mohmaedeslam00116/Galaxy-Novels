import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/auth_entry_view.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/login_account_view.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/register_account_view.dart';

void main() {
  testWidgets('renders a clean account login entry surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: LoginAccountView(isSubmitting: false, onLogin: (_) async {}),
          ),
        ),
      ),
    );

    expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    expect(find.text('حساب واحد لموقع مجرة الروايات والتطبيق'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-account-benefits')), findsNothing);
  });

  testWidgets('login uses a text link to create an account', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: LoginAccountView(
              isSubmitting: false,
              onLogin: (_) async {},
              onCreateAccount: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget(find.byKey(const ValueKey('auth-show-register'))),
      isA<TextButton>(),
    );
  });

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

  testWidgets('submits account registration through the app API flow', (
    tester,
  ) async {
    RegisterCredentials? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AuthEntryView(
              isSubmitting: false,
              onLogin: (_) async {},
              onRegister: (credentials) async => submitted = credentials,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('auth-show-register')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('register-username')),
      'reader123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'reader@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-display-name')),
      'Reader',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'secret123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm-password')),
      'secret123',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(submitted?.username, 'reader123');
    expect(submitted?.email, 'reader@example.com');
    expect(submitted?.displayName, 'Reader');
    expect(submitted?.password, 'secret123');
    expect(submitted?.rememberSession, isTrue);
    expect(submitted?.deviceLabel, 'Android');
  });

  testWidgets('login credentials are explicitly LTR and left aligned', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: LoginAccountView(isSubmitting: false, onLogin: (_) async {}),
          ),
        ),
      ),
    );

    for (final key in const ['login-username', 'login-password']) {
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.textDirection, TextDirection.ltr, reason: key);
      expect(editable.textAlign, TextAlign.left, reason: key);
    }
  });

  testWidgets(
    'register credentials are LTR while display name keeps Arabic direction',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: RegisterAccountView(
                isSubmitting: false,
                onRegister: (_) async {},
                onShowLogin: () {},
              ),
            ),
          ),
        ),
      );

      for (final key in const [
        'register-username',
        'register-email',
        'register-password',
        'register-confirm-password',
      ]) {
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(EditableText),
          ),
        );
        expect(editable.textDirection, TextDirection.ltr, reason: key);
        expect(editable.textAlign, TextAlign.left, reason: key);
      }

      final displayName = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('register-display-name')),
          matching: find.byType(EditableText),
        ),
      );
      expect(displayName.textDirection, isNot(TextDirection.ltr));
      expect(displayName.textAlign, TextAlign.start);
    },
  );
}
