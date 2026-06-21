import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/repositories/downloads_repository.dart';
import 'package:galaxy_novels_app/features/downloads/presentation/download_progress_overlay.dart';

void main() {
  testWidgets('shows active batch download progress', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: DownloadProgressOverlay(
          progress: const DownloadBatchProgress(
            novelTitle: 'رواية الاختبار',
            novelCover: '',
            total: 10,
            completed: 3,
            failed: 0,
            isComplete: false,
          ),
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('جاري تنزيل الفصول'), findsOneWidget);
    expect(find.text('جاري تحميل 3 من 10'), findsOneWidget);
    expect(find.text('3 / 10'), findsOneWidget);
  });

  testWidgets('shows completed progress with failed count', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: DownloadProgressOverlay(
          progress: const DownloadBatchProgress(
            novelTitle: 'رواية الاختبار',
            novelCover: '',
            total: 10,
            completed: 8,
            failed: 2,
            isComplete: true,
          ),
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('اكتمل التنزيل'), findsOneWidget);
    expect(find.text('تم تحميل 8 فصل، وفشل 2'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }
}
