import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/rankings_data.dart';
import '../../../shared/widgets/app_async_state.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../novel_details/presentation/novel_details_navigation.dart';
import 'widgets/rankings_content.dart';
import 'widgets/rankings_loading_state.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  Future<RankingsData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppDependencies.of(context).rankingsRepository.loadRankings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RankingsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const RankingsLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AppAsyncState.error(
            title: 'تعذر تحميل الترتيب الآن',
            message: 'تحقق من الاتصال ثم حاول مجددًا.',
            onRetry: _retry,
          );
        }

        final rankings = snapshot.data!;
        if (rankings.items.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد روايات في الترتيب الآن',
            message: 'ستظهر الروايات هنا عند توفر الترتيب.',
          );
        }

        return RankingsContent(
          rankings: rankings,
          onOpenNovel: _openNovelDetails,
        );
      },
    );
  }

  void _retry() {
    setState(() {
      _future = AppDependencies.of(context).rankingsRepository.loadRankings();
    });
  }

  void _openNovelDetails(String manifestPath) {
    unawaited(NovelDetailsNavigation.open(context, manifestPath: manifestPath));
  }
}
