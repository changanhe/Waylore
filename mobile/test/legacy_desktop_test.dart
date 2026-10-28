import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kexinglu_mobile/legacy_desktop.dart';
import 'package:kexinglu_mobile/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('old Windows records import without modifying the source or duplicating records', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('waylore-legacy-test-');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/yingjianlu.db';
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute(
      'CREATE TABLE tickets (id INTEGER PRIMARY KEY, vehicle TEXT, from_city TEXT, to_city TEXT)',
    );
    await db.insert('tickets', {
      'id': 1,
      'vehicle': '高铁',
      'from_city': '杭州东',
      'to_city': '上海虹桥',
    });
    await db.execute(
      'CREATE TABLE movies (id INTEGER PRIMARY KEY, title TEXT, rating REAL, poster TEXT)',
    );
    await db.insert('movies', {
      'id': 2,
      'title': '电影记录',
      'rating': 4.5,
      'poster': 'missing.png',
    });
    await db.execute(
      'CREATE TABLE travel_notebooks (id INTEGER PRIMARY KEY, title TEXT, document TEXT)',
    );
    await db.insert('travel_notebooks', {
      'id': 3,
      'title': '旧手账',
      'document': jsonEncode({
        'title': '旧手账',
        'style': 'ocean',
        'pages': [
          {
            'design': {
              'elements': [
                {
                  'kind': 'text',
                  'text': '原稿',
                  'x': 42,
                  'y': 58,
                  'w': 210,
                  'size': 21,
                  'rotation': 90,
                },
              ],
            },
          },
        ],
      }),
    });
    await db.close();
    final before = await File(path).readAsBytes();
    final backup = await readLegacyDesktop(path);
    expect(backup['entries'], hasLength(3));
    expect(backup['missingPhotos'], 1);
    final store = JournalStore.memory();
    await store.restore(backup);
    expect(store.of('ticket').single.data['mode'], 'rail');
    expect(store.of('movie').single.data['rating'], 4.5);
    expect(store.of('movie').single.data['image'], '');
    expect(store.of('book').single.data['style'], 1);
    final part = store.of('book').single.data['pages'][0]['elements'][0];
    expect(part['text'], '原稿');
    expect(part['x'], closeTo(.1, .001));
    final again = await readLegacyDesktop(
      path,
      existingIds: store.entries.map((e) => e.id).toSet(),
    );
    expect(again['entries'], isEmpty);
    expect(await File(path).readAsBytes(), before);
  });
  test('an unrelated database is rejected', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('waylore-invalid-test-');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/other.db';
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.close();
    await expectLater(readLegacyDesktop(path), throwsFormatException);
  });
}
