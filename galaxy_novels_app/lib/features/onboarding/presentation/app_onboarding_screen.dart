import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../application/app_onboarding_controller.dart';
import '../domain/app_onboarding_state.dart';
import 'app_onboarding_art.dart';

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({
    required this.controller,
    required this.entryPoint,
    required this.onFinished,
    required this.onExitRequested,
    super.key,
  });

  final AppOnboardingController controller;
  final AppOnboardingEntryPoint entryPoint;
  final VoidCallback onFinished;
  final VoidCallback onExitRequested;

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      title: 'اكتشف عالمك القادم',
      description:
          'روايات محدثة وتوصيات تناسب قراءتك، مع رئيسية ومكتبة ترتبهما بالطريقة التي تحبها.',
      art: AppOnboardingArtVariant.discovery,
    ),
    _OnboardingPageData(
      title: 'اقرأ بطريقتك',
      description:
          'اختر الثيم والخط المناسبين، واستخدم التمرير التلقائي وتغيير المصطلحات لقراءة أكثر راحة.',
      art: AppOnboardingArtVariant.reading,
    ),
    _OnboardingPageData(
      title: 'رواياتك معك دائمًا',
      description:
          'نزّل فصولك للقراءة دون اتصال، وارجع إلى سجل القراءة لمتابعة رحلتك من حيث توقفت.',
      art: AppOnboardingArtVariant.offline,
    ),
  ];

  late final PageController _pageController = PageController();
  int _pageIndex = 0;
  bool _finishing = false;
  bool _pageTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.controller.recordShown(widget.entryPoint));
      unawaited(
        widget.controller.recordPageView(
          pageNumber: 1,
          entryPoint: widget.entryPoint,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final compactHeight = MediaQuery.sizeOf(context).height < 520;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_pageIndex > 0) {
          _goTo(_pageIndex - 1);
        } else {
          widget.onExitRequested();
        }
      },
      child: Scaffold(
        key: const ValueKey('app-onboarding-screen'),
        backgroundColor: tokens.canvas,
        body: SafeArea(
          child: Column(
            children: [
              _OnboardingTopBar(
                compact: compactHeight,
                onSkip: _finishing
                    ? null
                    : () => _finish(AppOnboardingCompletionMethod.skipped),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                    compact: compactHeight,
                  ),
                ),
              ),
              _OnboardingFooter(
                pageIndex: _pageIndex,
                pageCount: _pages.length,
                busy: _finishing,
                onPrevious: _pageIndex == 0
                    ? null
                    : () => _goTo(_pageIndex - 1),
                onNext: () => _goTo(_pageIndex + 1),
                onStart: () => _finish(AppOnboardingCompletionMethod.completed),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _pageIndex = index);
    unawaited(
      widget.controller.recordPageView(
        pageNumber: index + 1,
        entryPoint: widget.entryPoint,
      ),
    );
  }

  Future<void> _goTo(int index) async {
    if (_finishing ||
        _pageTransitioning ||
        index < 0 ||
        index >= _pages.length) {
      return;
    }
    _pageTransitioning = true;
    try {
      await _pageController.animateToPage(
        index,
        duration: GalaxyMotion.resolve(context, GalaxyMotion.emphasis),
        curve: GalaxyMotion.curve,
      );
    } finally {
      _pageTransitioning = false;
    }
  }

  Future<void> _finish(AppOnboardingCompletionMethod method) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (widget.entryPoint == AppOnboardingEntryPoint.automatic) {
      await widget.controller.completeAutomatic(method);
    }
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.compact, required this.onSkip});

  final bool compact;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, compact ? 2 : 8, 12, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reservedLabelWidth = MediaQuery.textScalerOf(
            context,
          ).scale(110);
          final showBrandLabel =
              constraints.maxWidth - reservedLabelWidth >= 150;
          return Row(
            children: [
              Semantics(
                label: 'مجرة الروايات',
                image: true,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.brandContainer,
                    borderRadius: BorderRadius.circular(
                      GalaxyMetrics.radiusControl,
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: tokens.onBrandContainer,
                  ),
                ),
              ),
              const SizedBox(width: GalaxyMetrics.space12),
              if (showBrandLabel)
                Expanded(
                  child: Text(
                    'مجرة الروايات',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                const Spacer(),
              GalaxyButton(
                key: const ValueKey('onboarding-skip'),
                label: 'تخطي',
                variant: GalaxyActionVariant.ghost,
                onPressed: onSkip,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.compact});

  final _OnboardingPageData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: GalaxyMetrics.space20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: compact ? 190 : 280,
                    child: AppOnboardingArt(variant: data.art),
                  ),
                  SizedBox(height: compact ? 8 : GalaxyMetrics.space20),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: GalaxyMetrics.space12),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: tokens.contentSecondary,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: GalaxyMetrics.space16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.pageIndex,
    required this.pageCount,
    required this.busy,
    required this.onPrevious,
    required this.onNext,
    required this.onStart,
  });

  final int pageIndex;
  final int pageCount;
  final bool busy;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final isLast = pageIndex == pageCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (index) {
                final selected = index == pageIndex;
                return AnimatedContainer(
                  duration: GalaxyMotion.resolve(
                    context,
                    GalaxyMotion.stateChange,
                  ),
                  curve: GalaxyMotion.curve,
                  width: selected ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? tokens.brand : tokens.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            const SizedBox(height: GalaxyMetrics.space16),
            Row(
              children: [
                if (onPrevious != null) ...[
                  Expanded(
                    child: GalaxyButton(
                      key: const ValueKey('onboarding-previous'),
                      label: 'السابق',
                      icon: Icons.arrow_forward_rounded,
                      variant: GalaxyActionVariant.secondary,
                      onPressed: busy ? null : onPrevious,
                    ),
                  ),
                  const SizedBox(width: GalaxyMetrics.space12),
                ],
                Expanded(
                  flex: onPrevious == null ? 1 : 2,
                  child: GalaxyButton(
                    key: ValueKey(
                      isLast ? 'onboarding-start' : 'onboarding-next',
                    ),
                    label: isLast ? 'ابدأ رحلتك' : 'التالي',
                    icon: isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_back_rounded,
                    onPressed: busy ? null : (isLast ? onStart : onNext),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.art,
  });

  final String title;
  final String description;
  final AppOnboardingArtVariant art;
}
