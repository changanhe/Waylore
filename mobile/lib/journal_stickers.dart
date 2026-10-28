import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JournalSticker {
  final String id, name, group;
  final double ratio;
  const JournalSticker(this.id, this.name, this.group, this.ratio);
  String get value => 'decal:$id';
  String get asset => 'assets/stickers/$id.svg';
}

const journalStickers = [
  JournalSticker('bunny', '奶糖兔', '软萌伙伴', 1),
  JournalSticker('cat', '草莓猫', '软萌伙伴', 1),
  JournalSticker('capy', '橘子水豚', '软萌伙伴', 1),
  JournalSticker('bear', '蜂蜜小熊', '软萌伙伴', 1),
  JournalSticker('duck', '出游鸭', '软萌伙伴', 1),
  JournalSticker('puppy', '奶油小狗', '软萌伙伴', 1),
  JournalSticker('camera', '旅行相机', '旅途出发', 1),
  JournalSticker('pack', '远行背包', '旅途出发', 1),
  JournalSticker('train', '山间列车', '旅途出发', 1),
  JournalSticker('plane', '云上飞行', '旅途出发', 1),
  JournalSticker('tent', '松林露营', '旅途出发', 1),
  JournalSticker('compass', '心向远方', '旅途出发', 1),
  JournalSticker('daisy', '晴日雏菊', '花草野趣', 1),
  JournalSticker('tulip', '春日郁金香', '花草野趣', 1),
  JournalSticker('mushroom', '森林蘑菇', '花草野趣', 1),
  JournalSticker('leaf', '银杏来信', '花草野趣', 1),
  JournalSticker('butterfly', '花间蝴蝶', '花草野趣', 1),
  JournalSticker('mountain', '山野日记', '花草野趣', 1),
  JournalSticker('cloud', '软绵云朵', '天空与心情', 1),
  JournalSticker('rainbow', '好天气彩虹', '天空与心情', 1),
  JournalSticker('moon', '晚安月亮', '天空与心情', 1),
  JournalSticker('planet', '银河漫游', '天空与心情', 1),
  JournalSticker('bow', '奶油蝴蝶结', '天空与心情', 1),
  JournalSticker('balloon', '心动气球', '天空与心情', 1),
  JournalSticker('ticket', '远行票根', '拼贴纸品', 1),
  JournalSticker('stamp', '山海邮票', '拼贴纸品', 1),
  JournalSticker('postcard', '旅途明信片', '拼贴纸品', 1),
  JournalSticker('kraft', '撕边牛皮纸', '拼贴纸品', 1),
  JournalSticker('polaroid', '空白拍立得', '拼贴纸品', 1),
  JournalSticker('memo', '格纹便签', '拼贴纸品', 1),
  JournalSticker('tape-dots', '奶油波点', '和纸胶带', 3),
  JournalSticker('tape-stripe', '海风条纹', '和纸胶带', 3),
  JournalSticker('tape-gingham', '野餐格纹', '和纸胶带', 3),
  JournalSticker('tape-flower', '碎花纸胶带', '和纸胶带', 3),
  JournalSticker('tape-star', '星光胶带', '和纸胶带', 3),
  JournalSticker('tape-wave', '海浪胶带', '和纸胶带', 3),
  JournalSticker('tape-heart', '心动胶带', '和纸胶带', 3),
  JournalSticker('tape-leaf', '枝叶胶带', '和纸胶带', 3),
];
JournalSticker? journalSticker(String value) {
  for (final sticker in journalStickers) {
    if (sticker.value == value) return sticker;
  }
  return null;
}

Widget stickerArt(JournalSticker sticker, {double? width, double? height}) =>
    SvgPicture.asset(
      sticker.asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: sticker.name,
    );
Future<String> stickerExportImage(JournalSticker sticker) async {
  final svg = await rootBundle.loadString(sticker.asset);
  return '<img alt="${sticker.name}" src="data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}" style="width:100%;height:auto">';
}

Future<void> showStickerStudio(
  BuildContext context,
  void Function(JournalSticker) insert,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => StickerStudio(onInsert: insert),
);

class StickerStudio extends StatefulWidget {
  final void Function(JournalSticker) onInsert;
  const StickerStudio({super.key, required this.onInsert});
  @override
  State<StickerStudio> createState() => _StickerStudioState();
}

class _StickerStudioState extends State<StickerStudio> {
  String group = journalStickers.first.group;
  String? last;
  int added = 0;
  final pages = PageController();
  final tabs = ScrollController();
  final categories = journalStickers.map((s) => s.group).toSet().toList();
  @override
  void dispose() {
    pages.dispose();
    tabs.dispose();
    super.dispose();
  }

  void chooseGroup(int index) {
    pages.animateToPage(
      index,
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
      ),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: .84,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '旅途素材铺',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        added == 0
                            ? '${journalStickers.length} 款原创图形 · 轻点贴入书页'
                            : '已贴入 $added 枚 · 可继续挑选',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.8,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView.separated(
              key: const ValueKey('sticker-category-tabs'),
              controller: tabs,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final name = categories.elementAt(i);
                return Center(
                  child: ChoiceChip(
                    label: Text(name),
                    selected: group == name,
                    onSelected: (_) => chooseGroup(i),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('sticker-category-pages'),
              controller: pages,
              itemCount: categories.length,
              onPageChanged: (index) {
                setState(() {
                  group = categories[index];
                  last = null;
                });
                if (tabs.hasClients) {
                  tabs.animateTo(
                    tabs.position.maxScrollExtent *
                        index /
                        (categories.length - 1),
                    duration: Duration(
                      milliseconds: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 180,
                    ),
                    curve: Curves.easeOut,
                  );
                }
              },
              itemBuilder: (_, categoryIndex) {
                final entries = journalStickers
                    .where((s) => s.group == categories[categoryIndex])
                    .toList();
                return LayoutBuilder(
                  builder: (_, box) => GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: box.maxWidth > 600
                          ? 5
                          : box.maxWidth < 340
                          ? 2
                          : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 132,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final sticker = entries[i];
                      return Semantics(
                        button: true,
                        label: '贴入${sticker.name}',
                        child: Material(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              widget.onInsert(sticker);
                              setState(() {
                                last = sticker.id;
                                added++;
                              });
                              if (!MediaQuery.disableAnimationsOf(context)) {
                                HapticFeedback.selectionClick();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: stickerArt(
                                        sticker,
                                        width: 90,
                                        height: 82,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (last == sticker.id) ...[
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                      Flexible(
                                        child: Text(
                                          sticker.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: '上一组素材',
                  onPressed: group == categories.first
                      ? null
                      : () => chooseGroup(categories.indexOf(group) - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${categories.indexOf(group) + 1} / ${categories.length} · 左右滑动切换',
                  style: const TextStyle(fontSize: 11),
                ),
                IconButton(
                  tooltip: '下一组素材',
                  onPressed: group == categories.last
                      ? null
                      : () => chooseGroup(categories.indexOf(group) + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              '轻点贴入，左右滑动换组，上下浏览；书页素材可旋转缩放。',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
