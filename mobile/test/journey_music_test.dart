import 'support/test_audio.dart';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/journey_music.dart';
import 'package:kexinglu_mobile/store.dart';
import 'package:kexinglu_mobile/birthday.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => CloudAccount.instance.initialize(configuration: {}));
  late TestAudioPlatform audio;
  int getPlays() => audio.plays;
  setUp(() {
    audio = TestAudioPlatform();
    JustAudioPlatform.instance = audio;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (_) async => null,
        );
  });
  test('all bundled music and grouped backgrounds exist offline', () {
    expect(journeyTracks.length, 12);
    for (final track in journeyTracks.keys) {
      expect(File('assets/audio/$track.mp3').lengthSync(), greaterThan(10000));
    }
    final grouped = profileCoverGroups.values.expand((v) => v).toList();
    expect(grouped.toSet().length, grouped.length);
    expect(grouped.toSet(), profileCovers.keys.toSet());
    for (final cover in grouped) {
      expect(File('assets/backgrounds/$cover').existsSync(), isTrue);
    }
  });
  testWidgets(
    'selection autoplays on selection and reopening; empty journals stay silent',
    (t) async {
      final store = JournalStore.memory();
      store.settings['reduced'] = true;
      Future<void> open(String id) async {
        await t.runAsync(() async {
          await t.pumpWidget(
            MaterialApp(
              navigatorObservers: [birthdayRoutes],
              home: Scaffold(
                body: JourneyMusic(
                  key: ValueKey(id),
                  store: store,
                  journalId: id,
                ),
              ),
            ),
          );
          await t.pump();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('music-record')));
        await t.pumpAndSettle();
      }

      await open('first');
      await t.tap(find.byTooltip('选择背景音乐'));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(find.text('林间晨光'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await t.pumpAndSettle();
      expect(find.text('林间晨光'), findsOneWidget);
      expect(find.byTooltip('暂停音乐'), findsOneWidget);
      expect(getPlays(), 1);
      expect(
        (store.settings['journey_music:guest:first'] as Map)['source'],
        'asset:morning',
      );
      await t.runAsync(() async {
        await t.tap(find.byTooltip('暂停音乐'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('选择背景音乐'));
      await t.pumpAndSettle();
      Navigator.of(t.element(find.text('旅途随身听'))).pop();
      await t.pumpAndSettle();
      expect(find.byTooltip('暂停音乐'), findsNothing);
      final count = getPlays();
      await open('second');
      expect(getPlays(), count);
      expect(find.text('为这段旅程选一首配乐。'), findsOneWidget);
      await open('first');
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await t.pumpAndSettle();
      expect(getPlays(), greaterThan(count));
      expect(find.byTooltip('暂停音乐'), findsOneWidget);
      expect(find.text('林间晨光'), findsOneWidget);
      await t.tap(find.byTooltip('选择背景音乐'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('移除本页配乐'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await t.ensureVisible(find.text('移除本页配乐'));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(find.text('移除本页配乐'));
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await t.pumpAndSettle();
      expect(
        (store.settings['journey_music:guest:first'] as Map)['source'],
        '',
      );
      expect(store.entries, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
}
