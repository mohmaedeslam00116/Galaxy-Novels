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

  test('uses safe defaults for missing rankings fields', () {
    final rankings = RankingsData.fromJson({});

    expect(rankings.period, '');
    expect(rankings.items, isEmpty);
  });
}
