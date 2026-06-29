import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/rankings_data.dart';
import '../../novel_details/presentation/novel_details_screen.dart';
import 'widgets/rankings_content.dart';

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
          return const _RankingsMessage(title: 'جار تحميل الترتيب...');
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _RankingsMessage(
            title: 'تعذر تحميل الترتيب الآن',
            actionLabel: 'إعادة المحاولة',
            onAction: _retry,
          );
        }

        final rankings = snapshot.data!;
        if (rankings.items.isEmpty) {
          return const _RankingsMessage(
            title: 'لا توجد روايات في الترتيب الآن',
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
      ),
    );
  }
}

class _RankingsMessage extends StatelessWidget {
  const _RankingsMessage({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
