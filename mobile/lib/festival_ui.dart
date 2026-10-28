import 'dart:convert';

import 'package:flutter/services.dart';

import 'feedback.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'birthday.dart';
import 'cloud_account.dart';
import 'festival_calendar.dart';
import 'look.dart';
import 'store.dart';

Map<dynamic, dynamic> celebrationProfile(JournalStore store) {
  final cloud = CloudAccount.instance;
  final raw = store.settings['personal_profile:${cloud.uid ?? 'guest'}'];
  final local = raw is Map ? raw : const {};
  final remote =
      cloud.client?.auth.currentUser?.userMetadata?['kexinglu_profile'];
  return local['pending'] == true || remote is! Map ? local : remote;
}

/// BirthdayGate remains the outer layer. A birthday suppresses the holiday
/// splash entirely, so the original birthday greeting/confetti never queues
/// behind another screen or shares its once-per-day marker.
class FestivalGate extends StatefulWidget {
  final JournalStore store;
  final Widget child;
  final DateTime Function()? clock;
  const FestivalGate({
    super.key,
    required this.store,
    required this.child,
    this.clock,
  });
  @override
  State<FestivalGate> createState() => _FestivalGateState();
}

class _FestivalGateState extends State<FestivalGate>
    with WidgetsBindingObserver, RouteAware {
  final cloud = CloudAccount.instance;
  JournalFestival? active;
  String? activeDay, activeOwner;
  bool scheduled = false;
  final shown = <String>{};
  Timer? closeTimer, midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(schedule);
    cloud.addListener(schedule);
    birthdayHomeVisible.addListener(schedule);
    schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) birthdayRoutes.subscribe(this, route);
  }

  @override
  void didPopNext() => schedule();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) schedule();
  }

  void schedule() {
    if (!mounted || scheduled) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (mounted) check();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void close() {
    closeTimer?.cancel();
    if (mounted && active != null) setState(() => active = null);
  }

  void check() {
    final now = (widget.clock ?? DateTime.now)().toLocal();
    final day = FestivalCalendar.dayKey(now);
    final owner = cloud.uid ?? 'guest';
    midnight?.cancel();
    midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      schedule,
    );
    final birthday = isBirthday(
      celebrationProfile(widget.store)['birthday'],
      now,
    );
    final enabled = widget.store.settings['festival_greetings'] != false;
    if (birthday || !enabled || day != activeDay || owner != activeOwner) {
      close();
    }
    if (!cloud.initialized ||
        birthday ||
        !enabled ||
        active != null ||
        !birthdayHomeVisible.value ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    final seenKey = 'festival_greeting_seen:$owner';
    if (widget.store.settings[seenKey] == day ||
        shown.contains('$owner:$day')) {
      return;
    }
    final events = FestivalCalendar.on(
      now,
      international: widget.store.settings['festival_international'] != false,
    );
    if (events.isEmpty) return;
    shown.add('$owner:$day');
    setState(() {
      active = events.first;
      activeDay = day;
      activeOwner = owner;
    });
    closeTimer = Timer(const Duration(milliseconds: 3000), close);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && active != null) {
        unawaited(widget.store.setting(seenKey, day).catchError((Object _) {}));
      }
    });
  }

  @override
  void dispose() {
    closeTimer?.cancel();
    midnight?.cancel();
    widget.store.removeListener(schedule);
    cloud.removeListener(schedule);
    birthdayHomeVisible.removeListener(schedule);
    birthdayRoutes.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      if (active != null)
        Positioned.fill(
          child: FestivalSplash(
            key: const ValueKey('festival-splash'),
            festival: active!,
            onClose: close,
            reduced:
                widget.store.settings['reduced'] == true ||
                MediaQuery.disableAnimationsOf(context),
          ),
        ),
    ],
  );
}

