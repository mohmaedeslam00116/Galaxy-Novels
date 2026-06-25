import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../application/auth_repository.dart';
import '../domain/auth_session.dart';
import 'widgets/account_session_view.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AuthRepository? _repository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).authRepository;
    if (_repository == repository) {
      return;
    }

    _repository = repository;
    if (repository.value.status == AuthSessionStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _repository != repository) {
          return;
        }
        if (repository.value.status == AuthSessionStatus.idle) {
          unawaited(repository.restoreSession());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository!;

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: AccountSessionView(repository: repository),
    );
  }
}
