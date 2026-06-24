import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../account/application/auth_repository.dart';
import '../../../account/domain/auth_session.dart';
import '../../../favorites/application/favorites_repository.dart';

class FavoriteToggleButton extends StatelessWidget {
  const FavoriteToggleButton({
    required this.novelId,
    required this.authRepository,
    required this.favoritesRepository,
    required this.onPressed,
    super.key,
  });

  final int novelId;
  final AuthRepository authRepository;
  final FavoritesRepository favoritesRepository;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: authRepository,
      builder: (context, session, _) {
        return ValueListenableBuilder<FavoritesState>(
          valueListenable: favoritesRepository,
          builder: (context, favorites, _) {
            final isAuthenticated =
                session.status == AuthSessionStatus.authenticated;
            final isLoading =
                isAuthenticated &&
                favorites.status == FavoritesLoadStatus.loading;
            final isFavorite = isAuthenticated && favorites.contains(novelId);
            return _FavoriteIconButton(
              isFavorite: isFavorite,
              isLoading: isLoading,
              onPressed: novelId > 0 && !isLoading ? onPressed : null,
            );
          },
        );
      },
    );
  }
}

class _FavoriteIconButton extends StatelessWidget {
  const _FavoriteIconButton({
    required this.isFavorite,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isFavorite;
  final bool isLoading;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        key: const ValueKey('novel-favorite-toggle'),
        tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_add_outlined,
              ),
        style: IconButton.styleFrom(
          backgroundColor: isFavorite ? tokens.primary : tokens.surface,
          foregroundColor: isFavorite
              ? Theme.of(context).colorScheme.onPrimary
              : tokens.accent,
          side: BorderSide(
            color: isFavorite
                ? tokens.primary
                : tokens.accent.withValues(alpha: 0.26),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