class FestivalColors {
  final Color background, accent, ink;
  const FestivalColors(this.background, this.accent, this.ink);
  static FestivalColors of(FestivalArt art, bool dark) {
    final color = switch (art) {
      FestivalArt.lantern => const Color(0xffa83935),
      FestivalArt.moon => const Color(0xff9b7843),
      FestivalArt.blossom => const Color(0xffb65e7c),
      FestivalArt.earth => const Color(0xff397f75),
      FestivalArt.sparkle => const Color(0xff8062a5),
      FestivalArt.snow => const Color(0xff507b91),
      FestivalArt.quiet => const Color(0xff62756b),
    };
    return FestivalColors(
      dark
          ? Color.lerp(const Color(0xff161d23), color, .14)!
          : Color.lerp(const Color(0xfffffbf3), color, .045)!,
      dark ? Color.lerp(color, const Color(0xffffe9b0), .55)! : color,
      dark ? const Color(0xfff5efe2) : const Color(0xff303a38),
    );
  }
}

class FestivalSplash extends StatefulWidget {
  final JournalFestival festival;
  final VoidCallback onClose;
  final bool reduced, preview;
  const FestivalSplash({
    super.key,
    required this.festival,
    required this.onClose,
    this.reduced = false,
    this.preview = false,
  });
  @override
  State<FestivalSplash> createState() => _FestivalSplashState();
}

class _FestivalSplashState extends State<FestivalSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  bool get still => widget.reduced || widget.festival.art == FestivalArt.quiet;
  @override
  void initState() {
    super.initState();
    if (!still) controller.repeat();
  }

  @override
  void didUpdateWidget(FestivalSplash old) {
    super.didUpdateWidget(old);
    if (still) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.festival;
    final c = FestivalColors.of(
      f.art,
      Theme.of(context).brightness == Brightness.dark,
    );
    return Material(
      color: c.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FestivalPainter(controller, f.art, c.accent, still),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.preview ? '效果预览 · 不改变日期和播放记录' : '客行录 · 岁时来信',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: c.ink.withValues(alpha: .6),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '跳过祝福',
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close_rounded,
                          color: c.ink.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 28,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: still ? 0 : 700,
                                ),
                                tween: Tween(begin: 0, end: 1),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) => Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 18 * (1 - value)),
                                    child: child,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: c.accent.withValues(
                                            alpha: .28,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        color: c.background.withValues(
                                          alpha: .9,
                                        ),
                                      ),
                                      child: Text(
                                        f.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          letterSpacing: 2,
                                          color: c.accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Icon(
                                      festivalIcon(f.art),
                                      size: 54,
                                      color: c.accent,
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      f.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 38,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                        color: c.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      f.wish,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 2,
                                        color: c.ink.withValues(alpha: .76),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Text(
                                      f.english,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        height: 1.6,
                                        letterSpacing: 1.2,
                                        color: c.accent.withValues(alpha: .8),
                                      ),
                                    ),
                                    const SizedBox(height: 34),
                                    FilledButton(
                                      onPressed: widget.onClose,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: c.accent,
                                        foregroundColor: c.background,
                                        minimumSize: const Size(180, 48),
                                      ),
                                      child: Text(
                                        widget.preview ? '返回节日手册' : '开启今天的客行录',
                                      ),
                                    ),
                                    if (!widget.preview)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          '今日仅首次展示 · 随时可以跳过',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: c.ink.withValues(alpha: .5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData festivalIcon(FestivalArt art) => switch (art) {
  FestivalArt.lantern => Icons.light_rounded,
  FestivalArt.moon => Icons.nightlight_round,
  FestivalArt.blossom => Icons.local_florist_outlined,
  FestivalArt.earth => Icons.public_rounded,
  FestivalArt.sparkle => Icons.auto_awesome_rounded,
  FestivalArt.snow => Icons.ac_unit_rounded,
  FestivalArt.quiet => Icons.spa_outlined,
};

class _FestivalPainter extends CustomPainter {
  final Animation<double> time;
  final FestivalArt art;
  final Color color;
  final bool still;
  _FestivalPainter(this.time, this.art, this.color, this.still)
    : super(repaint: time);
  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 0.0 : time.value * math.pi * 2;
    final paint = Paint()..color = color.withValues(alpha: .075);
    canvas.drawCircle(
      Offset(size.width * .9, size.height * .26),
      size.width * .6,
      paint,
    );
    canvas.drawCircle(Offset(0, size.height * .89), size.width * .65, paint);
    if (art == FestivalArt.lantern) {
      for (final x in [.14, .86]) {
        final center = Offset(
          size.width * x + math.sin(t) * 4,
          size.height * .19,
        );
        paint
          ..color = color.withValues(alpha: .55)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(center.dx, 0), center, paint);
        paint.color = color.withValues(alpha: .17);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 46, height: 58),
            const Radius.circular(18),
          ),
          paint,
        );
        paint
          ..color = color.withValues(alpha: .45)
          ..strokeWidth = 2;
        canvas.drawLine(
          center + const Offset(0, 29),
          center + const Offset(0, 46),
          paint,
        );
      }
    } else if (art == FestivalArt.moon) {
      paint.color = color.withValues(alpha: .2);
      canvas.drawCircle(Offset(size.width * .8, size.height * .19), 52, paint);
      paint
        ..color = color.withValues(alpha: .09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(size.width * .8, size.height * .19),
        64 + math.sin(t) * 3,
        paint,
      );
    } else {
      for (var i = 0; i < 22; i++) {
        final random = math.Random(i * 31);
        final x = random.nextDouble() * size.width;
        final y = (random.nextDouble() * size.height + math.sin(t + i) * 12);
        // Keep the text area calm; decorations live along the edges.
        if (x > size.width * .15 &&
            x < size.width * .85 &&
            y > size.height * .27 &&
            y < size.height * .83) {
          continue;
        }
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(t * .2 + i);
        paint
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: .15 + .1 * random.nextDouble());
        if (art == FestivalArt.snow || art == FestivalArt.sparkle) {
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4;
          canvas.drawLine(const Offset(-5, 0), const Offset(5, 0), paint);
          canvas.drawLine(const Offset(0, -5), const Offset(0, 5), paint);
        } else {
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 7, height: 14),
            paint,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_FestivalPainter old) =>
      old.art != art || old.color != color || old.still != still;
}

