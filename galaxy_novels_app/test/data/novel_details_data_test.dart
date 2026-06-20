import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';

void main() {
  test('parses novel details data from pack data', () {
    final details = NovelDetails.fromJson({
      'id': 120429,
      'title': 'إمبراطوريتي البريطانية',
      'original_title': 'My British Empire',
      'url': '/novel/my-british-empire/',
      'cover': {
        'thumbnail': '/thumb.webp',
        'medium': '/medium.webp',
        'large': '/large.webp',
      },
      'status': {'key': 'ongoing', 'label': 'مستمرة'},
      'country': 'cn',
      'author': 'Fei Tian Lan Che',
      'translator': 'ISRAWATAN',
      'genres': [
        {'id': 8, 'name': 'تاريخي', 'slug': 'history'},
      ],
      'chapters_count': 127,
      'first_chapter_id': 122597,
      'first_chapter_url': '/chapter-1/',
      'rating': {'average': 4.5, 'count': 12},
      'stats': {'views': 525},
      'updated_at': '2026-06-16T12:12:29+03:00',
      'summary': 'ملخص طويل للرواية',
      'links': {
        'chapters_manifest': '/chapters/manifest.json',
        'vip_schedule_manifest': '/vip/manifest.json',
      },
      'manifest': '/novel-manifest.json',
    });

    expect(details.id, 120429);
    expect(details.title, 'إمبراطوريتي البريطانية');
    expect(details.originalTitle, 'My British Empire');
    expect(details.coverLarge, '/large.webp');
    expect(details.bestCover, '/large.webp');
    expect(details.statusLabel, 'مستمرة');
    expect(details.author, 'Fei Tian Lan Che');
    expect(details.translator, 'ISRAWATAN');
    expect(details.genres.single.name, 'تاريخي');
    expect(details.chaptersCount, 127);
    expect(details.firstChapterUrl, '/chapter-1/');
    expect(details.ratingAverage, 4.5);
    expect(details.ratingCount, 12);
    expect(details.views, 525);
    expect(details.summary, 'ملخص طويل للرواية');
    expect(details.chaptersManifest, '/chapters/manifest.json');
  });

  test('parses chapter manifest pack url', () {
    final manifest = ChapterManifest.fromJson({
      'novel_id': 120429,
      'total': 127,
      'latest_id': 122723,
      'latest_number': '127',
      'pack_url': 'https://example.com/chapters.json',
    });

    expect(manifest.novelId, 120429);
    expect(manifest.total, 127);
    expect(manifest.latestNumber, '127');
    expect(manifest.packUrl, 'https://example.com/chapters.json');
  });

  test('parses chapter pack object with chapters field', () {
    final pack = ChapterPack.fromJsonValue({
      'total': 2,
      'chapters': [
        {
          'id': 1,
          'position': 1,
          'number': '1',
          'label': 'الفصل 1',
          'title': 'البداية',
          'url': 'https://example.com/chapter-1/',
          'date': 'يونيو 17, 2026',
          'date_iso': '2026-06-18T00:14:09+03:00',
          'content_api': '/wp-json/wor-reader-app/v1/chapters/1',
          'views': 7,
          'comments': 2,
          'search': '1 الفصل 1 البداية',
        },
      ],
    });

    expect(pack.total, 2);
    expect(pack.chapters.single.id, 1);
    expect(pack.chapters.single.displayTitle, 'البداية');
    expect(
      pack.chapters.single.contentApi,
      '/wp-json/wor-reader-app/v1/chapters/1',
    );
    expect(pack.chapters.single.dateLabel, 'يونيو 17, 2026');
  });

  test('parses chapter pack top-level array', () {
    final pack = ChapterPack.fromJsonValue([
      {'id': 5, 'position': 5, 'label': 'الفصل 5', 'url': '/chapter-5/'},
    ]);

    expect(pack.total, 1);
    expect(pack.chapters.single.position, 5);
    expect(pack.chapters.single.label, 'الفصل 5');
  });

  test('uses safe defaults for missing fields', () {
    final details = NovelDetails.fromJson({'id': 7, 'title': 'ناقصة'});
    final chapter = NovelChapter.fromJson({'id': 1});

    expect(details.title, 'ناقصة');
    expect(details.coverLarge, '');
    expect(details.bestCover, '');
    expect(details.genres, isEmpty);
    expect(details.chaptersManifest, '');
    expect(chapter.label, '');
    expect(chapter.displayTitle, '');
    expect(chapter.url, '');
  });
}
