import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/auth_entry_view.dart';

void main() {
  testWidgets('account starts as a guest without invoking authentication', (
    tester,
  ) async {
    var loginCalls = 0;
    var registerCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AuthEntryView(
              isSubmitting: false,
              onLogin: (LoginCredentials credentials) async {
                loginCalls += 1;
              },
              onRegister: (RegisterCredentials credentials) async {
                registerCalls += 1;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('تتصفح كزائر'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-username')), findsNothing);
    expect(find.byKey(const ValueKey('register-username')), findsNothing);
    expect(find.byKey(const ValueKey('auth-show-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-show-register')), findsOneWidget);
    expect(
      tester.widget(find.byKey(const ValueKey('auth-show-login'))),
      isA<FilledButton>(),
    );
    expect(
      tester.widget(find.byKey(const ValueKey('auth-show-register'))),
      isA<TextButton>(),
    );
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(loginCalls, 0);
    expect(registerCalls, 0);
  });

  testWidgets(
    'optional login and registration can return to the guest landing',
    (tester) async {
      var loginCalls = 0;
      var registerCalls = 0;

      await tester.pumpWidget(
        _authEntry(
          onLogin: (_) async => loginCalls += 1,
          onRegister: (_) async => registerCalls += 1,
        ),
      );

      await tester.ensureVisible(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-username')), findsOneWidget);
      expect(find.byKey(const ValueKey('register-username')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('login-back-to-guest')));
      await tester.pumpAndSettle();
      expect(find.text('تتصفح كزائر'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('auth-show-register')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('register-username')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-username')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('register-back-to-guest')));
      await tester.pumpAndSettle();
      expect(find.text('تتصفح كزائر'), findsOneWidget);
      expect(loginCalls, 0);
      expect(registerCalls, 0);
    },
  );

  testWidgets(
    'login and register fields stay centered at 520 on wide screens',
    (tester) async {
      tester.view.physicalSize = const Size(840, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_authEntry());
      await tester.tap(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();

      final loginField = tester.getRect(
        find.byKey(const ValueKey('login-username')),
      );
      expect(loginField.width, lessThanOrEqualTo(520));
      expect(loginField.center.dx, closeTo(420, 1));

      await tester.tap(find.byKey(const ValueKey('login-back-to-guest')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-show-register')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-show-register')));
      await tester.pumpAndSettle();

      final registerField = tester.getRect(
        find.byKey(const ValueKey('register-username')),
      );
      expect(registerField.width, lessThanOrEqualTo(520));
      expect(registerField.center.dx, closeTo(420, 1));
    },
  );

  testWidgets(
    'login and register remain scrollable at 320, 200%, and keyboard insets',
    (tester) async {
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _authEntry(
          mediaQueryData: const MediaQueryData(
            size: Size(320, 560),
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: 220),
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-show-login')));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('login-submit')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey('login-back-to-guest')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('login-back-to-guest')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-show-register')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth-show-register')));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('register-submit')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('login mode survives submitting and error rebuilds', (
    tester,
  ) async {
    final harnessKey = GlobalKey<_AuthEntryHarnessState>();
    await _pumpRebuildHarness(tester, harnessKey);

    await tester.ensureVisible(find.byKey(const ValueKey('auth-show-login')));
    await tester.tap(find.byKey(const ValueKey('auth-show-login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-account-form')), findsOneWidget);

    harnessKey.currentState!.update(
      isSubmitting: true,
      errorMessage: 'تعذر تسجيل الدخول.',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('login-account-form')), findsOneWidget);
    expect(find.byKey(const ValueKey('register-account-form')), findsNothing);
    expect(find.text('تتصفح كزائر'), findsNothing);
    expect(find.text('تعذر تسجيل الدخول.'), findsOneWidget);
  });

  testWidgets('register mode survives submitting and error rebuilds', (
    tester,
  ) async {
    final harnessKey = GlobalKey<_AuthEntryHarnessState>();
    await _pumpRebuildHarness(tester, harnessKey);

    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-show-register')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-show-register')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('register-account-form')), findsOneWidget);

    harnessKey.currentState!.update(
      isSubmitting: true,
      errorMessage: 'تعذر إنشاء الحساب.',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('register-account-form')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-account-form')), findsNothing);
    expect(find.text('تتصفح كزائر'), findsNothing);
    expect(find.text('تعذر إنشاء الحساب.'), findsOneWidget);
  });
}

Future<void> _pumpRebuildHarness(
  WidgetTester tester,
  GlobalKey<_AuthEntryHarnessState> harnessKey,
) async {
  tester.view.physicalSize = const Size(840, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: _AuthEntryHarness(key: harnessKey)),
      ),
    ),
  );
}

class _AuthEntryHarness extends StatefulWidget {
  const _AuthEntryHarness({super.key});

  @override
  State<_AuthEntryHarness> createState() => _AuthEntryHarnessState();
}

class _AuthEntryHarnessState extends State<_AuthEntryHarness> {
  bool isSubmitting = false;
  String? errorMessage;

  void update({required bool isSubmitting, required String errorMessage}) {
    setState(() {
      this.isSubmitting = isSubmitting;
      this.errorMessage = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthEntryView(
      key: const ValueKey('persistent-auth-entry'),
      isSubmitting: isSubmitting,
      errorMessage: errorMessage,
      onLogin: (_) async {},
      onRegister: (_) async {},
    );
  }
}

Widget _authEntry({
  Future<void> Function(LoginCredentials credentials)? onLogin,
  Future<void> Function(RegisterCredentials credentials)? onRegister,
  MediaQueryData? mediaQueryData,
}) {
  Widget child = Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: AuthEntryView(
        isSubmitting: false,
        onLogin: onLogin ?? (_) async {},
        onRegister: onRegister ?? (_) async {},
      ),
    ),
  );
  if (mediaQueryData != null) {
    child = MediaQuery(data: mediaQueryData, child: child);
  }
  return MaterialApp(home: child);
}
