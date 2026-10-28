import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'i18n.dart';
import 'motion.dart';

enum AuthFeedback { idle, working, success, error }

class AuthModeTransition extends StatelessWidget {
  final Widget child;
  const AuthModeTransition({super.key, required this.child});
  @override
  Widget build(BuildContext context) => MotionScope.off(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: child,
          ),
        );
}

class AuthHero extends StatefulWidget {
  final AuthFeedback feedback;
  final int pulse;
  final bool signedIn;
  const AuthHero({
    super.key,
    required this.feedback,
    required this.pulse,
    required this.signedIn,
  });
  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero> with TickerProviderStateMixin {
  late final entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final response = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MotionScope.off(context);
    if (reduced) {
      entrance.value = 1;
      response.stop();
      response.value = 1;
    } else {
      if (entrance.value == 0) entrance.forward();
      if (widget.feedback == AuthFeedback.working && !response.isAnimating) {
        response.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(AuthHero old) {
    super.didUpdateWidget(old);
    if (widget.feedback != old.feedback || widget.pulse != old.pulse) {
      response.stop();
      if (!reduced) {
        if (widget.feedback == AuthFeedback.working) {
          response.repeat();
        } else {
          response.forward(from: 0);
        }
      }
    }
  }

  @override
  void dispose() {
    entrance.dispose();
    response.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: SizedBox(
        height: 162,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([entrance, response]),
          builder: (context, _) {
            final entry = Curves.easeOutCubic.transform(entrance.value);
            final wave = reduced ? 0.0 : math.sin(response.value * math.pi);
            final error = widget.feedback == AuthFeedback.error;
            final success =
                widget.feedback == AuthFeedback.success || widget.signedIn;
            final ink = error ? colors.error : colors.primary;
            return Opacity(
              opacity: entry,
              child: Transform.translate(
                offset: Offset(
                  error && !reduced
                      ? math.sin(response.value * math.pi * 8) * wave * 5
                      : 0,
                  (1 - entry) * 20 -
                      (widget.feedback == AuthFeedback.working && !reduced
                          ? wave * 6
                          : 0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AuthOrbits(
                          color: ink,
                          progress: response.value,
                          entry: entry,
                          working: widget.feedback == AuthFeedback.working,
                          success: success,
                          reduced: reduced,
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: reduced ? 0 : (1 - entry) * -.15,
                      child: Transform.scale(
                        scale: .85 + entry * .15 + (success ? wave * .07 : 0),
                        child: Container(
                          width: 88,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color.lerp(colors.surface, ink, .1)!,
                                Color.lerp(colors.surface, ink, .025)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: ink.withValues(alpha: .25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ink.withValues(alpha: .16),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: reduced ? 0 : 300),
                            transitionBuilder: (child, a) => ScaleTransition(
                              scale: a,
                              child: FadeTransition(opacity: a, child: child),
                            ),
                            child: success
                                ? Icon(
                                    Icons.check_rounded,
                                    key: const ValueKey('auth-success-mark'),
                                    size: 44,
                                    color: ink,
                                  )
                                : error
                                ? Icon(
                                    Icons.lock_reset_rounded,
                                    key: const ValueKey('auth-error-mark'),
                                    size: 40,
                                    color: ink,
                                  )
                                : Center(
                                    key: const ValueKey('auth-brand-mark'),
                                    child: SvgPicture.asset(
                                      'assets/app-mark.svg',
                                      width: 42,
                                      height: 42,
                                      colorFilter: ColorFilter.mode(
                                        ink,
                                        BlendMode.srcIn,
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
            );
          },
        ),
      ),
    );
  }
}

class _AuthOrbits extends CustomPainter {
  final Color color;
  final double progress, entry;
  final bool working, success, reduced;
  _AuthOrbits({
    required this.color,
    required this.progress,
    required this.entry,
    required this.working,
    required this.success,
    required this.reduced,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final radius = 58.0 + i * 18;
      paint.color = color.withValues(alpha: .15 - i * .035);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2.8 * entry,
          height: radius * 1.65 * entry,
        ),
        paint,
      );
    }
    for (var i = 0; i < 6; i++) {
      final angle =
          i * math.pi / 3 + (working && !reduced ? progress * math.pi * 2 : .3);
      final point =
          center + Offset(math.cos(angle) * 108, math.sin(angle) * 61);
      canvas.drawCircle(
        point,
        i.isEven ? 3.2 : 2,
        paint
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: .3 + (i.isEven ? .25 : 0)),
      );
    }
    if (success && !reduced) {
      paint.strokeWidth = 2;
      final t = Curves.easeOutCubic.transform(progress);
      for (var i = 0; i < 16; i++) {
        final angle = i * math.pi / 8;
        final distance = 50 + t * 65;
        final point =
            center +
            Offset(
              math.cos(angle) * distance * 1.3,
              math.sin(angle) * distance * .7,
            );
        paint.color = color.withValues(alpha: (1 - progress) * .8);
        canvas.drawCircle(point, 2 + (i % 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuthOrbits old) =>
      old.progress != progress ||
      old.entry != entry ||
      old.color != color ||
      old.success != success ||
      old.working != working ||
      old.reduced != reduced;
}

class AuthSubmitButton extends StatelessWidget {
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  const AuthSubmitButton({
    super.key,
    required this.busy,
    required this.label,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = MotionScope.off(context);
    return SizedBox(
      height: 56,
      child: AnimatedContainer(
        duration: Duration(milliseconds: reduced ? 0 : 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: busy
              ? []
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: FilledButton(
          key: const ValueKey('auth-submit'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            disabledBackgroundColor: colors.primary.withValues(alpha: .65),
            disabledForegroundColor: colors.onPrimary,
          ),
          onPressed: busy ? null : onPressed,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: reduced ? 0 : 220),
            child: Row(
              key: ValueKey(busy),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy && !reduced) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: LocalText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!busy) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthStatusPanel extends StatelessWidget {
  final AuthFeedback feedback;
  final Widget child;
  const AuthStatusPanel({
    super.key,
    required this.feedback,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = feedback == AuthFeedback.error
        ? colors.error
        : colors.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              feedback == AuthFeedback.error
                  ? Icons.info_outline_rounded
                  : feedback == AuthFeedback.success
                  ? Icons.check_circle_outline_rounded
                  : Icons.cloud_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
