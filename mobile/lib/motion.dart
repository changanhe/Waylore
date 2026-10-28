import 'package:flutter/material.dart';

/// Brief touch feedback only; no repeating controller or background ticker.
class PressFeedback extends StatefulWidget {
  final Widget child;
  final bool reduced;
  const PressFeedback({super.key, required this.child, this.reduced = false});
  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool pressed = false;
  Offset? start;
  void release() {
    if (pressed && mounted) setState(() => pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = widget.reduced || MotionScope.off(context);
    return Listener(
      onPointerDown: (e) {
        start = e.position;
        if (!reduced) setState(() => pressed = true);
      },
      onPointerMove: (e) {
        if (start != null && (e.position - start!).distance > 8) release();
      },
      onPointerUp: (_) => release(),
      onPointerCancel: (_) => release(),
      child: AnimatedScale(
        scale: pressed && !reduced ? 0.975 : 1,
        duration: Duration(milliseconds: reduced ? 0 : 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// A single entrance animation, with its subtree cached between frames.
class MotionScope extends InheritedWidget {
  final bool reduced;
  const MotionScope({super.key, required this.reduced, required super.child});
  static bool off(BuildContext c) =>
      (c.dependOnInheritedWidgetOfExactType<MotionScope>()?.reduced ?? false) ||
      MediaQuery.disableAnimationsOf(c);
  @override
  bool updateShouldNotify(MotionScope oldWidget) =>
      reduced != oldWidget.reduced;
}

class Reveal extends StatelessWidget {
  final Widget child;
  const Reveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (MotionScope.off(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class JournalPageTransitions extends PageTransitionsBuilder {
  const JournalPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MotionScope.off(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.035, .015),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
