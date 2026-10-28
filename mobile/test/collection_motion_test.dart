import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/collection_screen.dart';
import 'package:kexinglu_mobile/look.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  testWidgets(
    'category changes and thumbnail jumps keep one pager and correct cards',
    (t) async {
      t.view.physicalSize = const Size(360, 780);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = JournalStore.memory();
      for (var i = 0; i < 3; i++) {
        await store.save(Entry('movie-$i', 'movie', {'title': '影片$i'}));
      }
      await store.save(Entry('food', 'food', {'title': '午后咖啡'}));
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionScreen(
              store: store,
              palette: AppPalette.all.last,
              reduced: true,
              photo: (e, {height}) => const ColoredBox(color: Colors.teal),
              card: (_) => const SizedBox(),
              onEdit: (_, {entry}) async {},
              onDetail: (_) async {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final controller = t.widget<PageView>(find.byType(PageView)).controller!;
      await t.tap(find.byTooltip(store.of('movie')[2].text('title')));
      await t.pumpAndSettle();
      expect(controller.page, 2);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text('食光小记'));
        await t.pumpAndSettle();
        expect(find.text('午后咖啡'), findsOneWidget);
        expect(controller.positions.length, 1);
        await t.tap(find.text('影视收藏'));
        await t.pumpAndSettle();
        expect(controller.page, 0);
        expect(controller.positions.length, 1);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  test('every palette has readable foreground on paper and background', () {
    for (final p in AppPalette.all) {
      for (final surface in [p.paper, p.background]) {
        final values = [p.ink.computeLuminance(), surface.computeLuminance()]
          ..sort();
        expect(
          (values.last + .05) / (values.first + .05),
          greaterThanOrEqualTo(4.5),
          reason: p.name,
        );
      }
    }
  });
}
