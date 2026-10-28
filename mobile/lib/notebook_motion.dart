import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum NotebookTurn {
  smooth('平滑', Icons.swipe_outlined),
  fold('折页', Icons.unfold_less_rounded),
  book('书页', Icons.auto_stories_outlined),
  fade('淡入', Icons.blur_on_rounded);

  final String label;
  final IconData icon;
  const NotebookTurn(this.label, this.icon);
  static NotebookTurn read(dynamic name) =>
      values.firstWhere((v) => v.name == name, orElse: () => fold);
}

class NotebookPageMotion extends StatelessWidget {
  final Widget child;
  final double distance;
  final NotebookTurn mode;
  final bool reduced;
  const NotebookPageMotion({
    super.key,
    required this.child,
    required this.distance,
    required this.mode,
    required this.reduced,
  });
  @override
  Widget build(BuildContext context) {
    final d = distance.clamp(-1.0, 1.0);
    if (reduced) return child;
    return switch (mode) {
      NotebookTurn.smooth => Transform.scale(
        scale: 1 - .035 * d.abs(),
        child: child,
      ),
      NotebookTurn.fade => Opacity(
        opacity: (1 - d.abs() * .8).clamp(0.0, 1.0),
        child: child,
      ),
      NotebookTurn.book => Transform(
        alignment: d < 0 ? Alignment.centerRight : Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0013)
          ..rotateY(-d * 1.1),
        child: child,
      ),
      NotebookTurn.fold => _FoldedPaper(amount: d.abs(), child: child),
    };
  }
}

/// Paint one laid-out page as two hinged halves. No duplicate element trees,
/// image decodes, global keys or semantics nodes are created while folding.
class _FoldedPaper extends SingleChildRenderObjectWidget {
  final double amount;
  const _FoldedPaper({required this.amount, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFold(amount);
  @override
  void updateRenderObject(BuildContext context, _RenderFold renderObject) =>
      renderObject.amount = amount;
}

class _RenderFold extends RenderProxyBox {
  double _amount;
  _RenderFold(this._amount);
  set amount(double value) {
    if (value == _amount) return;
    _amount = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (_amount < .001) {
      super.paint(context, offset);
      return;
    }
    final half = size.width / 2;
    final angle = _amount * math.pi * .40;
    for (var i = 0; i < 2; i++) {
      final transform = Matrix4.identity()
        ..setEntry(3, 2, .0007)
        ..translateByDouble(half, size.height / 2, 0, 1)
        ..rotateY(i == 0 ? angle : -angle)
        ..translateByDouble(-half, -size.height / 2, 0, 1);
      final clip = Rect.fromLTWH(i * half, 0, half, size.height);
      context.pushTransform(needsCompositing, offset, transform, (c, o) {
        c.pushClipRect(needsCompositing, o, clip, (c, o) {
          c.paintChild(child!, o);
          c.canvas.drawRect(
            clip.shift(o),
            Paint()
              ..color = Colors.black.withValues(
                alpha: _amount * (i == 0 ? .09 : .19),
              ),
          );
        });
      });
    }
  }
}
