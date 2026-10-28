import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/app_typography.dart';
import 'package:kexinglu_mobile/atlas.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/i18n.dart';
import 'package:kexinglu_mobile/main.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AtlasData atlas;
  setUpAll(() async {
    await CloudAccount.instance.initialize(configuration: {});
    atlas = AtlasData();
    await atlas.load();
  });
  tearDown(() => AppLanguage.current = 'zh');
  for (final font in JournalFont.values) {
    for (final language in AppLanguage.names.keys) {
      testWidgets(
        '${font.name} $language keeps all main pages readable on a small phone',
        (t) async {
          t.view.physicalSize = const Size(360, 780);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final store = JournalStore.memory();
          await store.setting('font', font.name);
          await store.setting('language', language);
          await store.setting('reduced', true);
          await t.pumpWidget(Kexinglu(store: store, atlas: atlas));
          await t.pumpAndSettle();
          for (var i = 1; i < 5; i++) {
            await t.tap(find.byKey(ValueKey('navigation-tab-$i')));
            await t.pumpAndSettle();
            expect(find.byKey(ValueKey('navigation-tab-$i')), findsOneWidget);
          }
        },
      );
    }
  }
}
