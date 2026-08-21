import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/novel_details_data.dart';
import 'package:galaxy_novels_app/features/novel_details/domain/readable_chapter.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';

void main() {
  test('merges public and VIP chapters in reading order', () {
    final chapters = mergeReadableChapters(
      publicChapters: [_publicChapter(1), _publicChapter(2)],
      vipChapters: [_vipChapter(3), _vipChapter(4)],
    );

    expect(chapters.map((chapter) => chapter.label), [
      'الفصل 1',
      'الفصل 2',
      'الفصل 3',
      'الفصل 4',
    ]);
    expect(chapters.map((chapter) => chapter.isVip), [
      false,
      false,
      true,
      true,
    ]);
  });

  test('prefers public chapters when a VIP chapter has become public', () {
    final chapters = mergeReadableChapters(
      publicChapters: [_publicChapter(10)],
      vipChapters: [_vipChapter(10)],
    );

    expect(chapters, hasLength(1));
    expect(chapters.single.isVip, isFalse);
    expect(
      chapters.single.contentApi,
      '/wp-json/wor-reader-app/v1/chapters/10',
    );
  });

  test('paginates merged chapters into fixed fifty item pages', () {
    final chapters = mergeReadableChapters(
      publicChapters: List.generate(125, (index) => _publicChapter(index + 1)),
      vipChapters: [_vipChapter(126), _vipChapter(127)],
    );

    expect(chapterPageCount(chapters), 3);
    expect(chapterPageItems(chapters, 0), hasLength(50));
    expect(chapterPageItems(chapters, 1).first.label, 'الفصل 51');
    expect(chapterPageItems(chapters, 2).map((chapter) => chapter.label), [
      'الفصل 101',
      'الفصل 102',
      'الفصل 103',
      'الفصل 104',
      'الفصل 105',
      'الفصل 106',
      'الفصل 107',
      'الفصل 108',
      'الفصل 109',
      'الفصل 110',
      'الفصل 111',
      'الفصل 112',
      'الفصل 113',
      'الفصل 114',
      'الفصل 115',
      'الفصل 116',
      'الفصل 117',
      'الفصل 118',
      'الفصل 119',
      'الفصل 120',
      'الفصل 121',
      'الفصل 122',
      'الفصل 123',
      'الفصل 124',
      'الفصل 125',
      'الفصل 126',
      'الفصل 127',
    ]);
  });

  test('filters readable chapters in Arabic and reverses the result', () {
    final chapters = mergeReadableChapters(
      publicChapters: [
        _publicChapter(1, title: 'البداية'),
        _publicChapter(2, title: 'السر الغامض'),
      ],
      vipChapters: const [],
    );

    expect(
      readableChaptersForDisplay(
        chapters,
        query: 'غامض',
        descending: false,
      ).map((chapter) => chapter.number),
      ['2'],
    );
    expect(
      readableChaptersForDisplay(
        chapters,
        query: '',
        descending: true,
      ).map((chapter) => chapter.number),
      ['2', '1'],
    );
  });

  test('selects every readable chapter inside an inclusive position range', () {
    final chapters = mergeReadableChapters(
      publicChapters: List.generate(60, (index) => _publicChapter(index + 1)),
      vipChapters: const [],
    );

    final selected = readableChaptersInPositionRange(
      chapters,
      start: 11,
      end: 50,
    );

    expect(selected, hasLength(40));
    expect(selected.first.number, '11');
    expect(selected.last.number, '50');
  });

  test('does not open VIP chapters through the wrong public next fallback', () {
    final chapters = mergeReadableChapters(
      publicChapters: [_publicChapter(274)],
      vipChapters: [_vipChapter(275)],
    );

    expect(
      readableChapterOpenContentApi(
        chapters,
        1,
        directVipChapterRouteAvailable: false,
      ),
      isEmpty,
    );
  });

  test('keeps direct VIP content APIs when the direct route is available', () {
    final chapters = mergeReadableChapters(
      publicChapters: [_publicChapter(274)],
      vipChapters: [_vipChapter(275)],
    );

    expect(
      readableChapterOpenContentApi(
        chapters,
        1,
        directVipChapterRouteAvailable: true,
      ),
      '/wp-json/wor-reader-app/v1/vip/chapters/1275',
    );
  });

  test(
    'cannot open the first VIP chapter without a previous chapter fallback',
    () {
      final chapters = mergeReadableChapters(
        publicChapters: const [],
        vipChapters: [_vipChapter(1)],
      );

      expect(
        readableChapterOpenContentApi(
          chapters,
          0,
          directVipChapterRouteAvailable: false,
        ),
        isEmpty,
      );
    },
  );
}

NovelChapter _publicChapter(int number, {String? title}) {
  return NovelChapter(
    id: number,
    position: number,
    number: '$number',
    label: 'الفصل $number',
    title: title ?? 'عنوان الفصل $number',
    url: '/chapter-$number/',
    contentApi: '/wp-json/wor-reader-app/v1/chapters/$number',
    dateLabel: '',
    dateIso: null,
    views: 0,
    comments: 0,
    search: '',
  );
}

VipChapter _vipChapter(int number) {
  return VipChapter(
    id: number + 1000,
    number: '$number',
    position: number,
    order: '$number.000000',
    title: 'VIP $number',
    url: '',
    publicAt: '',
    views: 0,
    comments: 0,
    contentApi: '/wp-json/wor-reader-app/v1/vip/chapters/${number + 1000}',
  );
}
