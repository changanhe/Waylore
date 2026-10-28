import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reads a user-selected old desktop database without changing it. Returns the
/// same validated, atomic import format used by current phone/tablet backups.
Future<Map<String, dynamic>> readLegacyDesktop(
  String path, {
  Set<String> existingIds = const {},
}) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
  );
  final prefix = sha256
      .convert(utf8.encode(File(path).absolute.path.toLowerCase()))
      .toString()
      .substring(0, 12);
  final photos = <String, String>{};
  final records = <Map<String, dynamic>>[];
  var missing = 0;
  Future<String> image(dynamic value) async {
    if (value is! String || value.isEmpty) return '';
    if (photos.containsKey(value)) return value;
    final absolute = File(value).isAbsolute
        ? File(value)
        : File('${File(path).parent.path}/$value');
    if (await absolute.exists()) {
      if (await absolute.length() > 25 * 1024 * 1024) {
        throw const FormatException('旧版图片超过25MB，请先缩小后导入');
      }
      photos[value] = base64Encode(await absolute.readAsBytes());
      return value;
    }
    // Old scrapbook pages embed their photos as base64 strings.
    if (value.length > 256) {
      try {
        final bytes = base64Decode(value);
        if (bytes.length > 25 * 1024 * 1024) {
          throw const FormatException('旧版图片过大');
        }
        final key = 'legacy-${sha256.convert(bytes)}.png';
        photos[key] = value;
        return key;
      } on FormatException {
        /* Treat unavailable media as missing, retain text. */
      }
    }
    missing++;
    return '';
  }

  try {
    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    )).map((r) => r['name']).toSet();
    const mapping = {
      'movie': (
        'movies',
        {
          'title': 'title',
          'category': 'kind',
          'date': 'watch_date',
          'rating': 'rating',
          'note': 'review',
          'image': 'poster',
        },
      ),
      'food': (
        'food_items',
        {
          'title': 'name',
          'place': 'place',
          'date': 'eat_date',
          'price': 'price',
          'rating': 'rating',
          'note': 'note',
          'image': 'image',
        },
      ),
      'travel': (
        'travel_logs',
        {
          'title': 'title',
          'city': 'city',
          'date': 'visit_date',
          'rating': 'rating',
          'note': 'note',
          'image': 'image',
          'lon': 'lon',
          'lat': 'lat',
        },
      ),
      'ticket': (
        'tickets',
        {
          'from': 'from_city',
          'to': 'to_city',
          'date': 'depart_date',
          'code': 'code',
          'seat': 'seat',
          'passenger': 'passenger',
          'price': 'price',
          'note': 'note',
          'image': 'image',
          'airline': 'airline',
        },
      ),
    };
    if (!tables.any(
      (t) => mapping.values.any((m) => m.$1 == t) || t == 'travel_notebooks',
    )) {
      throw const FormatException('不是旧版客行录数据库');
    }
    for (final group in mapping.entries) {
      if (!tables.contains(group.value.$1)) continue;
      for (final row in await db.query(group.value.$1)) {
        final id = 'legacy-$prefix-${group.key}-${row['id']}';
        if (existingIds.contains(id)) continue;
        final data = <String, dynamic>{};
        for (final field in group.value.$2.entries) {
          final value = row[field.value];
          if (value != null) data[field.key] = value;
        }
        if (data['rating'] is num) {
          data['rating'] = (data['rating'] as num).clamp(0, 5);
        }
        data['image'] = await image(data['image']);
        if (group.key == 'ticket') {
          data['mode'] = row['vehicle'] == '飞机' ? 'air' : 'rail';
        }
        if (group.key == 'travel' && tables.contains('travel_photos')) {
          data['photos'] = <Map<String, dynamic>>[];
          for (final photo in await db.query(
            'travel_photos',
            where: 'log_id = ?',
            whereArgs: [row['id']],
            orderBy: 'sort, id',
          )) {
            final ref = await image(photo['image']);
            if (ref.isNotEmpty) {
              (data['photos'] as List).add({
                'image': ref,
                'caption': photo['caption'] ?? '',
              });
            }
          }
        }
        records.add({'id': id, 'kind': group.key, 'data': data});
      }
    }
    if (tables.contains('travel_notebooks')) {
      for (final row in await db.query('travel_notebooks')) {
        final id = 'legacy-$prefix-book-${row['id']}';
        if (existingIds.contains(id)) continue;
        final doc = jsonDecode(row['document'] as String) as Map;
        final pages = <Map<String, dynamic>>[];
        for (final raw in doc['pages'] as List? ?? []) {
          final elements = <Map<String, dynamic>>[];
          var index = 0;
          Future<void> add(Map e) async {
            final photo = e['image'];
            final ref = photo == null ? '' : await image(photo);
            if (photo != null && ref.isEmpty) return;
            final sourceWidth = math.max(
              1.0,
              ((raw['design'] as Map?)?['width'] as num? ?? 420).toDouble(),
            );
            final sourceHeight = math.max(
              1.0,
              ((raw['design'] as Map?)?['height'] as num? ?? 580).toDouble(),
            );
            double number(String key, double fallback) =>
                (e[key] as num? ?? fallback).toDouble();
            elements.add({
              'id': '$id-${pages.length}-${index++}',
              'kind': photo != null
                  ? 'image'
                  : e['kind'] == 'sticker'
                  ? 'sticker'
                  : 'text',
              'text': photo != null ? ref : '${e['text'] ?? ''}',
              'x': (number('x', 30) / sourceWidth).clamp(0, .9),
              'y': (number('y', 30) / sourceHeight).clamp(0, .94),
              'width': (number('w', 220) / sourceWidth).clamp(.01, 1),
              'size': (number('size', 18) * 360 / sourceWidth).clamp(10, 100),
              'rotation': number('rotation', 0) * math.pi / 180,
            });
          }

          final design = raw['design'] as Map?;
          if (design != null) {
            for (final e in design['elements'] as List? ?? []) {
              await add(e as Map);
            }
          } else {
            await add({'text': raw['title'] ?? '', 'size': 28, 'y': 35});
            await add({'text': raw['note'] ?? '', 'y': 100});
            for (final photo in raw['photos'] as List? ?? []) {
              if (photo['included'] != false) {
                await add({'image': photo['image'], 'y': 230, 'w': 250});
              }
            }
          }
          pages.add({'elements': elements});
        }
        const styles = ['paper', 'ocean', 'kraft', 'rose', 'mono', 'night'];
        records.add({
          'id': id,
          'kind': 'book',
          'data': {
            'title': doc['title'] ?? row['title'] ?? '旅行手账',
            'style': math.max(0, styles.indexOf('${doc['style']}')),
            'pages': pages.isEmpty
                ? [
                    {'elements': <dynamic>[]},
                  ]
                : pages,
          },
        });
      }
    }
    return {
      'format': 'kexinglu-mobile',
      'version': 1,
      'entries': records,
      'photos': photos,
      'missingPhotos': missing,
    };
  } finally {
    await db.close();
  }
}
