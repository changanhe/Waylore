import 'feedback.dart';
import 'i18n.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'look.dart';
import 'motion.dart';
import 'store.dart';

class CollectionScreen extends StatefulWidget {
  final String initialKind;
  final JournalStore store;
  final AppPalette palette;
  final bool reduced;
  final Widget Function(Entry, {double? height}) photo;
  final Widget Function(Entry) card;
  final Future<void> Function(String, {Entry? entry}) onEdit;
  final Future<void> Function(Entry) onDetail;
  const CollectionScreen({
    super.key,
    this.initialKind = 'movie',
    required this.store,
    required this.palette,
    required this.reduced,
    required this.photo,
    required this.card,
    required this.onEdit,
    required this.onDetail,
  });
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with WidgetsBindingObserver {
  late String kind = widget.initialKind;
  final controller = PageController(viewportFraction: .82);
  Timer? timer;
  bool interacting = false, resumed = true;
  final flipped = <String>{};
  double position = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      final n = widget.store.of(kind).length;
      if (!mounted ||
          !resumed ||
          widget.reduced ||
          interacting ||
          flipped.isNotEmpty ||
          n < 2 ||
          !controller.hasClients ||
          !(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }
      controller.animateToPage(
        ((controller.page ?? 0).round() + 1) % n,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    resumed = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> remove(Entry e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const LocalText('删除这条收藏？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const LocalText('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const LocalText('删除'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await widget.store.remove(e);
      flipped.remove(e.id);
      if (mounted) {
        showJournalMessage(
          context,
          SnackBar(
            content: const LocalText('收藏已删除'),
            action: SnackBarAction(
              label: '撤销',
              onPressed: () async {
                try {
                  await widget.store.save(e);
                } catch (_) {
                  if (mounted) {
                    showJournalMessage(
                      context,
                      const SnackBar(content: LocalText('恢复失败，请重试')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showJournalMessage(
          context,
          const SnackBar(content: LocalText('删除失败，记录仍保留')),
        );
      }
    }
  }

  Widget collectionCard(Entry e) {
    final p = widget.palette;
    final desktop = e.data['_desktop'] as Map? ?? {};
    final basic = <String, String>{
      '日期': e.text('date'),
      '评分': e.text('rating').isEmpty ? '' : '${e.text('rating')} / 5',
      if (e.kind == 'movie') ...{
        '类别': e.text('category'),
        '导演': '${desktop['director'] ?? ''}',
        '主演': e.text('actors').isNotEmpty
            ? e.text('actors')
            : '${desktop['actors'] ?? desktop['cast'] ?? ''}',
        '类型': '${desktop['genre'] ?? ''}',
        '地区': '${desktop['country'] ?? ''}',
        '年份': '${desktop['year'] ?? ''}',
      },
      if (e.kind == 'food') ...{'地点': e.text('place'), '价格': e.text('price')},
    }..removeWhere((_, v) => v.isEmpty);
    Widget paper(Widget child) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.accent.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    return FlipCard(
      key: ValueKey('collection-${e.id}'),
      semanticLabel: '收藏',
      reduced: widget.reduced,
      swipeToFlip: false,
      onFlipped: (back) => setState(() {
        back ? flipped.add(e.id) : flipped.remove(e.id);
      }),
      front: paper(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: p.ink.withValues(alpha: .04),
                child: widget.photo(e),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.text('title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  if (e.kind == 'movie' && (basic['主演'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      basic['主演']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: p.ink.withValues(alpha: .65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      back: paper(
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.text('title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final row in basic.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  row.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.ink.withValues(alpha: .55),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row.value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (Uri.tryParse(e.text('posterUrl'))?.scheme == 'https')
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(e.text('posterUrl')),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(
                            e.text('posterSource').isEmpty
                                ? '海报来源'
                                : e.text('posterSource'),
                          ),
                        ),
                      const Divider(height: 26),
                      Text(
                        e.kind == 'movie' ? '观看感悟' : '食光感想',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.text('note').isEmpty
                            ? '还没有写下感想，点击编辑补充。'
                            : e.text('note'),
                        style: const TextStyle(height: 1.7, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => widget.onEdit(e.kind, entry: e),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const LocalText('编辑'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '删除收藏',
                    onPressed: () => remove(e),
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  ),
                ],
              ),
              LocalText(
                '轻触空白处翻回封面',
                style: TextStyle(
                  fontSize: 10,
                  color: p.ink.withValues(alpha: .5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.store.of(kind);
    final activePage = list.isEmpty
        ? 0
        : position.round().clamp(0, list.length - 1);
    final indicatorStart = (activePage - 4).clamp(
      0,
      list.length > 9 ? list.length - 9 : 0,
    );
    final deck = SizedBox(
      height: (MediaQuery.sizeOf(context).height * .56).clamp(390.0, 520.0),
      child: Listener(
        onPointerDown: (_) => interacting = true,
        onPointerUp: (_) => interacting = false,
        onPointerCancel: (_) => interacting = false,
        child: PageView.builder(
          controller: controller,
          itemCount: list.length,
          onPageChanged: (index) => setState(() => position = index.toDouble()),
          itemBuilder: (c, i) {
            final e = list[i];
            return AnimatedBuilder(
              animation: controller,
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 10,
                  ),
                  child: collectionCard(e),
                ),
              ),
              builder: (context, child) {
                final page =
                    controller.positions.length == 1 &&
                        controller.position.hasContentDimensions
                    ? controller.page ?? 0
                    : 0.0;
                final d = (i - page).clamp(-1.0, 1.0);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0012)
                    ..rotateY(widget.reduced ? 0 : d * -.18)
                    ..translateByDouble(
                      0,
                      widget.reduced ? 0 : d.abs() * 12,
                      0,
                      1,
                    ),
                  child: Transform.scale(
                    scale: widget.reduced ? 1 : 1 - d.abs() * .045,
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: [
        SectionHead(
          'THE THINGS THAT STAY',
          '生活的余韵',
          action: PressFeedback(
            reduced: widget.reduced,
            child: IconButton.filled(
              onPressed: () => widget.onEdit(kind),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: widget.palette.ink.withValues(alpha: .045),
              borderRadius: BorderRadius.circular(22),
            ),
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  AnimatedAlign(
                    alignment: kind == 'movie'
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: Duration(milliseconds: widget.reduced ? 0 : 300),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: box.maxWidth / 2,
                      height: 54,
                      decoration: BoxDecoration(
                        color: widget.palette.paper,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final category in ['movie', 'food'])
                        Expanded(
                          child: Semantics(
                            selected: kind == category,
                            button: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                if (kind == category) {
                                  return;
                                }
                                if (controller.hasClients) {
                                  controller.jumpToPage(0);
                                }
                                setState(() {
                                  kind = category;
                                  position = 0;
                                  flipped.clear();
                                });
                              },
                              child: SizedBox(
                                height: 54,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedRotation(
                                      turns: kind == category ? 0 : -.06,
                                      duration: Duration(
                                        milliseconds: widget.reduced ? 0 : 260,
                                      ),
                                      child: Icon(
                                        category == 'movie'
                                            ? Icons.movie_outlined
                                            : Icons.restaurant_outlined,
                                        size: 18,
                                        color: kind == category
                                            ? widget.palette.accent
                                            : widget.palette.ink.withValues(
                                                alpha: .4,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: LocalText(
                                        category == 'movie' ? '影视收藏' : '食光小记',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: kind == category
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      '${widget.store.of(category).length}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (list.isEmpty)
          EmptyPage(
            icon: kind == 'movie'
                ? Icons.theaters_outlined
                : Icons.local_dining_outlined,
            title: kind == 'movie' ? '留住散场后的感受' : '记得那一口的味道',
            subtitle: '从一张照片、一句话开始。',
            onAdd: () => widget.onEdit(kind),
          )
        else ...[
          Reveal(child: deck),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (
                var i = indicatorStart;
                i < list.length && i < indicatorStart + 9;
                i++
              )
                AnimatedContainer(
                  duration: Duration(milliseconds: widget.reduced ? 0 : 240),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  width: activePage == i ? 22 : 5,
                  decoration: BoxDecoration(
                    color: widget.palette.accent.withValues(
                      alpha: activePage == i ? 1 : .2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                '${activePage + 1} / ${list.length}',
                style: TextStyle(fontSize: 11, color: widget.palette.accent),
              ),
            ],
          ),
          if (list.length > 1) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) => Tooltip(
                  message: list[index].text('title'),
                  child: Semantics(
                    button: true,
                    selected: activePage == index,
                    label: list[index].text('title'),
                    child: InkWell(
                      onTap: () {
                        if (widget.reduced) {
                          controller.jumpToPage(index);
                        } else {
                          controller.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: Duration(
                          milliseconds: widget.reduced ? 0 : 220,
                        ),
                        width: 48,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activePage == index
                                ? widget.palette.accent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.photo(list[index]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: LocalText(
              '轻触翻面查看感悟 · 左右滑动切换',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}
