import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/look.dart';
import 'package:kexinglu_mobile/notebook.dart';
import 'package:kexinglu_mobile/notebook_motion.dart';
import 'package:kexinglu_mobile/privacy_page.dart';
import 'package:kexinglu_mobile/profile_pages.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => CloudAccount.instance.initialize(configuration: {}));
  Entry book() => Entry('folding-test', 'book', {
    'title': '沿途记录',
    'style': 0,
    'pages': [
      for (var i = 0; i < 3; i++)
        {
          'elements': [element('第${i + 1}页', y: .4)],
        },
    ],
  });
  void size(WidgetTester t, Size value) {
    t.view.physicalSize = value;
    t.view.devicePixelRatio = 1;
  }

  testWidgets(
    'about opens a bundled selectable privacy page with no website entry',
    (t) async {
      await t.pumpWidget(const MaterialApp(home: ProfileAboutScreen()));
      await t.pumpAndSettle();
      expect(find.text('客行录官网'), findsNothing);
      await t.scrollUntilVisible(find.text('隐私政策'), 120);
      await t.tap(find.text('隐私政策'));
      await t.pumpAndSettle();
      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.text('本地记录与个人资料'), findsOneWidget);
      await t.scrollUntilVisible(find.text('未成年人、更新与联系'), 350);
      expect(t.takeException(), isNull);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byType(ProfileAboutScreen), findsOneWidget);
    },
  );

  testWidgets('all four effects turn pages and preference survives reopening', (
    t,
  ) async {
    size(t, const Size(390, 844));
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final store = JournalStore.memory();
    Future<void> open() => t.pumpWidget(
      MaterialApp(
        home: NotebookEditor(
          store: store,
          book: book(),
          palette: AppPalette.all.first,
          reduced: false,
        ),
      ),
    );
    await open();
    await t.pumpAndSettle();
    for (final mode in NotebookTurn.values) {
      await t.tap(find.byKey(const ValueKey('notebook-turn-picker')));
      await t.pumpAndSettle();
      await t.tap(find.text(mode.label).last);
      await t.pumpAndSettle();
      expect(store.settings['notebook_turn'], mode.name);
      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('notebook-pages'))),
      );
      await gesture.moveBy(const Offset(-120, 0));
      await t.pump(const Duration(milliseconds: 120));
      expect(t.takeException(), isNull);
      await gesture.moveBy(const Offset(-140, 0));
      await gesture.up();
      await t.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        t.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, .001),
      );
      await t.drag(
        find.byKey(const ValueKey('notebook-pages')),
        const Offset(300, 0),
      );
      await t.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
    }
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    await open();
    await t.pumpAndSettle();
    expect(find.text('淡入'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'rotation preserves page and draft; landscape scroll and side tools are usable',
    (t) async {
      size(t, const Size(390, 844));
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = JournalStore.memory();
      await t.pumpWidget(
        MaterialApp(
          home: NotebookEditor(
            store: store,
            book: book(),
            palette: AppPalette.all.first,
            reduced: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const ValueKey('notebook-pages')),
        const Offset(-300, 0),
      );
      await t.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        t.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, .001),
      );
      await t.tap(find.byTooltip('自由编辑'));
      await t.pumpAndSettle();
      await t.tap(find.text('✦'));
      await t.pumpAndSettle();
      size(t, const Size(844, 390));
      await t.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        t.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, .001),
      );
      expect(
        find.byKey(const ValueKey('notebook-landscape-tools')),
        findsOneWidget,
      );
      expect(
        t.getRect(find.byKey(const ValueKey('music-record'))).right,
        lessThan(
          t
              .getRect(find.byKey(const ValueKey('notebook-landscape-tools')))
              .left,
        ),
      );
      final scroll = find
          .descendant(
            of: find.byKey(const ValueKey('notebook-landscape-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      final state = t.state<ScrollableState>(scroll);
      await t.drag(
        find.byKey(const ValueKey('notebook-landscape-scroll')),
        const Offset(0, -150),
      );
      await t.pumpAndSettle();
      expect(state.position.pixels, greaterThan(0));
      await t.tap(find.text('保存'));
      await t.pumpAndSettle();
      expect(
        (store.of('book').single.data['pages'][1]['elements'] as List).length,
        2,
      );
      size(t, const Size(390, 844));
      await t.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(
        t.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, .001),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