class FestivalHomeCard extends StatefulWidget {
  final JournalStore store;
  final AppPalette palette;
  final bool openCenter;
  final bool compact;
  const FestivalHomeCard({
    super.key,
    required this.store,
    required this.palette,
    this.openCenter = true,
    this.compact = false,
  });
  @override
  State<FestivalHomeCard> createState() => _FestivalHomeCardState();
}

class _FestivalHomeCardState extends State<FestivalHomeCard>
    with WidgetsBindingObserver {
  Timer? midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    resetClock();
  }

  void resetClock() {
    midnight?.cancel();
    final now = DateTime.now();
    midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          resetClock();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      resetClock();
    }
  }

  @override
  void dispose() {
    midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette, now = DateTime.now();
    final events = FestivalCalendar.on(
      now,
      international: widget.store.settings['festival_international'] != false,
    );
    final birthday = isBirthday(
      celebrationProfile(widget.store)['birthday'],
      now,
    );
    final title = birthday
        ? '今天，你是主角'
        : events.isEmpty
        ? '今日寄语'
        : events.first.name;
    final wish = birthday
        ? '愿新一岁，所有美好如期而至。今天的祝福，只为你。'
        : events.isEmpty
        ? FestivalCalendar.dailyWish(now)
        : events.first.wish.replaceAll('\n', '');
    if (widget.compact) {
      return Semantics(
        button: true,
        child: InkWell(
          key: const ValueKey('home-daily-wish'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FestivalCenter(store: widget.store),
            ),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthday || events.isNotEmpty ? title : '每日寄语',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        wish,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: p.ink.withValues(alpha: .4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: p.paper.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: !widget.openCenter
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FestivalCenter(store: widget.store),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    birthday
                        ? Icons.cake_outlined
                        : festivalIcon(
                            events.isEmpty
                                ? FestivalArt.blossom
                                : events.first.art,
                          ),
                    size: 21,
                    color: p.accent,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (widget.openCenter)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: p.accent,
                      size: 19,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                wish,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: p.ink.withValues(alpha: .7),
                ),
              ),
              if (events.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '今天也是：${events.skip(1).map((e) => e.name).join(' · ')}',
                    style: TextStyle(fontSize: 11, color: p.accent),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: p.accent),
                    ),
                  ),
                  if (!widget.openCenter)
                    IconButton(
                      tooltip: '复制今日寄语',
                      icon: const Icon(Icons.copy_outlined, size: 17),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: wish));
                        if (context.mounted) {
                          showJournalMessage(
                            context,
                            const SnackBar(content: Text('已复制')),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FestivalCenter extends StatelessWidget {
  final JournalStore store;
  const FestivalCenter({super.key, required this.store});
  Future<void> set(BuildContext context, String key, bool value) async {
    try {
      await store.setting(key, value);
    } catch (_) {
      if (context.mounted) {
        showJournalMessage(context, const SnackBar(content: Text('设置未保存，请重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final reduced =
          store.settings['reduced'] == true ||
          MediaQuery.disableAnimationsOf(context);
      return Scaffold(
        appBar: AppBar(title: const Text('每日寄语与节日祝福')),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                const Text(
                  '今天的问候',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '在这里阅读今日寄语、预览节日祝福并调整开屏设置。生日祝福与彩带继续保留。',
                  style: TextStyle(height: 1.8),
                ),
                const SizedBox(height: 16),
                FestivalHomeCard(
                  store: store,
                  palette:
                      AppPalette.all[(store.settings['theme'] as int? ?? 0)
                          .clamp(0, AppPalette.all.length - 1)],
                  openCenter: false,
                ),
                const SizedBox(height: 12),
                const DailyQuote(),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  key: const ValueKey('festival-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('节日开屏祝福'),
                  subtitle: const Text('默认每天一次，约 3 秒，可随时跳过；不影响生日祝福'),
                  value: store.settings['festival_greetings'] != false,
                  onChanged: (v) => set(context, 'festival_greetings', v),
                ),
                SwitchListTile.adaptive(
                  key: const ValueKey('festival-international'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('国际与文化节日'),
                  subtitle: const Text('包括地球日、读书日、圣诞节等；可按喜好关闭'),
                  value: store.settings['festival_international'] != false,
                  onChanged: (v) => set(context, 'festival_international', v),
                ),
                const SizedBox(height: 18),
                const Text(
                  '节日预览',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  '点击下方节日即可预览，不需要修改手机日期，也不会占用当天的自动播放次数。清明与公祭日采用安静画面。',
                  style: TextStyle(fontSize: 12, height: 1.8),
                ),
                const SizedBox(height: 14),
                for (final f in FestivalCalendar.examples)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      key: ValueKey('festival-preview-${f.id}'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: Icon(festivalIcon(f.art)),
                      title: Text(f.name),
                      subtitle: Text(f.title),
                      trailing: const Icon(Icons.play_circle_outline_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (route) => FestivalSplash(
                            festival: f,
                            reduced: reduced,
                            preview: true,
                            onClose: () => Navigator.pop(route),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '节日按设备本地日期判断，农历与节气离线计算。此处为节日文化问候，不代表各国放假或调休安排。',
                    style: TextStyle(fontSize: 11, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Original quote collection remains available here rather than on the home page.
class DailyQuote extends StatefulWidget {
  const DailyQuote({super.key});
  @override
  State<DailyQuote> createState() => _DailyQuoteState();
}

class _DailyQuoteState extends State<DailyQuote> {
  List<dynamic> quotes = const [
    ['千里之行，始于足下。', '老子'],
  ];
  int index = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/quotes.json'),
      );
      if (mounted && data is List && data.isNotEmpty) {
        setState(() {
          quotes = data;
          final now = DateTime.now();
          index =
              DateTime.utc(
                now.year,
                now.month,
                now.day,
              ).difference(DateTime.utc(2020)).inDays %
              quotes.length;
        });
      }
    } catch (_) {
      /* The bundled fallback remains readable. */
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('settings-daily-quote'),
    tilePadding: EdgeInsets.zero,
    title: const Text('每日一句', style: TextStyle(fontSize: 15)),
    subtitle: const Text('阅读或换一句摘录', style: TextStyle(fontSize: 12)),
    childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${quotes[index][0]}',
          style: const TextStyle(fontSize: 16, height: 1.7),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              '— ${quotes[index][1]}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () =>
                setState(() => index = (index + 1) % quotes.length),
            child: const Text('换一句'),
          ),
        ],
      ),
    ],
  );
}
