import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/atlas.dart';
import 'package:kexinglu_mobile/collection_screen.dart';
import 'package:kexinglu_mobile/editor.dart';
import 'package:kexinglu_mobile/i18n.dart';
import 'package:kexinglu_mobile/journal_navigation.dart';
import 'package:kexinglu_mobile/look.dart';
import 'package:kexinglu_mobile/profile_pages.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  tearDown(() => AppLanguage.current = 'zh');
  testWidgets('navigation exposes native accessibility tap actions', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalNavigation(
            selected: 0,
            onSelected: (_) {},
            palette: AppPalette.all.first,
            reduced: true,
            motion: NavigationMotion.glide,
            pulses: List.filled(5, 0),
          ),
        ),
      ),
    );
    for (final label in ['首页', '旅途', '票夹', '收藏', '我的']) {
      expect(
        t
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }
    semantics.dispose();
  });
  for (final width in [360.0, 1440.0]) {
    testWidgets('settings maintains a readable width in a $width window', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(home: ProfileSettingsScreen(store: JournalStore.memory())),
      );
      await t.pumpAndSettle();
      expect(
        t
            .getSize(find.byKey(const ValueKey('settings-responsive-width')))
            .width,
        width < 840 ? width : 840,
      );
      expect(t.takeException(), isNull);
    });
  }
  for (final motion in NavigationMotion.values) {
    testWidgets(
      '${motion.name} indicator travels in both directions and accepts dragging',
      (t) async {
        var selected = 0;
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: StatefulBuilder(
                    builder: (context, set) => JournalNavigation(
                      selected: selected,
                      onSelected: (i) => set(() => selected = i),
                      palette: AppPalette.all.first,
                      reduced: false,
                      motion: motion,
                      pulses: List.filled(5, 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final pill = find.byKey(const ValueKey('navigation-moving-pill'));
        final start = t.getCenter(pill).dx;
        await t.tap(find.byKey(const ValueKey('navigation-tab-4')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 140));
        final mid = t.getCenter(pill).dx;
        expect(mid, greaterThan(start));
        await t.pumpAndSettle();
        final end = t.getCenter(pill).dx;
        expect(end, greaterThan(mid));
        await t.tap(find.byKey(const ValueKey('navigation-tab-0')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 140));
        expect(t.getCenter(pill).dx, lessThan(end));
        await t.pumpAndSettle();
        await t.drag(find.byType(JournalNavigation), const Offset(210, 0));
        await t.pumpAndSettle();
        expect(selected, greaterThanOrEqualTo(2));
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('reduced motion places indicator immediately', (t) async {
    var selected = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => JournalNavigation(
              selected: selected,
              onSelected: (i) => set(() => selected = i),
              palette: AppPalette.all.first,
              reduced: true,
              motion: NavigationMotion.spring,
              pulses: List.filled(5, 0),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('navigation-tab-4')));
    await t.pump();
    expect(
      t.getCenter(find.byKey(const ValueKey('navigation-moving-pill'))).dx,
      greaterThan(650),
    );
    await t.pumpAndSettle();
  });
  testWidgets(
    'new collection ratings default to five and existing ratings are retained',
    (t) async {
      final atlas = AtlasData();
      for (final kind in ['movie', 'food']) {
        for (final rating in [null, 2]) {
          await t.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RecordEditor(
                  key: UniqueKey(),
                  store: JournalStore.memory(),
                  atlas: atlas,
                  kind: kind,
                  entry: rating == null
                      ? null
                      : Entry('existing', kind, {'rating': rating}),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
            find.byType(Slider),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            t.widget<Slider>(find.byType(Slider)).value,
            rating?.toDouble() ?? 5,
          );
        }
      }
    },
  );
  testWidgets(
    'film cover contains title and cast without poster metadata or date',
    (t) async {
      final store = JournalStore.memory();
      await store.save(
        Entry('film', 'movie', {
          'title': '海街日记',
          'actors': '绫濑遥 / 长泽雅美 / 夏帆',
          'date': '2026-10-25',
          'posterSource': '豆瓣',
          'posterUrl': 'https://movie.douban.com/subject/1/',
        }),
      );
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionScreen(
              store: store,
              palette: AppPalette.all.first,
              reduced: true,
              photo: (_, {height}) => const ColoredBox(color: Colors.teal),
              card: (_) => const SizedBox(),
              onEdit: (_, {entry}) async {},
              onDetail: (_) async {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('海街日记'), findsWidgets);
      expect(find.text('绫濑遥 / 长泽雅美 / 夏帆'), findsOneWidget);
      expect(find.textContaining('海报：'), findsNothing);
      expect(find.textContaining('轻触查看感悟'), findsNothing);
      expect(find.text('2026-10-25'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'settings language sheet and navigation choices persist at large text size',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = JournalStore.memory();
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: ProfileSettingsScreen(store: store),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('settings-language')),
        260,
      );
      await t.tap(find.byKey(const ValueKey('settings-language')));
      await t.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('简体中文'), findsWidgets);
      expect(find.text('日本語'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('language-option-ja')));
      await t.pumpAndSettle();
      expect(store.settings['language'], 'ja');
      for (final motion in NavigationMotion.values) {
        await t.scrollUntilVisible(
          find.byKey(ValueKey('navigation-motion-${motion.name}')),
          180,
        );
        await t.ensureVisible(
          find.byKey(ValueKey('navigation-motion-${motion.name}')),
        );

        await t.pumpAndSettle();

        await t.tap(find.byKey(ValueKey('navigation-motion-${motion.name}')));
        await t.pumpAndSettle();
        expect(store.settings['navigation_motion'], motion.name);
        await t.scrollUntilVisible(find.byType(JournalNavigation), -180);
        expect(
          t.widget<JournalNavigation>(find.byType(JournalNavigation)).motion,
          motion,
        );
        expect(t.takeException(), isNull);
      }
    },
  );
}
