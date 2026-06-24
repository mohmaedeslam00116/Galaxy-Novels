import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/catalog_data.dart';
import '../../../data/models/rankings_data.dart';
import '../../novel_details/presentation/novel_details_screen.dart';
import '../../../shared/widgets/novel_list_row.dart';
import '../../../shared/widgets/section_title.dart';

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

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: rankings.items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionTitle(
                title: 'ترتيب الشهر',
                leadingIcon: Icons.leaderboard,
              );
            }

            final rank = index;
            final novel = rankings.items[index - 1];
            return NovelListRow(
              leadingLabel: '#$rank',
              title: novel.title,
              subtitle: _subtitle(novel),
              meta: _meta(novel),
              imageUrl: novel.coverMedium.isNotEmpty
                  ? novel.coverMedium
                  : novel.coverThumbnail,
              badgeLabel: novel.statusLabel,
              onTap: novel.manifest.isEmpty
                  ? null
                  : () => _openNovelDetails(novel.manifest),
            );
          },
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

String _subtitle(CatalogNovel novel) {
  final genres = novel.genres.take(2).map((genre) => genre.name).join('، ');
  if (genres.isNotEmpty) {
    return genres;
  }
  return novel.statusLabel;
}

String _meta(CatalogNovel novel) {
  final parts = <String>[
    if (novel.chaptersCount > 0) '${novel.chaptersCount} فصل',
    if (novel.views > 0) '${_compactNumber(novel.views)} مشاهدة',
  ];
  return parts.join(' • ');
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}
