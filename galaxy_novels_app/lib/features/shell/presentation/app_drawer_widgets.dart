part of 'app_drawer.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/galaxy_novels_play_icon_512.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                semanticLabel: 'شعار مجرة الروايات',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مجرة الروايات',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عالمك بين النجوم',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w700,
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
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.id,
    required this.title,
    required this.entries,
    required this.onOpen,
  });

  final String id;
  final String title;
  final List<_DrawerEntry> entries;
  final ValueChanged<_DrawerDestination> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: tokens.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          key: ValueKey('drawer-section-$id'),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0)
                    Divider(
                      key: ValueKey('drawer-divider-$id-$index'),
                      height: 1,
                      thickness: 1,
                      indent: 12,
                      endIndent: 12,
                      color: tokens.border.withValues(alpha: 0.72),
                    ),
                  _DrawerTile(
                    entry: entries[index],
                    onTap: () => onOpen(entries[index].destination),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.entry, required this.onTap});

  final _DrawerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Semantics(
      button: true,
      label: entry.label,
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('drawer-destination-${entry.destination.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  _DrawerIcon(icon: entry.icon, iconType: entry.iconType),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: tokens.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerIcon extends StatelessWidget {
  const _DrawerIcon({required this.icon, required this.iconType});

  final IconData icon;
  final _DrawerIconType iconType;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.primary.withValues(alpha: 0.18)),
      ),
      child: SizedBox.square(
        dimension: 30,
        child: Center(
          child: switch (iconType) {
            _DrawerIconType.material => Icon(
              icon,
              color: tokens.primary,
              size: 18,
            ),
            _DrawerIconType.discord => const FaIcon(
              FontAwesomeIcons.discord,
              key: ValueKey('discord-brand-mark'),
              color: Color(0xFF5865F2),
              size: 18,
            ),
          },
        ),
      ),
    );
  }
}

class _DrawerVersionLabel extends StatefulWidget {
  const _DrawerVersionLabel({required this.versionLoader});

  final AppVersionLoader versionLoader;

  @override
  State<_DrawerVersionLabel> createState() => _DrawerVersionLabelState();
}

class _DrawerVersionLabelState extends State<_DrawerVersionLabel> {
  String? _resolvedVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    var resolvedVersion = 'غير متاح';
    try {
      final loaded = (await widget.versionLoader()).displayLabel.trim();
      if (loaded.isNotEmpty) {
        resolvedVersion = loaded;
      }
    } on Exception {
      resolvedVersion = 'غير متاح';
    }
    if (mounted) {
      setState(() => _resolvedVersion = resolvedVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final label = _resolvedVersion == null
        ? 'الإصدار …'
        : 'الإصدار $_resolvedVersion';

    return Semantics(
      label: label,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          label,
          key: const ValueKey('drawer-app-version'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
