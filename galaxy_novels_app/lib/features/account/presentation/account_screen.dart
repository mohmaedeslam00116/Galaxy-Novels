import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/auth_repository.dart';
import '../domain/auth_session.dart';
import 'widgets/account_session_view.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({this.embedded = false, super.key});

  final bool embedded;

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
    final content = AccountSessionView(
      repository: repository,
      onOpenFavorites: _openFavorites,
      onOpenHistory: _openHistory,
      onOpenReaderSettings: _openSettings,
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: content,
    );
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.favorites),
        builder: (_) => const FavoritesScreen(),
      ),
    );
  }

  void _openHistory() {
    _openStandaloneShellPage(
      title: 'السجل',
      body: const HistoryScreen(),
      screenName: AppScreenNames.history,
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.settings),
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openStandaloneShellPage({
    required String title,
    required Widget body,
    required String screenName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: screenName),
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
        ),
      ),
    );
  }
}
