import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class AccountHeroPanel extends StatefulWidget {
  const AccountHeroPanel({
    required this.user,
    this.onRefreshProfile,
    super.key,
  });

  final AuthUser user;
  final Future<void> Function()? onRefreshProfile;

  @override
  State<AccountHeroPanel> createState() => _AccountHeroPanelState();
}

class _AccountHeroPanelState extends State<AccountHeroPanel> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      key: const ValueKey('account-profile-header'),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useStackedLayout =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            return useStackedLayout
                ? _StackedProfileHeader(
                    user: widget.user,
                    refreshAction: _refreshAction(),
                  )
                : _HorizontalProfileHeader(
                    user: widget.user,
                    refreshAction: _refreshAction(),
                  );
          },
        ),
      ),
    );
  }

  Widget _refreshAction() {
    final refreshProfile = widget.onRefreshProfile;
    if (refreshProfile == null) return const SizedBox.shrink();
    return IconButton(
      key: const ValueKey('account-refresh-profile'),
      onPressed: _refreshing ? null : _refresh,
      tooltip: 'تحديث بيانات الحساب',
      icon: _refreshing
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
    );
  }

  Future<void> _refresh() async {
    final refreshProfile = widget.onRefreshProfile;
    if (_refreshing || refreshProfile == null) return;
    setState(() => _refreshing = true);
    try {
      await refreshProfile();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _HorizontalProfileHeader extends StatelessWidget {
  const _HorizontalProfileHeader({
    required this.user,
    required this.refreshAction,
  });

  final AuthUser user;
  final Widget refreshAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccountAvatar(user: user),
        const SizedBox(width: 12),
        Expanded(child: _ProfileIdentity(user: user)),
        const SizedBox(width: 6),
        refreshAction,
      ],
    );
  }
}

class _StackedProfileHeader extends StatelessWidget {
  const _StackedProfileHeader({
    required this.user,
    required this.refreshAction,
  });

  final AuthUser user;
  final Widget refreshAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(alignment: AlignmentDirectional.topEnd, child: refreshAction),
        _AccountAvatar(user: user),
        const SizedBox(height: 12),
        _ProfileIdentity(user: user, alignment: _ProfileAlignment.center),
      ],
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.user,
    this.alignment = _ProfileAlignment.start,
  });

  final AuthUser user;
  final _ProfileAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final rank = user.xp.rank.display.trim();
    final expiry = _membershipExpiry(context, user.vip);

    return Column(
      crossAxisAlignment: alignment == _ProfileAlignment.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          user.displayName,
          textAlign: _textAlignment,
          style: theme.textTheme.titleLarge?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (rank.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            rank,
            textAlign: _textAlignment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          alignment: alignment == _ProfileAlignment.center
              ? WrapAlignment.center
              : WrapAlignment.start,
          spacing: 6,
          runSpacing: 6,
          children: [
            if (user.xp.rank.level > 0)
              _ProfileTag(label: 'المستوى ${user.xp.rank.level}'),
            _ProfileTag(
              label: _membershipLabel(user.vip),
              tone: user.vip.active
                  ? _ProfileTagTone.gold
                  : _ProfileTagTone.primary,
            ),
          ],
        ),
        if (expiry != null) ...[
          const SizedBox(height: 6),
          Text(
            expiry,
            textAlign: _textAlignment,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  TextAlign get _textAlignment => alignment == _ProfileAlignment.center
      ? TextAlign.center
      : TextAlign.start;
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.label, this.tone = _ProfileTagTone.primary});

  final String label;
  final _ProfileTagTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final color = tone == _ProfileTagTone.gold ? tokens.gold : tokens.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

enum _ProfileAlignment { start, center }

enum _ProfileTagTone { primary, gold }

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
      radius: 30,
      backgroundColor: tokens.surfaceRaised,
      backgroundImage: avatarUrl == null || avatarUrl.isEmpty
          ? null
          : NetworkImage(avatarUrl),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initial,
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.primary,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

String _membershipLabel(AuthVip vip) {
  if (!vip.active) return 'حساب عادي';
  return vip.label.trim().isEmpty ? 'عضو VIP' : vip.label;
}

String? _membershipExpiry(BuildContext context, AuthVip vip) {
  final expiresAt = vip.expiresAt;
  if (!vip.active || expiresAt == null) return null;
  final date = MaterialLocalizations.of(
    context,
  ).formatCompactDate(expiresAt.toLocal());
  return 'ينتهي في $date';
}
