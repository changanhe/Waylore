import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeDesktopStorage() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

String get platformVersionLabel => switch (defaultTargetPlatform) {
  TargetPlatform.windows => 'Windows · 1.0.0',
  TargetPlatform.macOS => 'macOS · 1.0.0',
  TargetPlatform.linux => 'Linux · 1.0.0',
  _ => 'Android · 1.0.0',
};

Future<Directory> journalDataDirectory() async {
  if (Platform.isWindows) {
    final custom = Platform.environment['WAYLORE_DATA_DIR'];
    final base = Platform.environment['LOCALAPPDATA'];
    final dir = Directory(
      custom ??
          '${base ?? (await getApplicationSupportDirectory()).path}/Waylore',
    );
    await dir.create(recursive: true);
    return dir;
  }
  return getApplicationDocumentsDirectory();
}
