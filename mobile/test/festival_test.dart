import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';
import 'package:kexinglu_mobile/birthday.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/festival_calendar.dart';
import 'package:kexinglu_mobile/festival_ui.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  setUpAll(() async => CloudAccount.instance.initialize(configuration: {}));
  setUp(() {
    birthdayHomeVisible.value = true;
  });

  test('traditional festivals follow the 2026/2027 lunar calendar, not leave dates', () {
    final dates = <String, List<int>>{
      'eve': [2026, 2, 16],
      'spring': [2026, 2, 17],
      'lantern': [2026, 3, 3],
      'dragon_boat': [2026, 6, 19],
      'mid_autumn': [2026, 9, 25],
      'qingming': [2026, 4, 5],
      'winter': [2026, 12, 22],
    };
    for (final entry in dates.entries) {
      final d = entry.value;
      expect(
        FestivalCalendar.on(DateTime(d[0], d[1], d[2])).map((e) => e.id),
        contains(entry.key),
        reason: entry.key,
      );
    }
    expect(
      FestivalCalendar.on(DateTime(2026, 2, 15)).map((e) => e.id),
      isNot(contains('spring')),
    );
    expect(
      FestivalCalendar.on(DateTime(2027, 2, 6)).map((e) => e.id),
      contains('spring'),
    );
    expect(
      FestivalCalendar.on(DateTime(2027, 9, 15)).map((e) => e.id),
      contains('mid_autumn'),
    );
  });

  test('leap lunar fifth month does not duplicate Dragon Boat Festival', () {
    final leap = Lunar.fromYmd(2009, -5, 5).getSolar();
    expect(
      FestivalCalendar.on(
        DateTime(leap.getYear(), leap.getMonth(), leap.getDay()),
      ).map((e) => e.id),
      isNot(contains('dragon_boat')),
    );
  });
  test('movable world holidays and overlapping events are preserved', () {
    expect(
      FestivalCalendar.on(DateTime(2026, 5, 10)).map((e) => e.id),
      contains('mothers'),
    );
    expect(
      FestivalCalendar.on(DateTime(2026, 6, 21)).map((e) => e.id),
      contains('fathers'),
    );
    expect(
      FestivalCalendar.on(DateTime(2026, 11, 26)).map((e) => e.id),
      contains('thanksgiving'),
    );
    expect(FestivalCalendar.easterDate(2026), DateTime(2026, 4, 5));
    expect(
      FestivalCalendar.on(DateTime(2020, 10, 1)).map((e) => e.id),
      containsAll(['national', 'mid_autumn']),
    );
    expect(
      FestivalCalendar.on(DateTime(2026, 4, 5)).first.art,
      FestivalArt.quiet,
    );
  });
  test('international opt-out, ordinary days and time-of-day matching', () {
    expect(
      FestivalCalendar.on(DateTime(2026, 12, 25), international: false),
      isEmpty,
    );
    expect(
      FestivalCalendar.on(DateTime(2026, 10, 1), international: false).first.id,
      'national',
    );
    expect(FestivalCalendar.on(DateTime(2026, 10, 27)), isEmpty);
    expect(
      FestivalCalendar.on(DateTime(2026, 2, 17, 23, 59)).first.id,
      'spring',
    );
    expect(
      FestivalCalendar.dailyWish(DateTime(2026, 10, 27)),
      FestivalCalendar.dailyWish(DateTime(2026, 10, 27, 20)),
    );
    expect(
      FestivalCalendar.examples.map((e) => e.id).toSet().length,
      FestivalCalendar.examples.length,
    );
  });

  testWidgets('holiday splash shows once per owner/day and survives relaunch', (
    t,
  ) async {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final store = JournalStore.memory();
    var now = DateTime(2026, 1, 1, 12);
    Widget app() => MaterialApp(
      navigatorObservers: [birthdayRoutes],
      home: FestivalGate(
        store: store,
        clock: () => now,
        child: const Scaffold(body: Text('Home')),
      ),
    );
    await t.pumpWidget(app());
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('festival-splash')), findsOneWidget);
    expect(store.settings['festival_greeting_seen:guest'], '2026-1-1');
    await t.tap(find.byTooltip('跳过祝福'));
    await t.pump();
    expect(find.byKey(const ValueKey('festival-splash')), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(app());
    await t.pump();
    expect(find.byKey(const ValueKey('festival-splash')), findsNothing);
    now = DateTime(2026, 2, 17, 12);
    await store.setting('tick', true);
    await t.pump();
    await t.pump();
    expect(find.text('新岁启封'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 3100));
    await t.pump();
    expect(find.byKey(const ValueKey('festival-splash')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  for (final holidaysEnabled in [true, false]) {
    testWidgets(
      'birthday retains splash and daily confetti with holidays $holidaysEnabled',
      (t) async {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final store = JournalStore.memory();
        await store.setting('festival_greetings', holidaysEnabled);
        await store.setting('personal_profile:guest', {
          'birthday': '2000-02-17',
        });
        final now = DateTime(2026, 2, 17, 12);
        await t.pumpWidget(
          MaterialApp(
            navigatorObservers: [birthdayRoutes],
            home: BirthdayGate(
              store: store,
              clock: () => now,
              child: FestivalGate(
                store: store,
                clock: () => now,
                child: const Scaffold(body: Text('Home')),
              ),
            ),
          ),
        );
        await t.pump();
        await t.pump();
        expect(find.byKey(const ValueKey('birthday-splash')), findsOneWidget);
        expect(find.byKey(const ValueKey('festival-splash')), findsNothing);
        await t.pump(const Duration(milliseconds: 2300));
        await t.pump();
        expect(find.byType(BirthdayConfetti), findsOneWidget);
        expect(find.byKey(const ValueKey('festival-splash')), findsNothing);
        expect(store.settings['festival_greeting_seen:guest'], isNull);
        await t.pump(const Duration(seconds: 4));
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('hidden home does not consume the greeting before it renders', (
    t,
  ) async {
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    birthdayHomeVisible.value = false;
    final store = JournalStore.memory();
    await t.pumpWidget(
      MaterialApp(
        navigatorObservers: [birthdayRoutes],
        home: FestivalGate(
          store: store,
          clock: () => DateTime(2026, 1, 1, 12),
          child: const Scaffold(body: Text('Home')),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    expect(store.settings['festival_greeting_seen:guest'], isNull);
    birthdayHomeVisible.value = true;
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('festival-splash')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets(
    'previews and preferences do not mutate birthday or seen markers',
    (t) async {
      final store = JournalStore.memory();
      await store.setting('personal_profile:guest', {'birthday': '2000-02-17'});
      await t.pumpWidget(MaterialApp(home: FestivalCenter(store: store)));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('festival-enabled')));
      await t.pumpAndSettle();
      expect(store.settings['festival_greetings'], false);
      await t.scrollUntilVisible(find.byKey(const ValueKey('festival-preview-eve')), 150, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.byKey(const ValueKey('festival-preview-eve')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('festival-preview-eve')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.text('灯火可亲，岁岁相守'), findsOneWidget);
      expect(store.settings['festival_greeting_seen:guest'], isNull);
      expect(
        (store.settings['personal_profile:guest'] as Map)['birthday'],
        '2000-02-17',
      );
      await t.tap(find.text('返回节日手册'));
      await t.pumpAndSettle();
      expect(find.text('每日寄语与节日祝福'), findsOneWidget);
      expect(store.settings['festival_greetings'], false);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final size in [const Size(320, 568), const Size(640, 320)]) {
    for (final art in FestivalArt.values) {
      testWidgets('${art.name} fits $size with large text and reduced motion', (
        t,
      ) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final f = FestivalCalendar.examples.firstWhere((f) => f.art == art);
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.8)),
              child: child!,
            ),
            home: FestivalSplash(
              festival: f,
              onClose: () {},
              reduced: true,
              preview: true,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(f.title), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
