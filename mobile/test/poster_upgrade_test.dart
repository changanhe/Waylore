import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/poster_search.dart';
import 'package:kexinglu_mobile/poster_crop.dart';
import 'package:kexinglu_mobile/motion.dart';

void main() {
  test('Chinese alias discovers original poster and excludes people', () {
    final rows = PosterSearch.doubanResults([
      {
        'type': 'movie',
        'title': '绝命毒师',
        'sub_title': 'Breaking Bad',
        'img':
            'https://img3.doubanio.com/view/photo/s_ratio_poster/public/a.jpg',
        'url': 'https://movie.douban.com/subject/1/',
        'year': '2008',
      },
      {
        'type': 'celebrity',
        'title': 'Breaking Bad',
        'img': 'https://example.com/person.jpg',
        'url': 'https://movie.douban.com/celebrity/2/',
      },
    ], 'Breaking Bad');
    expect(rows, hasLength(1));
    expect(rows.single.image, contains('/r/'));
    expect(rows.single.preview, contains('/s_ratio_poster/'));
    expect(rows.single.title, contains('2008'));
  });
  test('Bangumi matches Chinese aliases and chooses large artwork', () {
    final rows = PosterSearch.bangumiResults({
      'list': [
        {
          'type': 2,
          'id': 3,
          'name': '葬送のフリーレン',
          'name_cn': '葬送的芙莉莲',
          'images': {
            'large': 'https://lain.bgm.tv/large.jpg',
            'medium': 'https://lain.bgm.tv/medium.jpg',
          },
        },
      ],
    }, '葬送的芙莉莲');
    expect(rows.single.image, endsWith('large.jpg'));
    expect(rows.single.preview, endsWith('medium.jpg'));
  });
  test(
    'TVmaze uses original rather than thumbnail and rejects unrelated titles',
    () {
      final rows = PosterSearch.tvmazeResults([
        {
          'show': {
            'name': 'Breaking Bad',
            'premiered': '2008-01-01',
            'url': 'https://www.tvmaze.com/shows/169',
            'image': {
              'original': 'https://static.tvmaze.com/original.jpg',
              'medium': 'https://static.tvmaze.com/small.jpg',
            },
          },
        },
      ], 'Breaking Bad');
      expect(rows.single.image, endsWith('original.jpg'));
      expect(
        PosterSearch.tvmazeResults([
          {
            'show': {'name': 'Other'},
          },
        ], 'Breaking Bad'),
        isEmpty,
      );
      expect(PosterSearch.httpsImage('javascript:alert(1)'), isEmpty);
    },
  );
  test('portrait crop stays inside the source at all drag and zoom limits', () {
    for (final size in [
      const Size(1920, 1080),
      const Size(600, 1800),
      const Size(1000, 1500),
    ]) {
      for (final offset in [
        const Offset(-9, -9),
        Offset.zero,
        const Offset(9, 9),
      ]) {
        for (final z in [1.0, 2.5]) {
          final crop = posterCropRect(size, offset: offset, zoom: z);
          expect(crop.width / crop.height, closeTo(2 / 3, .00001));
          expect(crop.left, greaterThanOrEqualTo(0));
          expect(crop.top, greaterThanOrEqualTo(0));
          expect(crop.right, lessThanOrEqualTo(size.width + .001));
          expect(crop.bottom, lessThanOrEqualTo(size.height + .001));
        }
      }
    }
  });
  testWidgets(
    'crop controls remain reachable in landscape and cancel without selecting',
    (t) async {
      t.view.physicalSize = const Size(844, 390);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final r = ui.PictureRecorder();
      Canvas(r).drawRect(
        const Rect.fromLTWH(0, 0, 600, 900),
        Paint()..color = Colors.blue,
      );
      final picture = r.endRecording();
      final image = await t.runAsync(() => picture.toImage(600, 900));
      picture.dispose();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PosterCropSheet(image: image!, title: '测试影片'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(
        find.text('使用这张海报'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      expect(t.takeException(), isNull);
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('取消'));
      await t.pumpAndSettle();
      expect(find.byType(PosterCropSheet), findsNothing);
      image!.dispose();
    },
  );
  testWidgets(
    'press feedback yields to scrolling and respects reduced motion',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PressFeedback(
              child: SizedBox(width: 200, height: 200, child: Text('tap')),
            ),
          ),
        ),
      );
      final gesture = await t.startGesture(
        t.getCenter(find.byType(PressFeedback)),
      );
      await t.pump();
      expect(
        t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1),
      );
      await gesture.moveBy(const Offset(20, 0));
      await t.pump();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PressFeedback(
              reduced: true,
              child: SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(find.byType(PressFeedback)));
      await t.pump();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await g.up();
    },
  );
}
