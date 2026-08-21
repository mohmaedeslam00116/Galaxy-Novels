import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../shared/widgets/app_async_state.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../../account/presentation/account_screen.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../novel_details/presentation/novel_details_navigation.dart';
import '../application/favorites_repository.dart';
import '../domain/favorite_item.dart';
import 'widgets/favorite_novel_row.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({this.embedded = false, this.onOpenLibrary, super.key});

  final bool embedded;
  final VoidCallback? onOpenLibrary;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  AuthRepository? _authRepository;
  FavoritesRepository? _favoritesRepository;
  var _sessionGeneration = 0;

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
    final content = ValueListenableBuilder<AuthSessionState>(
      valueListenable: authRepository,
      builder: (context, session, _) {
        return switch (session.status) {
          AuthSessionStatus.idle ||
          AuthSessionStatus.restoring ||
          AuthSessionStatus.authenticating => const AppAsyncState.loading(
            loadingLabel: 'جارٍ تحميل المفضلة',
          ),
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
            onOpenLibrary: widget.onOpenLibrary ?? _openLibrary,
          ),
        };
      },
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: content,
    );
  }

  void _handleAuthChanged() {
    _sessionGeneration += 1;
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.account),
        builder: (_) => const AccountScreen(),
      ),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.library),
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('المكتبة')),
          body: const CatalogScreen(),
        ),
      ),
    );
  }

  void _openFavorite(FavoriteItem item) {
    unawaited(
      NovelDetailsNavigation.open(context, manifestPath: item.manifestPath),
    );
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final repository = _favoritesRepository!;
    final authRepository = _authRepository!;
    final userId = authRepository.value.user?.id;
    final generation = _sessionGeneration;
    final result = await repository.toggle(item);
    if (!_isCurrentSession(repository, authRepository, userId, generation)) {
      return;
    }

    if (result == FavoriteToggleResult.removed &&
        !repository.value.contains(item.id)) {
      _showRemovedFavoriteSnackBar(
        item,
        repository,
        authRepository,
        userId!,
        generation,
      );
      return;
    }
    _showMutationMessage(_messageFor(result));
  }

  bool _isCurrentSession(
    FavoritesRepository repository,
    AuthRepository authRepository,
    int? userId,
    int generation,
  ) {
    final session = authRepository.value;
    return mounted &&
        userId != null &&
        generation == _sessionGeneration &&
        identical(repository, _favoritesRepository) &&
        identical(authRepository, _authRepository) &&
        session.user?.id == userId &&
        repository.value.userId == userId;
  }

  void _showRemovedFavoriteSnackBar(
    FavoriteItem item,
    FavoritesRepository repository,
    AuthRepository authRepository,
    int userId,
    int generation,
  ) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('أُزيلت الرواية من المفضلة.'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => unawaited(
            _restoreFavorite(
              item,
              repository,
              authRepository,
              userId,
              generation,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreFavorite(
    FavoriteItem item,
    FavoritesRepository repository,
    AuthRepository authRepository,
    int userId,
    int generation,
  ) async {
    if (!_isCurrentSession(repository, authRepository, userId, generation) ||
        repository.value.contains(item.id)) {
      return;
    }
    final result = await repository.toggle(item);
    if (_isCurrentSession(repository, authRepository, userId, generation) &&
        result != FavoriteToggleResult.added) {
      _showMutationMessage(_messageFor(result));
    }
  }

  void _showMutationMessage(String message) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(FavoriteToggleResult result) => switch (result) {
    FavoriteToggleResult.added => 'الرواية موجودة في المفضلة.',
    FavoriteToggleResult.removed => 'تم تحديث المفضلة.',
    FavoriteToggleResult.signInRequired => 'سجّل الدخول لتحديث المفضلة.',
    FavoriteToggleResult.limitReached =>
      'وصلت إلى الحد الأقصى للروايات المفضلة.',
    FavoriteToggleResult.failed => 'تعذر حفظ التغيير على الجهاز.',
  };

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
    this.onOpenLibrary,
  });

  final FavoritesRepository repository;
  final ValueChanged<FavoriteItem> onOpen;
  final ValueChanged<FavoriteItem> onRemove;
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FavoritesState>(
      valueListenable: repository,
      builder: (context, state, _) {
        if (state.status != FavoritesLoadStatus.ready) {
          return const AppAsyncState.loading(
            loadingLabel: 'جارٍ تحميل المفضلة',
          );
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
                AppAsyncState.empty(
                  title: 'لا توجد روايات مفضلة بعد',
                  message: 'أضف رواياتك من صفحة التفاصيل لتجدها هنا.',
                  actionLabel: 'فتح المكتبة',
                  onAction: onOpenLibrary,
                )
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
