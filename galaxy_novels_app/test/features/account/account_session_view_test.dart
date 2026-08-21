import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/account/application/auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/account/presentation/widgets/account_session_view.dart';
import 'package:galaxy_novels_app/shared/widgets/app_skeleton.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets('account loading mirrors the compact profile', (tester) async {
    final repository = FakeAuthRepository(
      initialState: const AuthSessionState.restoring(),
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(_sessionApp(repository));

    expect(find.byKey(const ValueKey('account-loading-state')), findsOneWidget);
    expect(find.byType(AppSkeleton), findsNWidgets(7));
    expect(find.text('جارٍ تحميل الحساب...'), findsNothing);
  });

  testWidgets('account failure retries session restoration once', (
    tester,
  ) async {
    final repository = _RestoreCountingRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(_sessionApp(repository));

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(repository.restoreCalls, 1);
  });
}

Widget _sessionApp(AuthRepository repository) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: AccountSessionView(repository: repository)),
    ),
  );
}

class _RestoreCountingRepository extends FakeAuthRepository {
  _RestoreCountingRepository()
    : super(initialState: const AuthSessionState.failure('تعذر التحقق.'));

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls += 1;
  }
}
