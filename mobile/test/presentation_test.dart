import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:kexinglu_mobile/feedback.dart';
import 'package:kexinglu_mobile/journey_music.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/store.dart';
import 'package:kexinglu_mobile/profile_pages.dart';
import 'package:kexinglu_mobile/festival_ui.dart';

import 'support/test_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => CloudAccount.instance.initialize(configuration: {}));
  testWidgets(
    'top deletion notice leaves navigation usable, supports undo and expires',
    (t) async {
      final store = JournalStore.memory();
      final entry = Entry('notice', 'movie', {'title': '测试收藏'});
      await store.save(entry);
      var navigated = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) => Stack(
                children: [
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await store.remove(entry);
                        if (c.mounted) {
                          showJournalMessage(
                            c,
                            SnackBar(
                              content: const Text('收藏已删除'),
                              action: SnackBarAction(
                                label: '撤销',
                                onPressed: () => store.save(entry),
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('删除'),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: TextButton(
                      onPressed: () => navigated++,
                      child: const Text('导航'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('删除'));
      await t.pumpAndSettle();
      expect(store.entries, isEmpty);
      final notice = t.getRect(find.byKey(const ValueKey('journal-notice')));
      expect(notice.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(notice.bottom, lessThan(250));
      await t.tap(find.text('导航'));
      expect(navigated, 1);
      await t.tap(find.text('撤销'));
      await t.pumpAndSettle();
      expect(store.entries.single.id, 'notice');
      await t.tap(find.text('删除'));
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('journal-notice')), findsNothing);
    },
  );
  testWidgets(
    'messages replace each other without queueing, including the same frame',
    (t) async {
      late BuildContext context;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      showJournalMessage(context, const SnackBar(content: Text('旧提示')));
      showJournalMessage(context, const SnackBar(content: Text('新提示')));
      await t.pumpAndSettle();
      expect(find.text('旧提示'), findsNothing);
      expect(find.text('新提示'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.text('新提示'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'settings contains daily wishes and festival controls with no self navigation',
    (t) async {
      final store = JournalStore.memory();
      store.settings['reduced'] = true;
      await t.pumpWidget(
        MaterialApp(home: ProfileSettingsScreen(store: store)),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('settings-festivals')));
      await t.pumpAndSettle();
      expect(find.byType(FestivalCenter), findsOneWidget);
      expect(find.byType(FestivalHomeCard), findsOneWidget);
      expect(find.byTooltip('复制今日寄语'), findsOneWidget);
      expect(find.byKey(const ValueKey('festival-enabled')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final size in [const Size(320, 568), const Size(640, 320)]) {
    testWidgets('record panel is compact and usable at $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = JournalStore.memory();
      store.settings['reduced'] = true;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyMusic(
              store: store,
              journalId: 'empty',
              child: const Center(child: Text('图册内容')),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('图册内容'), findsOneWidget);
      expect(find.byKey(const ValueKey('record-controls')), findsNothing);
      expect(
        t.getSize(find.byKey(const ValueKey('music-record'))),
        const Size(58, 58),
      );
      await t.tap(find.byKey(const ValueKey('music-record')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('record-controls')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('music-record')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('record-controls')), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'record opens progress controls and seeking sends the requested time',
    (t) async {
      final audio = TestAudioPlatform();
      JustAudioPlatform.instance = audio;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => Directory.systemTemp.path,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.audio_session'),
        (_) async => null,
      );
      final store = JournalStore.memory();
      store.settings.addAll({
        'reduced': true,
        'journey_music:guest:seek': {'source': 'asset:morning', 'name': '林间晨光'},
      });
      await t.runAsync(() async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: JourneyMusic(store: store, journalId: 'seek'),
            ),
          ),
        );
        await t.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pumpAndSettle();
      expect(audio.plays, 1);
      expect(find.byKey(const ValueKey('music-progress')), findsNothing);
      await t.tap(find.byKey(const ValueKey('music-record')));
      await t.pumpAndSettle();
      final slider = t.widget<Slider>(
        find.byKey(const ValueKey('music-progress')),
      );
      expect(slider.onChanged, isNotNull);
      await t.runAsync(() async { slider.onChangeEnd!(12500); await Future<void>.delayed(const Duration(milliseconds: 100)); });
      await t.pumpAndSettle();
      expect(
        audio.players.values.last.lastSeek,
        const Duration(milliseconds: 12500),
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
}
