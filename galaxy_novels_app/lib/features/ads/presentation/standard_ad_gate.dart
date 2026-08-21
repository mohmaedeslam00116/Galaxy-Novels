import 'package:flutter/widgets.dart';

import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../application/standard_ad_visibility_policy.dart';

class StandardAdGate extends StatelessWidget {
  const StandardAdGate({
    required this.authRepository,
    required this.builder,
    super.key,
  });

  final AuthRepository authRepository;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: authRepository,
      builder: (context, session, child) {
        if (!StandardAdVisibilityPolicy.canShow(session)) {
          return const SizedBox.shrink();
        }
        return builder(context);
      },
    );
  }
}
