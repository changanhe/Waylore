import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kexinglu_mobile/account_screen.dart';
import 'package:kexinglu_mobile/app_typography.dart';
import 'package:kexinglu_mobile/atlas.dart';
import 'package:kexinglu_mobile/auth_motion.dart';
import 'package:kexinglu_mobile/cloud_account.dart';
import 'package:kexinglu_mobile/main.dart';
import 'package:kexinglu_mobile/motion.dart';
import 'package:kexinglu_mobile/profile_pages.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cloud = CloudAccount.instance;
  late Completer<http.Response> reply;
  setUpAll(() => cloud.initialize(configuration: {}));
  setUp(() {
    reply = Completer<http.Response>();
    cloud.client = SupabaseClient(
      'https://auth.test.invalid',
      'test-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/token')) return reply.future;
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDown(() async {
    await cloud.client?.dispose();
    cloud.client = null;
  });
  Future<void> open(WidgetTester t, {bool reduced = false}) async {
    reply = Completer<http.Response>();
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: MotionScope(
          reduced: reduced,
          child: AccountScreen(store: JournalStore.memory()),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> enter(WidgetTester t) async {
    final email = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '邮箱账号',
    );
    final password = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '密码（至少 8 位）',
    );
    await t.enterText(email, 'traveler@example.com');
    await t.enterText(password, 'example-pass-123');
    await t.ensureVisible(find.byKey(const ValueKey('auth-submit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('auth-submit')));
    await t.pump();
  }

  testWidgets(
    'login loading feedback follows the request and errors remain actionable',
    (t) async {
      await open(t);
      await enter(t);
      expect(
        t.widget<AuthHero>(find.byType(AuthHero)).feedback,
        AuthFeedback.working,
      );
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
            .onPressed,
        isNull,
      );
      await t.pump(const Duration(milliseconds: 450));
      reply.complete(
        http.Response(
          jsonEncode({
            'error_code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }),
          400,
          headers: {'content-type': 'application/json'},
        ),
      );
      await t.pumpAndSettle();
      expect(
        t.widget<AuthHero>(find.byType(AuthHero)).feedback,
        AuthFeedback.error,
      );
      expect(find.text('邮箱或密码不正确，请重试。'), findsOneWidget);
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
            .onPressed,
        isNotNull,
      );
      expect(
        t
            .widget<TextField>(
              find.byWidgetPredicate(
                (w) => w is TextField && w.decoration?.labelText == '邮箱账号',
              ),
            )
            .controller!
            .text,
        'traveler@example.com',
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'successful login celebrates only after an authenticated response',
    (t) async {
      await open(t);
      await enter(t);
      final exp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      String part(Map<String, dynamic> value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token =
          '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'exp': exp, 'sub': '00000000-0000-4000-8000-000000000001', 'aud': 'authenticated'})}.test';
      reply.complete(
        http.Response(
          jsonEncode({
            'access_token': token,
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': '00000000-0000-4000-8000-000000000001',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'traveler@example.com',
              'created_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await t.pumpAndSettle();
      expect(cloud.uid, isNotNull);
      expect(find.byKey(const ValueKey('auth-success-mark')), findsOneWidget);
      expect(find.text('你的客行录'), findsOneWidget);
      expect(find.text('同步当前资料库'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('reduced motion keeps working feedback static', (t) async {
    await open(t, reduced: true);
    await enter(t);
    await t.pump(const Duration(seconds: 1));
    expect(
      t.widget<AuthHero>(find.byType(AuthHero)).feedback,
      AuthFeedback.working,
    );
    expect(t.hasRunningAnimations, isFalse);
    reply.complete(
      http.Response(
        jsonEncode({
          'error_code': 'invalid_credentials',
          'msg': 'Invalid credentials',
        }),
        400,
        headers: {'content-type': 'application/json'},
      ),
    );
    await t.pumpAndSettle();
  });
  test('unknown font preferences fall back to device default', () {
    expect(JournalFont.read('unavailable'), JournalFont.system);
    expect(JournalFont.read(null).family, isNull);
    expect(JournalFont.fallback('ja').first, 'Noto Sans CJK JP');
  });
  testWidgets(
    'font selection updates the whole app and survives reopening settings',
    (t) async {
      final store = JournalStore.memory();
      final atlas = AtlasData();
      await t.pumpWidget(Kexinglu(store: store, atlas: atlas));
      await t.pumpAndSettle();
      for (final font in JournalFont.values) {
        await store.setting('font', font.name);
        await t.pumpAndSettle();
        final textContext = t.element(find.text('首页').last);
        expect(
          Theme.of(textContext).textTheme.bodyMedium!.fontFamily,
          font.family ?? 'Roboto',
        );
      }
      await t.pumpWidget(
        MaterialApp(home: ProfileSettingsScreen(store: store)),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('font-option-serif')),
        300,
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('font-option-serif')));
      await t.pumpAndSettle();
      expect(store.settings['font'], 'serif');
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        MaterialApp(home: ProfileSettingsScreen(store: store)),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('font-option-serif')),
        300,
      );
      expect(
        t
            .widget<ListTile>(find.byKey(const ValueKey('font-option-serif')))
            .selected,
        isTrue,
      );
      expect(t.takeException(), isNull);
    },
  );
}
