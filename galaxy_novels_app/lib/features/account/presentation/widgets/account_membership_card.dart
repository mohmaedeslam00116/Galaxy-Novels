import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/auth_session.dart';

class AccountMembershipCard extends StatelessWidget {
  const AccountMembershipCard({required this.vip, super.key});

  final AuthVip vip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final active = vip.active;
    final accent = active ? tokens.gold : tokens.textSecondary;
    final statusLabel = active ? 'VIP مفعل' : 'حساب عادي';
    final title = active
        ? (vip.label.isEmpty ? 'عضو VIP' : vip.label)
        : 'عضوية عادية';
    final description = active
        ? _vipExpiryText(context, vip.expiresAt)
        : 'الفصول العامة وتقدم القراءة متاحان دائما';
    final helper = active
        ? 'تظهر فصول VIP حسب صلاحية حسابك من الموقع.'
        : 'فصول VIP تحتاج صلاحية نشطة، ويمكنك متابعة الروايات العامة بدون قيود.';

    return Material(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: active ? 0.14 : 0.09),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.24)),
              ),
              child: SizedBox.square(
                dimension: 46,
                child: Icon(
                  active
                      ? Icons.workspace_premium_outlined
                      : Icons.person_outline_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'حالة العضوية',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: tokens.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MembershipPill(label: statusLabel, color: accent),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: active ? tokens.gold : tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _vipExpiryText(BuildContext context, DateTime? expiresAt) {
    if (expiresAt == null) {
      return 'فعال حاليا';
    }
    final date = MaterialLocalizations.of(
      context,
    ).formatCompactDate(expiresAt.toLocal());
    return 'ينتهي في $date';
  }
}

class _MembershipPill extends StatelessWidget {
  const _MembershipPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
