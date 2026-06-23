import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../../account/presentation/account_screen.dart';
import '../../novel_details/presentation/novel_details_screen.dart';
import '../application/favorites_repository.dart';
import '../domain/favorite_item.dart';
import 'widgets/favorite_novel_row.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  AuthRepository? _authRepository;
  FavoritesRepository? _favoritesRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    final authRepository = dependencies.authRepository;
    if (_authRepository != authRepository) {
      _authRepository?.removeListener(_handleAuthChanged);
      _authRepository = authRepository;
      authRepository.addListener(_handleAuthChanged);
    }
    _favoritesRepository = dependencies.favoritesRepository;
    _loadAccountAndFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = _authRepository!;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: ValueListenableBuilder<AuthSessionState>(
        valueListenable: authRepository,
        builder: (context, session, _) {
          return switch (session.status) {
            AuthSessionStatus.idle ||
            AuthSessionStatus.restoring ||
            AuthSessionStatus.authenticating => const _FavoritesSkeleton(),
            AuthSessionStatus.guest ||
            AuthSessionStatus.failure => _SignInRequired(
              message: session.errorMessage,
              onOpenAccount: _openAccount,
            ),
            AuthSessionStatus.authenticated ||
            AuthSessionStatus.signingOut => _AuthenticatedFavorites(
              repository: _favoritesRepository!,
              onOpen: _openFavorite,
              onRemove: _removeFavorite,
            ),
          };
        },
      ),
    );
  }

  void _handleAuthChanged() {
    if (_authRepository?.value.status == AuthSessionStatus.authenticated) {
      unawaited(_favoritesRepository?.load());
    }
  }

  void _loadAccountAndFavorites() {
    final authRepository = _authRepository!;
    if (authRepository.value.status == AuthSessionStatus.idle) {
      unawaited(authRepository.restoreSession());
    } else if (authRepository.value.status == AuthSessionStatus.authenticated) {
      unawaited(_favoritesRepository!.load());
    }
  }

  void _openAccount() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
  }

  void _openFavorite(FavoriteItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NovelDetailsScreen(manifestPath: item.manifestPath),
      ),
    );
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final result = await _favoritesRepository!.toggle(item);
    if (mounted && result == FavoriteToggleResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ التغيير على الجهاز.')),
      );
    }
  }

  @override
  void dispose() {
    _authRepository?.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

class _AuthenticatedFavorites extends StatelessWidget {
  const _AuthenticatedFavorites({
    required this.repository,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoritesRepository repository;
  final ValueChanged<FavoriteItem> onOpen;
  final ValueChanged<FavoriteItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FavoritesState>(
      valueListenable: repository,
      builder: (context, state, _) {
        if (state.status != FavoritesLoadStatus.ready) {
          return const _FavoritesSkeleton();
        }
        return RefreshIndicator(
          onRefresh: repository.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (state.isSyncing) const LinearProgressIndicator(minHeight: 2),
              if (state.errorMessage case final message?) ...[
                _SyncNotice(message: message, icon: Icons.cloud_off_outlined),
                const SizedBox(height: 12),
              ] else if (state.pendingCount > 0) ...[
                _SyncNotice(
                  message:
                      '${state.pendingCount} تغيير محفوظ بانتظار المزامنة.',
                  icon: Icons.cloud_upload_outlined,
                ),
                const SizedBox(height: 12),
              ],
              if (state.items.isEmpty)
                const _EmptyFavorites()
              else
                for (var index = 0; index < state.items.length; index++) ...[
                  FavoriteNovelRow(
                    item: state.items[index],
                    onOpen: () => onOpen(state.items[index]),
                    onRemove: () => onRemove(state.items[index]),
                  ),
                  if (index != state.items.length - 1)
                    const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onOpenAccount, this.message});

  final VoidCallback onOpenAccount;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_outline_rounded, size: 54),
            const SizedBox(height: 18),
            Text(
              'مفضلتك مرتبطة بحسابك',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'سجّل الدخول لتبقى رواياتك المفضلة متاحة على أجهزتك.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onOpenAccount,
              icon: const Icon(Icons.login_rounded),
              label: const Text('فتح حسابي'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            size: 52,
            color: tokens.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد روايات مفضلة بعد',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'أضف رواياتك من صفحة التفاصيل لتجدها هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SyncNotice extends StatelessWidget {
  const _SyncNotice({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 112,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
