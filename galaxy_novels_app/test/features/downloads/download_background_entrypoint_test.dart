import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/data/download_background_entrypoint.dart';

void main() {
  test(
    'background cleanup closes the store when repository shutdown fails',
    () async {
      final failure = StateError('transfer failed while shutting down');
      var repositoryDisposed = false;
      var storeClosed = false;

      await expectLater(
        shutdownDownloadWorkerResources(
          shutdownRepository: () async => throw failure,
          disposeRepository: () => repositoryDisposed = true,
          closeStore: () async => storeClosed = true,
        ),
        throwsA(same(failure)),
      );

      expect(repositoryDisposed, isTrue);
      expect(storeClosed, isTrue);
    },
  );
}
