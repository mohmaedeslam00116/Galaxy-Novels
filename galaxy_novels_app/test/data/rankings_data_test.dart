import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/rankings_data.dart';

void main() {
  test('parses rankings pack with catalog-shaped novels', () {
    final rankings = RankingsData.fromJson({
      'period': 'month',
      'items': [
        {
          'id': 77,
          'title': 'متصدر الاختبار',
          'cover': {'thumbnail': '/thumb.jpg', 'medium': '/medium.jpg'},
          'status': {'key': 'ongoing', 'label': 'مستمرة'},
          'genres': [
            {'id': 1, 'name': 'أكشن', 'slug': 'action'},
          ],
          'chapters_count': 150,
          'rating': {'average': 4.8, 'count': 22},
          'stats': {'views': 15000},
          'manifest': '/manifest/novel-77.json',
        },
      ],
    });

    expect(rankings.period, 'month');
    expect(rankings.items, hasLength(1));
    expect(rankings.items.single.title, 'متصدر الاختبار');
    expect(rankings.items.single.views, 15000);
    expect(rankings.items.single.chaptersCount, 150);
    expect(rankings.items.single.statusLabel, 'مستمرة');
  });

  test('parses live rankings pack wrapped inside data', () {
    final rankings = RankingsData.fromJson({
      'schema': 1,
      'generated': 1782769592,
      'data': {
        'period': 'month',
        'items': [
          {
            'id': 69562,
            'title': 'رواية من الترتيب المباشر',
            'cover': {
              'thumbnail': '/wp-content/uploads/cover-150x150.webp',
              'medium': '/wp-content/uploads/cover-225x300.webp',
            },
            'status': {'key': 'ongoing', 'label': 'مستمرة'},
            'genres': [
              {'id': 2, 'name': 'أكشن', 'slug': 'action'},
            ],
            'chapters_count': 400,
            'rating': {'average': 0, 'count': 0},
            'stats': {'views': 69719},
            'manifest':
                '/wp-content/uploads/wor-reader-cache/app/manifest/novel-69562.json',
          },
        ],
      },
    });

    expect(rankings.period, 'month');
    expect(rankings.items, hasLength(1));
    expect(rankings.items.single.title, 'رواية من الترتيب المباشر');
    expect(rankings.items.single.views, 69719);
    expect(rankings.items.single.chaptersCount, 400);
  });

  test('uses safe defaults for missing rankings fields', () {
    final rankings = RankingsData.fromJson({});

    expect(rankings.period, '');
    expect(rankings.items, isEmpty);
  });
}
