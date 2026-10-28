import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'i18n.dart';
import 'look.dart';
import 'nav_icon.dart';

enum NavigationMotion {
  glide('流光滑行', '胶囊顺着切换方向平滑流动'),
  spring('弹性胶囊', '带一点回弹的灵动滑行'),
  lift('轻盈浮起', '切换时轻轻浮起再落下'),
  fade('柔和淡入', '低调柔和的明暗过渡');

  final String label, description;
  const NavigationMotion(this.label, this.description);
  static NavigationMotion read(dynamic value) =>
      values.where((m) => m.name == value).firstOrNull ?? glide;
}

class JournalNavigation extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  final AppPalette palette;
  final bool reduced;
  final NavigationMotion motion;
  final List<int> pulses;
  const JournalNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.palette,
    required this.reduced,
    required this.motion,
    required this.pulses,
  });
  @override
  State<JournalNavigation> createState() => _JournalNavigationState();
}

class _JournalNavigationState extends State<JournalNavigation>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late double from = widget.selected.toDouble(), to = from;
  double? dragging;
  Curve get curve => widget.motion == NavigationMotion.spring
      ? Curves.easeOutBack
      : Curves.easeInOutCubic;
  double get position =>
      dragging ?? from + (to - from) * curve.transform(controller.value);
  void move(int index) {
    from = position;
    to = index.toDouble();
    dragging = null;
    controller.duration = Duration(
      milliseconds: widget.reduced
          ? 0
          : widget.motion == NavigationMotion.spring
          ? 620
          : 480,
    );
    controller.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    controller.value = 1;
  }

  @override
  void didUpdateWidget(JournalNavigation old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected || old.motion != widget.motion) {
      move(widget.selected);
    }
    if (widget.reduced) {
      from = to = widget.selected.toDouble();
      dragging = null;
      controller.value = 1;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    const icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.confirmation_number_outlined,
      Icons.bookmarks_outlined,
      Icons.person_outline_rounded,
    ];
    const labels = ['首页', '旅途', '票夹', '收藏', '我的'];
    return Glass(
      color: p.paper,
      child: SizedBox(
        height: 76,
        child: LayoutBuilder(
          builder: (context, box) {
            final cell = (box.maxWidth - 12) / 5;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                final current = position;
                controller.stop();
                setState(() => dragging = current);
              },
              onHorizontalDragUpdate: (event) => setState(
                () =>
                    dragging = ((dragging ?? position) + event.delta.dx / cell)
                        .clamp(0.0, 4.0),
              ),
              onHorizontalDragEnd: (event) {
                final destination =
                    ((dragging ?? position) +
                            (event.primaryVelocity ?? 0).clamp(-600.0, 600.0) /
                                1800)
                        .round()
                        .clamp(0, 4);
                widget.onSelected(destination);
                setState(() => move(destination));
              },
              onHorizontalDragCancel: () =>
                  setState(() => move(widget.selected)),
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final wave = widget.reduced || dragging != null
                          ? 0.0
                          : math.sin(controller.value * math.pi);
                      final stretch = widget.motion == NavigationMotion.glide
                          ? wave * .18
                          : 0.0;
                      final width = cell - 6 + cell * stretch;
                      final left = (9 + cell * position - cell * stretch / 2)
                          .clamp(4.0, math.max(4.0, box.maxWidth - width - 4))
                          .toDouble();
                      return Positioned(
                        left: left,
                        top:
                            8 -
                            (widget.motion == NavigationMotion.lift
                                ? wave * 5
                                : 0),
                        width: width,
                        height: 60,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: widget.motion == NavigationMotion.fade
                                ? 1 - wave * .65
                                : 1,
                            child: DecoratedBox(
                              key: const ValueKey('navigation-moving-pill'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(23),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    p.accent.withValues(
                                      alpha: p.dark ? .28 : .19,
                                    ),
                                    p.accent.withValues(alpha: .08),
                                  ],
                                ),
                                border: Border.all(
                                  color: p.accent.withValues(alpha: .3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: List.generate(
                        5,
                        (i) => Expanded(
                          child: Semantics(
                            selected: widget.selected == i,
                            button: true,
                            label: tr(labels[i]),
                            excludeSemantics: true,
                            onTap: () => widget.onSelected(i),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: ValueKey('navigation-tab-$i'),
                                // The shared sliding glass pill is the touch feedback.
                                // Per-tab ink leaves circular patches along its path.
                                splashFactory: NoSplash.splashFactory,
                                overlayColor: const WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => widget.onSelected(i),
                                child: SizedBox(
                                  height: 76,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedNavIcon(
                                        icon: icons[i],
                                        index: i,
                                        pulse: widget.pulses[i],
                                        reduced: widget.reduced,
                                        color: widget.selected == i
                                            ? p.accent
                                            : p.ink.withValues(alpha: .55),
                                      ),
                                      const SizedBox(height: 5),
                                      LocalText(
                                        labels[i],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.3,
                                          fontWeight: widget.selected == i
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: widget.selected == i
                                              ? p.accent
                                              : p.ink.withValues(alpha: .65),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
