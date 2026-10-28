// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/poster_search.dart';

void main() {
  test(
    'live poster sources and images',
    () async {
      for (final q in [
        'Inception',
        '琅琊榜',
        '流浪地球',
        '狂飙',
        '庆余年',
        '葬送的芙莉莲',
        'Breaking Bad',
      ]) {
        final watch = Stopwatch()..start();
        final report = await PosterSearch.search(q, refresh: true);
        print(
          '$q: ${report.results.map((p) => p.title).toList()} (${watch.elapsedMilliseconds} ms), failures: ${report.failures}',
        );
        expect(report.results, isNotEmpty, reason: q);
        var usable = false;
        for (final poster in report.results.take(3)) {
          try {
            final image = await PosterSearch.load(poster);
            print('${poster.source}: ${image.width} x ${image.height}');
            usable = image.width > 200;
            image.dispose();
            if (usable) break;
          } catch (e) {
            print('Image unavailable ${poster.source}: $e');
          }
        }
        expect(usable, isTrue, reason: 'No usable image for $q');
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: !const bool.fromEnvironment('POSTER_LIVE'),
  );
}
