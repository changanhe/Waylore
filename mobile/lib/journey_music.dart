import 'dart:math' as math;

import 'feedback.dart';

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'store.dart';
import 'birthday.dart';
import 'cloud_account.dart';

const journeyTracks = {
  'morning': ('林间晨光', '清透琴音 · 轻轻出发'),
  'coast': ('海岸慢行', '温柔和弦 · 看海发呆'),
  'stars': ('星河来信', '空灵钟音 · 夜色相伴'),
  'picnic': ('草莓野餐', '轻快拨弦 · 可爱日常'),
  'rain': ('雨窗慢笺', '舒缓琴声 · 雨天独处'),
  'sakura': ('樱花来信', '轻盈八音盒 · 春日散步'),
  'trainride': ('沿途风景', '轻快律动 · 列车出行'),
  'forestwalk': ('绿野微风', '木质拨弦 · 林间漫步'),
  'sunsetwalk': ('落日橘海', '温暖和声 · 傍晚看海'),
  'snowfall': ('初雪小径', '晶莹钟音 · 冬日静谧'),
  'coffeeshop': ('街角咖啡', '柔和节拍 · 城市漫游'),
  'moonlit': ('月色入梦', '低缓氛围 · 安静夜读'),
};

/// Selections are local to each journal; imported audio is copied into app storage.
class JourneyMusic extends StatefulWidget {
  final JournalStore store;
  final String journalId;
  final Widget? child;
  final double bottomInset, rightInset;
  const JourneyMusic({
    super.key,
    required this.store,
    required this.journalId,
    this.child,
    this.bottomInset = 20,
    this.rightInset = 16,
  });
  @override
  State<JourneyMusic> createState() => _JourneyMusicState();
}

