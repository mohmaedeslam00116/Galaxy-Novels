import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/chapter_summary.dart';
import 'package:galaxy_novels_app/data/models/home_data.dart';
import 'package:galaxy_novels_app/data/models/novel_summary.dart';

void main() {
  test('NovelSummary parses the catalog item shape used by public packs', () {
    final novel = NovelSummary.fromJson({
      'id': 123,
      'title': 'بوابة الشمال',
      'url': '/novel/north-gate/',
      'cover': {
        'thumbnail': '/uploads/north-thumb.jpg',
        'medium': '/uploads/north-medium.jpg',
        'large': '/uploads/north-large.jpg',
      },
      'status': {'key': 'ongoing', 'label': 'مستمرة'},
      'genres': [
        {'name': 'خيال'},
        {'name': 'أكشن'},
      ],
      'chapters_count': 126,
      'manifest': '/cache/app/manifest/novel-123.json',
    });

    expect(novel.id, 123);
    expect(novel.title, 'بوابة الشمال');
    expect(novel.coverThumbnail, '/uploads/north-thumb.jpg');
    expect(novel.coverMedium, '/uploads/north-medium.jpg');
    expect(novel.coverLarge, '/uploads/north-large.jpg');
    expect(novel.bestCover, '/uploads/north-large.jpg');
    expect(novel.statusLabel, 'مستمرة');
    expect(novel.genres, ['خيال', 'أكشن']);
    expect(novel.chaptersCount, 126);
    expect(novel.manifest, '/cache/app/manifest/novel-123.json');
  });

  test('ChapterSummary parses latest chapter entries', () {
    final chapter = ChapterSummary.fromJson({
      'id': 82,
      'novel_id': 12,
      'novel_title': 'حارس النجوم',
      'label': 'الفصل 82',
      'title': 'نداء بعيد',
      'date': 'منذ 12 دقيقة',
      'url': '/novel/star-guard/chapter-82/',
      'novel_url': '/novel/star-guard/',
      'cover_url': '/uploads/star-guard-legacy.jpg',
      'cover': {
        'thumbnail': '/uploads/star-guard-thumb.jpg',
        'medium': '/uploads/star-guard-medium.jpg',
        'large': '/uploads/star-guard-large.jpg',
      },
      'manifest': '/cache/app/manifest/star-guard.json',
    });

    expect(chapter.id, 82);
    expect(chapter.novelId, 12);
    expect(chapter.novelTitle, 'حارس النجوم');
    expect(chapter.label, 'الفصل 82');
    expect(chapter.title, 'نداء بعيد');
    expect(chapter.dateLabel, 'منذ 12 دقيقة');
    expect(chapter.url, '/novel/star-guard/chapter-82/');
    expect(chapter.novelUrl, '/novel/star-guard/');
    expect(chapter.coverUrl, '/uploads/star-guard-legacy.jpg');
    expect(chapter.bestCover, '/uploads/star-guard-large.jpg');
    expect(chapter.manifest, '/cache/app/manifest/star-guard.json');
    expect(
      chapter.effectiveContentApi,
      '/wp-json/wor-reader-app/v1/chapters/82',
    );
  });

  test('ChapterSummary accepts novel_manifest as a latest update fallback', () {
    final chapter = ChapterSummary.fromJson({
      'id': 83,
      'novel_id': 12,
      'novel_title': 'حارس النجوم',
      'label': 'الفصل 83',
      'date': 'الآن',
      'url': '/novel/star-guard/chapter-83/',
      'novel_manifest': '/cache/app/manifest/star-guard-legacy.json',
    });

    expect(chapter.manifest, '/cache/app/manifest/star-guard-legacy.json');
  });

  test(
    'ChapterSummary parses grouped latest chapter entries from home packs',
    () {
      final chapter = ChapterSummary.fromJson({
        'novel_id': 97656,
        'novel_title': 'تاجر تطوير الوحوش',
        'latest_date': 'يونيو 18, 2026',
        'chapters': [
          {
            'id': 98239,
            'label': 'الفصل 580',
            'title': 'صرخة الطائر',
            'url': 'https://galaxynovels.com/novel/fey/chapter-580/',
            'date': 'يونيو 18, 2026',
            'content_api': '/reader/98239',
          },
          {
            'id': 98238,
            'label': 'الفصل 579',
            'title': 'ظل القفص',
            'url': 'https://galaxynovels.com/novel/fey/chapter-579/',
            'date': 'يونيو 17, 2026',
          },
        ],
      });

      expect(chapter.id, 98239);
      expect(chapter.novelId, 97656);
      expect(chapter.novelTitle, 'تاجر تطوير الوحوش');
      expect(chapter.label, 'الفصل 580');
      expect(chapter.title, 'صرخة الطائر');
      expect(chapter.dateLabel, 'يونيو 18, 2026');
      expect(chapter.url, 'https://galaxynovels.com/novel/fey/chapter-580/');
      expect(chapter.chapters, hasLength(2));
      expect(chapter.chapters.last.label, 'الفصل 579');
      expect(chapter.effectiveContentApi, '/reader/98239');
    },
  );

  test('HomeData unwraps public home pack data', () {
    final home = HomeData.fromJson({
      'schema': 1,
      'data': {
        'continue_reading': {
          'novel_title': 'ظلال المجرة',
          'chapter_label': 'الفصل 24',
          'cover_url': '/uploads/shadows.jpg',
          'cover': {
            'medium': '/uploads/shadows-medium.jpg',
            'large': '/uploads/shadows-large.jpg',
          },
          'progress': 68,
        },
        'latest_chapters': [
          {
            'id': 82,
            'novel_id': 12,
            'novel_title': 'حارس النجوم',
            'label': 'الفصل 82',
            'date': 'منذ 12 دقيقة',
            'url': '/chapter-82/',
          },
        ],
        'recent_novels': [
          {
            'id': 123,
            'title': 'بوابة الشمال',
            'genres': [
              {'name': 'خيال'},
            ],
            'chapters_count': 126,
          },
        ],
      },
    });

    expect(home.continueReading?.novelTitle, 'ظلال المجرة');
    expect(home.continueReading?.coverUrl, '/uploads/shadows-large.jpg');
    expect(home.latestChapters.single.novelTitle, 'حارس النجوم');
    expect(home.recentNovels.single.title, 'بوابة الشمال');
    expect(home.isEmpty, isFalse);
  });
}
