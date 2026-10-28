import 'package:flutter/foundation.dart';
import 'platform_support.dart';
import 'privacy_page.dart';
import 'feedback.dart';
import 'festival_ui.dart';
import 'app_typography.dart';
import 'journal_navigation.dart';
import 'motion.dart';
import 'i18n.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'backup.dart';
import 'look.dart';
import 'profile_ui.dart';
import 'store.dart';

/// 我的 · 二级页共用顶栏。
class ProfilePageHeader extends StatelessWidget {
  final String title;
  final String kicker;
  final AppPalette palette;

  const ProfilePageHeader({
    super.key,
    required this.title,
    required this.kicker,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      children: [
        IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, size: 24, color: palette.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalText(
                title,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 3),
            ],
          ),
        ),
      ],
    ),
  );
}

/// 系统主题的放大选择卡：左边是主题的迷你预览，右边/下方是名称与选中态。
class ThemePreviewCard extends StatelessWidget {
  final AppPalette current;
  final AppPalette option;
  final bool selected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.current,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: Duration(milliseconds: MotionScope.off(context) ? 0 : 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: current.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? current.accent
                : current.ink.withValues(alpha: .08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: current.accent.withValues(alpha: .22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: option.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: option.ink.withValues(alpha: .08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 38,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: option.paper,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 4,
                          width: 16,
                          decoration: BoxDecoration(
                            color: option.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 4,
                          width: 13,
                          decoration: BoxDecoration(
                            color: option.ink.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: option.ink.withValues(alpha: .75),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: option.ink.withValues(alpha: .35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: 12,
                          width: 34,
                          decoration: BoxDecoration(
                            color: option.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LocalText(
                    option.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: current.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 16,
                  color: selected
                      ? current.accent
                      : current.ink.withValues(alpha: .3),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfileSettingsScreen extends StatefulWidget {
  final JournalStore store;
  const ProfileSettingsScreen({super.key, required this.store});
  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  int previewIndex = 0;
  final previewPulses = List.filled(5, 0);
  bool savingPreference = false;

  Future<void> preference(String key, dynamic value) async {
    if (savingPreference) return;
    savingPreference = true;
    try {
      await widget.store.setting(key, value);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        showJournalMessage(
          context,
          const SnackBar(content: LocalText('设置未保存，请重试')),
        );
      }
    } finally {
      savingPreference = false;
    }
  }

  Future<void> chooseLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: p.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: p.ink.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LocalText(
                        '语言 / Language',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(sheet)
                          .closeButtonTooltip,
                      onPressed: () => Navigator.pop(sheet),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final entry in AppLanguage.names.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppLanguage.current == entry.key
                          ? p.accent.withValues(alpha: .1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        key: ValueKey('language-option-${entry.key}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          entry.value,
                          locale: entry.key == 'zh-TW'
                              ? const Locale('zh', 'TW')
                              : Locale(entry.key),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: p.ink,
                          ),
                        ),
                        trailing: Icon(
                          AppLanguage.current == entry.key
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: AppLanguage.current == entry.key
                              ? p.accent
                              : p.ink.withValues(alpha: .25),
                        ),
                        onTap: () => Navigator.pop(sheet, entry.key),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) await preference('language', selected);
  }

  AppPalette get p =>
      AppPalette.all[(widget.store.settings['theme'] as int? ?? 0).clamp(
        0,
        AppPalette.all.length - 1,
      )];

  Future<void> pick(int i) async {
    try {
      await widget.store.setting('theme', i);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      showJournalMessage(
        context,
        const SnackBar(content: LocalText('主题未保存，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: p.background,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          key: const ValueKey('settings-responsive-width'),
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              ProfilePageHeader(title: '设置', kicker: 'PREFERENCES', palette: p),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
                  children: [
                    ListTile(
                      key: const ValueKey('settings-festivals'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.celebration_outlined,
                        color: p.accent,
                      ),
                      title: const Text('每日寄语与节日祝福'),
                      subtitle: const Text('今日寄语、节日开屏与祝福预览'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FestivalCenter(store: widget.store),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ProfileSectionHead(
                      kicker: 'APPEARANCE',
                      title: '系统主题',
                      palette: p,
                      trailing: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: p.ink.withValues(alpha: .5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocalText(
                      '选一个喜欢的配色，立即生效并记住。',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: p.ink.withValues(alpha: .5),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < AppPalette.all.length; i++)
                              SizedBox(
                                width: width,
                                child: ThemePreviewCard(
                                  current: p,
                                  option: AppPalette.all[i],
                                  selected: AppPalette.all[i].name == p.name,
                                  onTap: () => pick(i),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    ProfileSectionHead(
                      kicker: 'LANGUAGE',
                      title: '语言 / Language',
                      palette: p,
                    ),
                    const SizedBox(height: 12),
                    ProfilePaper(
                      palette: p,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        key: const ValueKey('settings-language'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        leading: Icon(Icons.translate_rounded, color: p.accent),
                        title: Text(
                          AppLanguage.names[AppLanguage.current]!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: p.ink,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: p.ink.withValues(alpha: .45),
                        ),
                        onTap: chooseLanguage,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ProfileSectionHead(
                      kicker: 'TYPOGRAPHY',
                      title: '阅读字体',
                      palette: p,
                    ),
                    const SizedBox(height: 12),
                    ProfilePaper(
                      palette: p,
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          for (final font in JournalFont.values)
                            ListTile(
                              key: ValueKey('font-option-${font.name}'),
                              selected:
                                  JournalFont.read(
                                    widget.store.settings['font'],
                                  ) ==
                                  font,
                              selectedTileColor: p.accent.withValues(
                                alpha: .08,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              title: LocalText(
                                font.label,
                                style: TextStyle(
                                  fontFamily: font.family ?? 'Roboto',
                                  fontSize: 17,
                                  height: 1.5,
                                  color: p.ink,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LocalText(
                                      '把旅途与日常，收进书里。',
                                      style: TextStyle(
                                        fontFamily: font.family ?? 'Roboto',
                                        fontSize: 15,
                                        height: 1.6,
                                        color: p.ink.withValues(alpha: .8),
                                      ),
                                    ),
                                    LocalText(
                                      font.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: p.ink.withValues(alpha: .55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(
                                JournalFont.read(
                                          widget.store.settings['font'],
                                        ) ==
                                        font
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color:
                                    JournalFont.read(
                                          widget.store.settings['font'],
                                        ) ==
                                        font
                                    ? p.accent
                                    : p.ink.withValues(alpha: .25),
                              ),
                              onTap: () => preference('font', font.name),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: '客行录',
                      ),
                      child: const LocalText('字体开源许可'),
                    ),
                    const SizedBox(height: 16),
                    ProfileSectionHead(
                      kicker: 'NAVIGATION',
                      title: '导航栏动效',
                      palette: p,
                    ),
                    const SizedBox(height: 12),
                    JournalNavigation(
                      selected: previewIndex,
                      onSelected: (index) => setState(() {
                        previewIndex = index;
                        previewPulses[index]++;
                      }),
                      palette: p,
                      reduced:
                          widget.store.settings['reduced'] == true ||
                          MediaQuery.disableAnimationsOf(context),
                      motion: NavigationMotion.read(
                        widget.store.settings['navigation_motion'],
                      ),
                      pulses: previewPulses,
                    ),
                    const SizedBox(height: 12),
                    ProfilePaper(
                      palette: p,
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          for (final motion in NavigationMotion.values)
                            ListTile(
                              key: ValueKey('navigation-motion-${motion.name}'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              selected:
                                  NavigationMotion.read(
                                    widget.store.settings['navigation_motion'],
                                  ) ==
                                  motion,
                              selectedTileColor: p.accent.withValues(
                                alpha: .08,
                              ),
                              title: LocalText(
                                motion.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: p.ink,
                                ),
                              ),
                              subtitle: LocalText(
                                motion.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: p.ink.withValues(alpha: .6),
                                ),
                              ),
                              trailing: Icon(
                                NavigationMotion.read(
                                          widget
                                              .store
                                              .settings['navigation_motion'],
                                        ) ==
                                        motion
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 20,
                                color:
                                    NavigationMotion.read(
                                          widget
                                              .store
                                              .settings['navigation_motion'],
                                        ) ==
                                        motion
                                    ? p.accent
                                    : p.ink.withValues(alpha: .25),
                              ),
                              onTap: () async {
                                await preference(
                                  'navigation_motion',
                                  motion.name,
                                );
                                if (mounted) {
                                  setState(() {
                                    previewIndex = previewIndex == 0 ? 3 : 0;
                                    previewPulses[previewIndex]++;
                                  });
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ProfileSectionHead(
                      kicker: 'MOTION',
                      title: '动效',
                      palette: p,
                    ),
                    const SizedBox(height: 12),
                    ProfilePaper(
                      palette: p,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ProfileSwitchRow(
                        palette: p,
                        title: '减少动态效果',
                        subtitle: '减少轮播与翻转动画',
                        value: widget.store.settings['reduced'] == true,
                        onChanged: (v) async {
                          try {
                            await widget.store.setting('reduced', v);
                            if (mounted) setState(() {});
                          } catch (_) {
                            if (!context.mounted) return;
                            showJournalMessage(
                              context,
                              const SnackBar(content: LocalText('设置未保存，请重试')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocalText(
                      '开启后，导航栏滑行、票夹轮播和卡片翻转将减少动态效果。',
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.6,
                        color: p.ink.withValues(alpha: .42),
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
}

class ProfileBackupScreen extends StatelessWidget {
  final JournalStore store;
  const ProfileBackupScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final p =
        AppPalette.all[(store.settings['theme'] as int? ?? 0).clamp(
          0,
          AppPalette.all.length - 1,
        )];
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfilePageHeader(title: '数据备份', kicker: 'BACKUP', palette: p),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
                children: [
                  const SizedBox(height: 8),
                  LocalText(
                    '把记录连同照片收进一份文件，需要时再导回。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: p.ink.withValues(alpha: .6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ProfilePaper(
                    palette: p,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ProfileActionRow(
                      palette: p,
                      icon: Icons.save_alt_rounded,
                      title: '导出本地备份',
                      subtitle: '生成一份包含照片的 JSON 文件，可保存到任意位置',
                      onTap: () => backupData(context, store),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 21,
                        color: p.ink.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ProfilePaper(
                    palette: p,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ProfileActionRow(
                      palette: p,
                      icon: Icons.restore_rounded,
                      title: '从备份导入',
                      subtitle: defaultTargetPlatform == TargetPlatform.windows ? '支持新版 JSON 与旧版电脑数据库，不清空现有记录' : '合并记录，不会清空现有内容',
                      onTap: () => backupData(context, store, restore: true),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 21,
                        color: p.ink.withValues(alpha: .35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: p.ink.withValues(alpha: .35),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LocalText(
                            '备份文件只保存在你选择的位置，客行录不会上传或接触它。建议导出后另存一份到电脑或云端盘。',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.7,
                              color: p.ink.withValues(alpha: .45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAboutScreen extends StatelessWidget {
  const ProfileAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.all.firstWhere(
            (e) => e.dark,
            orElse: () => AppPalette.all[6],
          )
        : AppPalette.all.first;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfilePageHeader(title: '关于', kicker: 'ABOUT', palette: palette),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/app-mark.svg',
                          width: 46,
                          height: 46,
                          colorFilter: ColorFilter.mode(
                            palette.accent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LocalText(
                    '客行录',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.3,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.background.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: palette.ink.withValues(alpha: .07),
                        ),
                      ),
                      child: LocalText(
                        platformVersionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: palette.ink.withValues(alpha: .65),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LocalText(
                    '把旅途与日常收进书里。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LocalText(
                    '记录地点、票根、食光、影视与手账。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: palette.ink.withValues(alpha: .55),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: palette.accent,
                    ),
                    title: const LocalText('隐私政策'),
                    subtitle: const LocalText('了解本地数据、权限与可选同步'),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.mail_outline_rounded,
                      color: palette.accent,
                    ),
                    title: const LocalText('联系与支持'),
                    subtitle: const LocalText('kexinglu@yeah.net'),
                    onTap: () async {
                      final opened = await launchUrl(
                        Uri(scheme: 'mailto', path: 'kexinglu@yeah.net'),
                      );
                      if (!opened && context.mounted) {
                        showJournalMessage(
                          context,
                          const SnackBar(
                            content: LocalText('请发送邮件至 kexinglu@yeah.net'),
                          ),
                        );
                      }
                    },
                  ),
                  ProfilePaper(
                    palette: palette,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalText(
                          '关于数据与隐私',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LocalText(
                          '记录默认保存在本机，账号与云同步可选。卸载前请先备份；完整说明见隐私政策。',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: palette.ink.withValues(alpha: .5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  LocalText(
                    '客行录 · 本地珍藏',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: palette.ink.withValues(alpha: .38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