class _JourneyMusicState extends State<JourneyMusic>
    with
        WidgetsBindingObserver,
        RouteAware,
        AutomaticKeepAliveClientMixin,
        SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  final player = AudioPlayer();
  late final record = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool expanded = false;
  double? seekPreview;
  bool get reduced =>
      widget.store.settings['reduced'] == true ||
      MediaQuery.disableAnimationsOf(context);
  void recordMotion() {
    if (playing &&
        !reduced &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.inactive) {
      if (!record.isAnimating) record.repeat();
    } else {
      record.stop();
    }
  }

  StreamSubscription<PlayerState>? subscription;
  bool busy = false, playing = false, loop = true;
  bool choosing = false, resumeAfterCover = false, manuallyPaused = false;
  double volume = .35;
  String source = '', name = '给这一程配一首音乐';
  int operation = 0;
  String? loadedSource;
  ModalRoute<void>? route;
  late final owner = CloudAccount.instance.uid ?? 'guest';
  String get key => 'journey_music:$owner:${widget.journalId}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    recordMotion();
    final next = ModalRoute.of<void>(context);
    if (next != route) {
      birthdayRoutes.unsubscribe(this);
      route = next;
      if (next != null) birthdayRoutes.subscribe(this, next);
    }
  }

  @override
  void didPushNext() {
    resumeAfterCover = playing || busy;
    operation++;
    player.pause();
  }

  @override
  void didPopNext() {
    if (resumeAfterCover && !choosing) unawaited(start(automatic: true));
    resumeAfterCover = false;
  }

  @override
  void didPop() {
    operation++;
    player.pause();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.store.settings[key];
    if (saved is Map) {
      source = saved['source'] as String? ?? '';
      name = saved['name'] as String? ?? name;
      volume = (saved['volume'] as num? ?? .35).toDouble().clamp(0, 1);
      loop = saved['loop'] != false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && source.isNotEmpty) unawaited(start(automatic: true));
    });
    subscription = player.playerStateStream.listen((state) {
      if (mounted) {
        setState(
          () => playing =
              state.playing &&
              state.processingState != ProcessingState.completed,
        );
        recordMotion();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      operation++;
      record.stop();
      player.pause();
    }
  }

  @override
  void dispose() {
    operation++;
    WidgetsBinding.instance.removeObserver(this);
    birthdayRoutes.unsubscribe(this);
    subscription?.cancel();
    record.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> persist() => widget.store.setting(key, {
    'source': source,
    'name': name,
    'volume': volume,
    'loop': loop,
  });
  void message(String text) {
    if (mounted) {
      showJournalMessage(context, SnackBar(content: Text(text)));
    }
  }

  Future<void> toggle() async {
    if (busy || source.isEmpty) return;
    if (playing) {
      manuallyPaused = true;
      await player.pause();
      return;
    }
    manuallyPaused = false;
    await start();
  }

  Future<void> start({bool automatic = false}) async {
    if (automatic && manuallyPaused) return;
    if (!mounted ||
        busy ||
        playing ||
        source.isEmpty ||
        route?.isCurrent == false) {
      return;
    }
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    final token = ++operation;
    final requestedSource = source;
    setState(() => busy = true);
    try {
      if (loadedSource != source) {
        if (source.startsWith('asset:')) {
          await player.setAsset('assets/audio/${source.substring(6)}.mp3');
        } else {
          if (!await File(source).exists()) throw StateError('missing');
          await player.setFilePath(source);
        }
        loadedSource = source;
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.setVolume(volume);
      await player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      if (mounted &&
          token == operation &&
          source == requestedSource &&
          route?.isCurrent != false &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
          WidgetsBinding.instance.lifecycleState !=
              AppLifecycleState.inactive) {
        unawaited(
          player.play().catchError((Object _) {
            message('音乐播放失败，请重新选择音频');
          }),
        );
      }
    } catch (_) {
      message('无法播放这首音乐，请重新导入有效的 MP3 文件');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> select(String value, String title) async {
    operation++;
    manuallyPaused = false;
    await player.stop();
    loadedSource = null;
    if (!mounted) return;
    setState(() {
      source = value;
      name = title;
    });
    try {
      await persist();
      if (mounted && value.isNotEmpty && !busy) await start();
    } catch (_) {
      message('音乐选择保存失败，请重试');
    }
  }

  Future<void> import() async {
    if (busy) return;
    setState(() => busy = true);
    String? copied;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );
      if (result.isEmpty || !mounted) return;
      final file = result.single;
      if (file.path == null || !file.name.toLowerCase().endsWith('.mp3')) {
        message('请选择 MP3 格式音频');
        return;
      }
      if ((await file.length() ?? 50 * 1024 * 1024 + 1) > 50 * 1024 * 1024) {
        message('请选择不超过 50 MB 的 MP3 文件');
        return;
      }
      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/journey_audio',
      );
      await dir.create(recursive: true);
      copied = '${dir.path}/${JournalStore.newId()}.mp3';
      await File(file.path!).copy(copied);
      // Decode before accepting the import; a renamed non-audio file is rejected.
      final probe = AudioPlayer();
      try {
        await probe.setFilePath(copied);
      } finally {
        await probe.dispose();
      }
      if (!mounted) {
        await File(copied).delete();
        return;
      }
      final library = Map<String, dynamic>.from(
        widget.store.settings['journey_library:$owner'] as Map? ?? {},
      );
      library[copied] = file.name.replaceFirst(
        RegExp(r'\.mp3$', caseSensitive: false),
        '',
      );
      await widget.store.setting('journey_library:$owner', library);
      await select(
        copied,
        file.name.replaceFirst(RegExp(r'\.mp3$', caseSensitive: false), ''),
      );
      message('音乐已导入，下次打开这一页会自动播放');
    } catch (_) {
      if (copied != null && copied != source) {
        try {
          await File(copied).delete();
        } catch (_) {}
      }
      message('导入失败，请选择可正常播放的 MP3 文件');
    } finally {
      if (mounted) {
        setState(() => busy = false);
        if (copied != null && source == copied) {
          unawaited(start(automatic: true));
        }
      }
    }
  }

  Future<void> choose() async {
    if (busy || choosing) return;
    choosing = true;
    final wasPlaying = playing;
    var picked = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        minChildSize: .4,
        maxChildSize: .9,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const ListTile(
              title: Text('旅途随身听', style: TextStyle(fontSize: 24)),
              subtitle: Text('十二首内置纯音乐，或带上自己的声音。选好后自动播放。'),
            ),
            for (final track in journeyTracks.entries)
              ListTile(
                leading: const Icon(Icons.music_note_rounded),
                title: Text(track.value.$1),
                subtitle: Text(track.value.$2),
                trailing: source == 'asset:${track.key}'
                    ? const Icon(Icons.check_circle_outline)
                    : null,
                onTap: () {
                  picked = true;
                  Navigator.pop(sheet);
                  select('asset:${track.key}', track.value.$1);
                },
              ),
            for (final track
                in (widget.store.settings['journey_library:$owner'] as Map? ??
                        {})
                    .entries)
              ListTile(
                leading: const Icon(Icons.library_music_outlined),
                title: Text(
                  '${track.value}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('我的导入'),
                trailing: source == track.key
                    ? const Icon(Icons.check_circle_outline)
                    : null,
                onTap: () {
                  picked = true;
                  Navigator.pop(sheet);
                  select('${track.key}', '${track.value}');
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('导入 MP3'),
              subtitle: const Text('最多 50 MB · 复制到本机保存'),
              onTap: () {
                picked = true;
                Navigator.pop(sheet);
                import();
              },
            ),
            if (source.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.music_off_outlined),
                title: const Text('移除本页配乐'),
                onTap: () {
                  picked = true;
                  Navigator.pop(sheet);
                  select('', '给这一程配一首音乐');
                },
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '已设置配乐的图册与手账，每次打开会自动播放。可随时暂停，离开页面或进入后台会暂停。导入音频仅在本机使用，不随照片分享或云端同步。',
                style: TextStyle(fontSize: 12, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
    choosing = false;
    if (mounted && wasPlaying && !picked && source.isNotEmpty) {
      unawaited(start(automatic: true));
    }
  }

  String time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget controls(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('record-controls'),
      color: colors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    source.isEmpty ? '背景音乐' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭配乐面板',
                  onPressed: () => setState(() => expanded = false),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ),
              ],
            ),
            if (source.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('为这段旅程选一首配乐。', style: TextStyle(fontSize: 12)),
              ),
            if (source.isNotEmpty)
              StreamBuilder<Duration>(
                stream: player.positionStream,
                initialData: player.position,
                builder: (context, snapshot) {
                  final total = player.duration ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble();
                  final position =
                      (seekPreview ??
                              (snapshot.data ?? Duration.zero).inMilliseconds
                                  .toDouble())
                          .clamp(0.0, math.max(0.0, max))
                          .toDouble();
                  return Column(
                    children: [
                      Slider(
                        key: const ValueKey('music-progress'),
                        semanticFormatterCallback: (v) =>
                            time(Duration(milliseconds: v.round())),
                        min: 0,
                        max: math.max(1.0, max),
                        value: position,
                        onChanged: max <= 0
                            ? null
                            : (v) => setState(() => seekPreview = v),
                        onChangeEnd: (v) async {
                          try {
                            await player.seek(
                              Duration(milliseconds: v.round()),
                            );
                          } catch (_) {
                            message('暂时无法调整进度，请重试');
                          }
                          if (mounted) setState(() => seekPreview = null);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              time(Duration(milliseconds: position.round())),
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              time(total),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            Row(
              children: [
                IconButton(
                  tooltip: playing ? '暂停音乐' : '播放音乐',
                  onPressed: busy || source.isEmpty ? null : toggle,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                ),
                Expanded(
                  child: Tooltip(
                    message: '选择背景音乐',
                    child: TextButton.icon(
                      onPressed: busy ? null : choose,
                      icon: const Icon(Icons.queue_music_rounded, size: 19),
                      label: const Text('更换音乐', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: loop ? '循环开启' : '循环关闭',
                  onPressed: source.isEmpty
                      ? null
                      : () async {
                          setState(() => loop = !loop);
                          try {
                            await player.setLoopMode(
                              loop ? LoopMode.one : LoopMode.off,
                            );
                            await persist();
                          } catch (_) {
                            message('循环设置保存失败');
                          }
                        },
                  icon: Icon(
                    Icons.repeat_rounded,
                    size: 19,
                    color: loop ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (source.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.volume_down_outlined, size: 18),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('music-volume'),
                      value: volume,
                      onChanged: (v) {
                        setState(() => volume = v);
                        player.setVolume(v);
                      },
                      onChangeEnd: (_) async {
                        try {
                          await persist();
                        } catch (_) {
                          message('音量保存失败');
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final bottom = math.min(
          widget.bottomInset + MediaQuery.viewPaddingOf(context).bottom,
          math.max(8.0, box.maxHeight - 80),
        );
        final right = widget.rightInset.clamp(
          8.0,
          math.max(8.0, box.maxWidth - 80),
        );
        final available = math.max(60.0, box.maxHeight - bottom - 88);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: widget.child ?? const SizedBox()),
            Positioned(
              right: right.toDouble(),
              bottom: bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: reduced ? 0 : 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    ),
                    child: expanded
                        ? SizedBox(
                            key: const ValueKey('record-panel'),
                            width: math.min(310, box.maxWidth - right - 16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: available),
                              child: SingleChildScrollView(
                                child: controls(context),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: expanded ? '收起配乐控制' : '打开配乐控制',
                    child: Semantics(
                      button: true,
                      label: '背景音乐唱片${playing ? '，正在播放' : ''}',
                      child: GestureDetector(
                        key: const ValueKey('music-record'),
                        onTap: () => setState(() => expanded = !expanded),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surface,
                              border: Border.all(color: colors.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ExcludeSemantics(
                                child: AnimatedBuilder(
                                  animation: record,
                                  child: CustomPaint(
                                    painter: _RecordPainter(colors.primary),
                                    child: const SizedBox.expand(),
                                  ),
                                  builder: (_, child) => Transform.rotate(
                                    angle: record.value * math.pi * 2,
                                    transformHitTests: false,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecordPainter extends CustomPainter {
  final Color label;
  _RecordPainter(this.label);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2;
    final paint = Paint()..color = const Color(0xff252724);
    canvas.drawCircle(center, radius, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = const Color(0xff565a54);
    for (double r = radius * .43; r < radius * .94; r += 3) {
      canvas.drawCircle(center, r, paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..color = label;
    canvas.drawCircle(center, radius * .35, paint);
    paint.color = const Color(0xfffaf6ed);
    canvas.drawCircle(center, 2, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .22);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * .82),
      -.8,
      .45,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RecordPainter old) => old.label != label;
}
