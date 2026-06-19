import '../models/chapter_summary.dart';
import '../models/home_data.dart';
import '../models/novel_summary.dart';
import 'home_repository.dart';

class FakeHomeRepository implements HomeRepository {
  const FakeHomeRepository();

  @override
  Future<HomeData> loadHome() async {
    return const HomeData(
      continueReading: ReadingProgress(
        novelTitle: 'ظلال المجرة',
        chapterLabel: 'الفصل 24',
        progress: 68,
      ),
      latestChapters: [
        ChapterSummary(
          id: 82,
          novelId: 1,
          novelTitle: 'حارس النجوم',
          label: 'الفصل 82',
          title: '',
          dateLabel: 'منذ 12 دقيقة',
          url: '',
        ),
        ChapterSummary(
          id: 41,
          novelId: 2,
          novelTitle: 'مدن الرماد',
          label: 'الفصل 41',
          title: '',
          dateLabel: 'منذ ساعة',
          url: '',
        ),
      ],
      recentNovels: [
        NovelSummary(
          id: 3,
          title: 'بوابة الشمال',
          url: '',
          coverThumbnail: '',
          statusLabel: 'مكتملة',
          genres: ['خيال', 'أكشن', 'مغامرة'],
          chaptersCount: 126,
          manifest: '',
        ),
      ],
    );
  }
}
