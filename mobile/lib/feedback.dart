import 'dart:async';

import 'package:flutter/material.dart';

import 'motion.dart';

OverlayEntry? _activeNotice;
OverlayState? _noticeOverlay;

/// Short, nonmodal feedback at the top. The bottom navigation stays reachable.
void showJournalMessage(BuildContext context, SnackBar message) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (_activeNotice != null && _noticeOverlay?.mounted == true) {
    _activeNotice?.remove();
    _activeNotice?.dispose();
  }
  final themes = InheritedTheme.capture(from: context, to: overlay.context);
  final top = MediaQuery.viewPaddingOf(context).top + kToolbarHeight + 12;
  final reduced = MotionScope.off(context);
  late final OverlayEntry entry;
  void remove() {
    if (_activeNotice != entry) return;
    _activeNotice = null;
    _noticeOverlay = null;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: top,
      left: 16,
      right: 16,
      child: themes.wrap(
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _JournalNotice(
              message: message,
              reduced: reduced,
              onClose: remove,
              onGone: () {
                if (_activeNotice == entry) {
                  _activeNotice = null;
                  _noticeOverlay = null;
                }
              },
            ),
          ),
        ),
      ),
    ),
  );
  _activeNotice = entry;
  _noticeOverlay = overlay;
  overlay.insert(entry);
}

class _JournalNotice extends StatefulWidget {
  final SnackBar message;
  final bool reduced;
  final VoidCallback onClose, onGone;
  const _JournalNotice({
    required this.message,
    required this.reduced,
    required this.onClose,
    required this.onGone,
  });
  @override
  State<_JournalNotice> createState() => _JournalNoticeState();
}

class _JournalNoticeState extends State<_JournalNotice>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.reduced ? 0 : 180),
  );
  Timer? timer;
  @override
  void initState() {
    super.initState();
    controller.forward();
    timer = Timer(
      Duration(seconds: widget.message.action == null ? 2 : 3),
      close,
    );
  }

  Future<void> close() async {
    timer?.cancel();
    if (!mounted) return;
    await controller.reverse();
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    widget.onGone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: controller,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -.12), end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        ),
        child: Material(
          key: const ValueKey('journal-notice'),
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(14),
          elevation: 3,
          child: Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 4,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: colors.onInverseSurface,
                        fontSize: 13,
                      ),
                      child: widget.message.content,
                    ),
                  ),
                  if (widget.message.action case final action?)
                    TextButton(
                      onPressed: () {
                        close();
                        action.onPressed();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.inversePrimary,
                      ),
                      child: Text(action.label),
                    ),
                  IconButton(
                    tooltip: '关闭提示',
                    icon: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: colors.onInverseSurface,
                    ),
                    onPressed: close,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
