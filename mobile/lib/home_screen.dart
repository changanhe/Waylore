import 'festival_ui.dart';
import 'i18n.dart';
import 'motion.dart';
import 'adaptive_layout.dart';

import 'package:flutter/material.dart';

import 'weather.dart';
import 'atlas.dart';
import 'look.dart';
import 'store.dart';

class JournalHome extends StatefulWidget {
  final JournalStore store;
  final AtlasData atlas;
  final AppPalette palette;
  final VoidCallback onTravel, onTickets, onFood, onMovies, onBooks;
  final Widget? recovery;
  const JournalHome({
    super.key,
    required this.store,
    required this.atlas,
    required this.palette,
    required this.onTravel,
    required this.onTickets,
    required this.onFood,
    required this.onMovies,
    required this.onBooks,
    this.recovery,
  });
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  AppPalette get p => widget.palette;

  String get greet {
    final h = DateTime.now().hour;
    return h < 5 || h >= 23
        ? '夜深了'
        : h < 9
        ? '早上好'
        : h < 13
        ? '中午好'
        : h < 18
        ? '下午好'
        : '晚上好';
  }

  String get dateLabel {
    final n = DateTime.now();
    return '${n.year}年${n.month}月${n.day}日  星期${'一二三四五六日'[n.weekday - 1]}';
  }

  Widget surface(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: p.paper.withValues(alpha: .84),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: p.ink.withValues(alpha: .08)),
    ),
    child: child,
  );

  Widget shortcut(
    String label,
    String hint,
    IconData icon,
    VoidCallback action,
  ) => PressFeedback(
    reduced: widget.store.settings['reduced'] == true,
    child: Material(
      color: p.paper.withValues(alpha: .82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          child: Row(
            children: [
              Icon(icon, size: 23, color: p.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalText(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LocalText(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: p.ink.withValues(alpha: .55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget sectionLabel(String title) => LocalText(
    title,
    style: const TextStyle(
      fontSize: 19,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget journalEntry() => Material(
    color: p.accent.withValues(alpha: p.dark ? .16 : .08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: p.accent.withValues(alpha: .2)),
    ),
    child: InkWell(
      onTap: widget.onBooks,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.paper,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.menu_book_outlined, size: 20, color: p.accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LocalText(
                    '旅行手账',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  LocalText(
                    '照片、文字与贴纸',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.ink.withValues(alpha: .5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: p.accent.withValues(alpha: .6),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => JournalDashboard(
    splitIndex: widget.recovery == null ? 8 : 10,
    children: [
      Text(
        greet,
        style: const TextStyle(
          fontSize: 26,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        dateLabel,
        style: TextStyle(fontSize: 11.5, color: p.ink.withValues(alpha: .55)),
      ),
      const SizedBox(height: 12),
      FestivalHomeCard(store: widget.store, palette: p, compact: true),
      const SizedBox(height: 18),
      if (widget.recovery != null) ...[
        widget.recovery!,
        const SizedBox(height: 12),
      ],
      WeatherPanel(store: widget.store, palette: p),
      const SizedBox(height: 14),
      sectionLabel('记录此刻'),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: shortcut(
              '旅行日志',
              '地点与故事',
              Icons.luggage_outlined,
              widget.onTravel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: shortcut(
              '旅程票根',
              '机票与车票',
              Icons.confirmation_number_outlined,
              widget.onTickets,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: shortcut(
              '食光小记',
              '一餐一味',
              Icons.restaurant_outlined,
              widget.onFood,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: shortcut(
              '影视收藏',
              '电影与剧',
              Icons.movie_filter_outlined,
              widget.onMovies,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      journalEntry(),
    ],
  );
}
