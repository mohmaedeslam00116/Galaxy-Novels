import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class AccountHeroPanel extends StatelessWidget {
  const AccountHeroPanel({required this.user, super.key});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                _AccountAvatar(user: user),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (user.xp.rank.display.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          user.xp.rank.display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (user.xp.rank.level > 0)
                  _LevelPill(level: user.xp.rank.level),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final trimmedName = user.displayName.trim();
    final chars = trimmedName.characters;
    final initial = chars.isEmpty ? 'م' : chars.first;
    final avatarUrl = user.avatar?.toString();

    return CircleAvatar(
      radius: 34,
      backgroundColor: tokens.surfaceRaised,
      backgroundImage: avatarUrl == null || avatarUrl.isEmpty
          ? null
          : NetworkImage(avatarUrl),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'المستوى $level',
          style: theme.textTheme.labelMedium?.copyWith(
            color: tokens.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
