import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/journal_stickers.dart';
import 'package:kexinglu_mobile/notebook.dart';
import 'package:kexinglu_mobile/look.dart';
import 'package:kexinglu_mobile/store.dart';
import 'package:kexinglu_mobile/cloud_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => CloudAccount.instance.initialize(configuration: {}));
  test('all original stickers have unique portable IDs and offline assets', () {
    expect(journalStickers.length, 38);
    expect(journalStickers.map((s) => s.id).toSet().length, 38);
    expect(journalStickers.map((s) => s.group).toSet().length, 6);
    for (final sticker in journalStickers) {
      expect(File(sticker.asset).readAsStringSync(), contains('<svg'));
      expect(journalSticker(sticker.value), same(sticker));
    }
    expect(journalSticker('decal:../../private'), isNull);
  });
  test(
    'new stickers and latest paper styles roundtrip through backup',
    () async {
      final store = JournalStore.memory();
      await store.save(
        Entry('originals', 'book', {
          'title': '素材测试',
          'style': 11,
          'pages': [
            {
              'elements': [
                element('decal:bunny', kind: 'sticker'),
                element('★', kind: 'sticker'),
              ],
            },
          ],
        }),
      );
      final backup = await store.backup();
      expect(backup['photos'], isEmpty);
      final restored = JournalStore.memory();
      await restored.restore(backup);
      expect(restored.of('book').single.data, store.of('book').single.data);
    },
  );
  testWidgets('all SVG designs render with genuine transparent edges', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: [
                for (final s in journalStickers)
                  SizedBox(width: 90, height: 90, child: stickerArt(s)),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    final html = await stickerExportImage(journalStickers.first);
    final encoded = html.split('base64,')[1].split('"')[0];
    expect(utf8.decode(base64Decode(encoded)), contains('<svg'));
  });
  testWidgets(
    'studio inserts, duplicates and saves vector stickers beside old emoji',
    (t) async {
      final store = JournalStore.memory();
      final book = Entry('studio', 'book', {
        'title': '贴纸测试',
        'style': 0,
        'pages': [
          {
            'elements': [element('★', kind: 'sticker')],
          },
        ],
      });
      await t.pumpWidget(
        MaterialApp(
          home: NotebookEditor(
            store: store,
            book: book,
            palette: AppPalette.all.first,
            reduced: true,
            fresh: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('sticker-studio')));
      await t.pumpAndSettle();
      await t.tap(find.text('奶糖兔'));
      await t.pumpAndSettle();
      await t.tap(find.text('完成'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('复制素材'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('移到最上层'));
      await t.pumpAndSettle();
      await t.tap(find.text('保存'));
      await t.pumpAndSettle();
      final elements =
          store.of('book').single.data['pages'][0]['elements'] as List;
      expect(elements.length, 3);
      expect(elements.where((e) => e['text'] == 'decal:bunny').length, 2);
      expect(elements.map((e) => e['id']).toSet().length, 3);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'horizontal swipe on a sticker card changes group without inserting',
    (t) async {
      var inserted = 0;
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StickerStudio(onInsert: (_) => inserted++)),
        ),
      );
      await t.pumpAndSettle();
      await t.drag(find.text('奶糖兔'), const Offset(-290, 0));
      await t.pumpAndSettle();
      expect(find.text('旅行相机'), findsOneWidget);
      expect(inserted, 0);
      await t.tap(find.byTooltip('下一组素材'));
      await t.pumpAndSettle();
      expect(find.text('晴日雏菊'), findsOneWidget);
      await t.tap(find.byTooltip('上一组素材'));
      await t.pumpAndSettle();
      expect(find.text('旅行相机'), findsOneWidget);
      await t.tap(find.text('旅行相机'));
      await t.pumpAndSettle();
      expect(inserted, 1);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'quick stickers scroll in both directions without starting a drag',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = JournalStore.memory();
      final book = Entry('swipe', 'book', {
        'title': '滑动测试',
        'style': 0,
        'pages': [
          {'elements': <dynamic>[]},
        ],
      });
      await t.pumpWidget(
        MaterialApp(
          home: NotebookEditor(
            store: store,
            book: book,
            palette: AppPalette.all.first,
            reduced: true,
            fresh: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      final strip = find.byKey(const ValueKey('quick-sticker-scroll'));
      final scroll = t.state<ScrollableState>(
        find.descendant(of: strip, matching: find.byType(Scrollable)),
      );
      await t.dragFrom(t.getCenter(find.text('✦')), const Offset(-230, 0));
      await t.pumpAndSettle();
      final advanced = scroll.position.pixels;
      expect(advanced, greaterThan(100));
      await t.drag(strip, const Offset(160, 0));
      await t.pumpAndSettle();
      expect(scroll.position.pixels, lessThan(advanced));
      expect(find.byType(Draggable<String>), findsNothing);
      await t.tap(find.text('保存'));
      await t.pumpAndSettle();
      expect(store.of('book').single.data['pages'][0]['elements'], isEmpty);
      final visible = find
          .descendant(of: strip, matching: find.byType(Text))
          .hitTestable()
          .first;
      final gesture = await t.startGesture(t.getCenter(visible));
      await t.pump(const Duration(milliseconds: 400));
      await gesture.moveTo(t.getCenter(find.byType(DragTarget<String>)));
      await t.pump();
      await gesture.up();
      await t.pumpAndSettle();
      await t.tap(find.text('保存'));
      await t.pumpAndSettle();
      expect(
        store.of('book').single.data['pages'][0]['elements'],
        hasLength(1),
      );
      expect(t.takeException(), isNull);
    },
  );
  for (final size in [const Size(320, 568), const Size(640, 320)]) {
    testWidgets('studio remains usable at $size with larger text', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.4),
            ),
            child: Scaffold(body: StickerStudio(onInsert: (_) {})),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
