import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';

Future<void> showDownloadsHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const DownloadsHelpSheet(),
  );
}

class DownloadsHelpSheet extends StatelessWidget {
  const DownloadsHelpSheet({super.key});

  static const steps = [
    ('افتح قائمة فصول الرواية', Icons.menu_book_outlined),
    ('اختر فصلًا أو عدة فصول', Icons.checklist_rounded),
    ('اضغط زر التنزيل', Icons.download_rounded),
    ('تابع التقدم من هذه الشاشة', Icons.downloading_rounded),
    ('اقرأ الفصل دون اتصال', Icons.offline_bolt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GalaxyBottomSheet(
      title: 'كيف تعمل التنزيلات؟',
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.68,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'يُخصم الفصل من حصتك بعد حفظه بنجاح فقط.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: GalaxyMetrics.space16),
            for (var index = 0; index < steps.length; index++) ...[
              _HelpStep(
                index: index + 1,
                label: steps[index].$1,
                icon: steps[index].$2,
              ),
              if (index < steps.length - 1)
                const SizedBox(height: GalaxyMetrics.space8),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GalaxySurface(
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space12),
      child: Row(
        children: [
          GalaxyBadge(
            label: '$index',
            tone: GalaxyBadgeTone.brand,
            size: GalaxyComponentSize.small,
          ),
          const SizedBox(width: GalaxyMetrics.space12),
          Icon(icon, size: 22),
          const SizedBox(width: GalaxyMetrics.space8),
          Expanded(child: Text('$index. $label')),
        ],
      ),
    );
  }
}
