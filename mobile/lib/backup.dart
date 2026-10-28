import 'dart:io';

import 'legacy_desktop.dart';
import 'feedback.dart';
import 'i18n.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'store.dart';

Future<void> backupData(
  BuildContext context,
  JournalStore store, {
  bool restore = false,
}) async {
  try {
    if (restore) {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: Platform.isWindows
            ? ['json', 'db', 'sqlite', 'sqlite3']
            : ['json'],
      );
      if (result == null) return;
      final file = result;
      if ((await file.length() ?? 0) > 150 * 1024 * 1024) {
        throw const FormatException('备份超过当前导入大小限制');
      }
      final legacy =
          Platform.isWindows && !file.name.toLowerCase().endsWith('.json');
      final decoded = legacy
          ? await readLegacyDesktop(
              file.path!,
              existingIds: store.entries.map((e) => e.id).toSet(),
            )
          : jsonDecode(utf8.decode(await file.readAsBytes()));
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != 'kexinglu-mobile') {
        throw const FormatException('请选择新版客行录导出的备份');
      }
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const LocalText('导入这份备份？'),
          content: Text(
            legacy
                ? '发现 ${(decoded['entries'] as List).length} 条尚未导入的旧版记录。原数据库不会被修改，已导入记录会跳过。缺失图片：${decoded['missingPhotos'] ?? 0}。建议先保留原数据目录。'
                : '将合并记录。同一条记录会恢复为备份中的版本，其他记录保留。建议先导出当前备份。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const LocalText('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const LocalText('导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await store.restore(decoded);
    } else {
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode(await store.backup())),
      );
      final path = await FilePicker.saveFile(
        dialogTitle: '保存客行录备份',
        fileName:
            'Kexinglu-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json',
        bytes: bytes,
      );
      if (path == null) return;
    }
    if (context.mounted) {
      showJournalMessage(
        context,
        SnackBar(content: Text(restore ? '备份已导入' : '备份已保存，请妥善保管')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      showJournalMessage(
        context,
        SnackBar(
          content: Text(
            restore ? '导入未成功，请检查备份文件；现有记录未清空。' : '备份未成功，请检查存储空间或图片文件。',
          ),
        ),
      );
    }
  }
}
