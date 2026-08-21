import 'package:flutter/material.dart';

import '../../../design_system/components/galaxy_tab_strip.dart';
import '../../../design_system/foundation/galaxy_motion.dart';

enum ReaderJourneyTab { history, downloads }

class ReaderJourneyScreen extends StatelessWidget {
  const ReaderJourneyScreen({
    required this.history,
    required this.downloads,
    this.initialTab = ReaderJourneyTab.history,
    super.key,
  });

  final Widget history;
  final Widget downloads;
  final ReaderJourneyTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ReaderJourneyTab.values.length,
      initialIndex: initialTab.index,
      animationDuration: GalaxyMotion.resolve(context, GalaxyMotion.emphasis),
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          return Column(
            children: [
              GalaxyTabStrip(
                key: const ValueKey('reader-journey-tabs'),
                controller: controller,
                tabs: const [
                  GalaxyTabSpec(label: 'سجل القراءة', icon: Icons.history),
                  GalaxyTabSpec(
                    label: 'التنزيلات',
                    icon: Icons.download_for_offline_outlined,
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: controller,
                  children: [
                    _JourneyTabPage(
                      key: const PageStorageKey('reader-journey-history'),
                      child: history,
                    ),
                    _JourneyTabPage(
                      key: const PageStorageKey('reader-journey-downloads'),
                      child: downloads,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JourneyTabPage extends StatefulWidget {
  const _JourneyTabPage({required this.child, super.key});

  final Widget child;

  @override
  State<_JourneyTabPage> createState() => _JourneyTabPageState();
}

class _JourneyTabPageState extends State<_JourneyTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
