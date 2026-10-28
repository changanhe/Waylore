# 客行录安卓 · 旅途随身听与个性背景

版本 1.0.0，安卓内部构建号 43。仅本地交付，不更新 GitHub 或网站。

## 体验入口
- 路途 → 打开一条旅行记录，在照片上方选择背景音乐。
- 旅行手账 → 打开一本手账，在页码上方选择背景音乐。
- 我的 → 编辑资料 → 个性背景，按「软萌治愈／旅行风景／梦幻与极简」选择，最后点保存。

四首内置离线纯音乐：林间晨光、海岸慢行、星河来信、草莓野餐。均为本项目合成的原创器乐小品，约 40 秒，可循环，不含第三方录音或商业歌曲。支持播放/暂停、音量、循环；设置后立即播放，此后每次打开相应手账或图册会自动播放；可手动暂停，离开页面或进入后台暂停。

支持导入不超过 50 MB 的 MP3，导入前验证可解码，成功后复制到应用私有目录，不依赖原文件。可从「我的导入」再次选用。各记录分别保存选择，按账号隔离；本机导入音频不会随照片导出、云同步或在其他设备自动播放。移除本页配乐不删除原始文件。升级请直接覆盖安装，勿卸载旧版。

新增五张内置背景：云朵野餐、 水豚温泉、月下花园、山湖晨曦、海风小镇，保留原有六张预设与相册上传。内置高清 WebP 离线可用。生日与节日功能保留。

## 图片制作记录
使用内置 image_gen 工具（imagegen 技能），非 CLI。资产保存在 mobile/assets/backgrounds/，原始生成图留在用户 generated_images 目录。提示词主题如下：
1. meadow-friends.webp — cream kitten and white bunny picnic, mint meadow, peach clouds, daisies, sophisticated gouache storybook, spacious landscape, no lettering.
2. capybara-spa.webp — two round capybaras with orange fruit hats, steaming spring, peach flowers and mossy stones, warm butter yellow/sage gouache, no lettering.
3. moon-garden.webp — lavender blue night garden, crescent moon and stars reflected in pond, hydrangeas, textured watercolor, no lettering.
4. alpine-dawn.webp — tranquil mountain lake, snow peaks, peach sunrise mirrored in turquoise water, wildflower meadow and pines, editorial gouache, no lettering.
5. coastal-town.webp — Mediterranean seaside village, cafe balcony, cobalt sea, cream and terracotta buildings, bougainvillea, editorial watercolor, no lettering.

## 技术参考
音频使用 just_audio 0.10.6 的官方资产/本地文件播放接口：https://pub.dev/packages/just_audio


## 本次新增 · 自动配乐与旅途素材铺
- 已保存的内置音乐及本机导入 MP3 自动沿用，无须重新设置。没有配乐的记录保持安静。手动暂停后，当前页面不会自行重新开始播放。
- 手账编辑模式点击「素材铺 · 38 款」，有 6 个分类：软萌伙伴、旅途出发、花草野趣、天空与心情、拼贴纸品、和纸胶带。保留原有快捷表情。
- 38 个图形均为本项目原创 SVG，包内离线使用，不下载商业贴纸或角色素材。支持连续贴入、拖动、双指旋转缩放、复制、置顶与删除。图形贴纸可随备份、云同步与 HTML 手账导出保留（配乐仍限本机）。
- 修复后六种纸张款式的备份导入校验，全部十二种现有纸张均可恢复。

设计参考仅用于形式与分类研究，未复制源站图案：
- CoraCreaCrafts 2026 Sticker Trends：拼贴、植物、星月与蝴蝶结 https://coracreacrafts.com/blogs/inspiration-nook/2026-sticker-trends-journaling-guide
- RiN! Studio：旅行形状贴纸与异形和纸胶带 https://rinstudious.com/blogs/news/die-cut-washi-tape-trend-2026


## 本次新增 · 十二首配乐与素材滑动修复
保留原四首配乐及其 ID，新加入八首原创合成器乐：雨窗慢笺、樱花来信、沿途风景、绿野微风、落日橘海、初雪小径、街角咖啡、月色入梦。新曲约 36–69 秒，支持离线循环和现有 MP3 导入、逐图册自动播放设置。

- 快捷表情：左右滑动浏览、轻点添加；需要拖入书页时先长按约 0.35 秒，再拖动。不再因普通滑动抢先启动拖拽。
- 素材铺：可在素材卡片上直接左右滑动切换六个分类，上下滑动浏览本组内容；也可点击分类标签或「上一组／下一组」按钮。切换分类时标签自动滚动跟随。
- 所有原贴纸、背景、生日与节日功能保留。仅本地交付，未更新 GitHub 或网站。


## 本次体验 · 首页精简、悬浮唱片与统一反馈
- 每日寄语、节日入口与每日一句已从首页移出，统一在「我的 → 设置 → 每日寄语与节日祝福」中查看。寄语按本地日期轮换，共 30 条，支持复制。原每日一句摘录在该页面折叠保存，仍可换一句。
- 中国与国际节日开屏设置、节日预览保留；生日开屏与生日彩带未移除，也不受节日开关影响。
- 手账与旅行图册右下角为悬浮唱片，原横向配乐条已移除。点击唱片可动画展开/收起进度、播放暂停、音量、循环和换曲；支持拖动进度，仍保留 12 首内置配乐和本机 MP3 导入、逐图册自动播放。
- 编辑手账时唱片上移，避开底部素材工具栏。播放时缓慢旋转，暂停/进入后台时停止；「减少动态效果」开启时唱片静止、展开动画关闭。
- 删除、撤销、设置保存、备份、资料与导入等应用提示统一为顶部短提示，避开状态栏和返回按钮，保留底部导航操作。普通提示约 2 秒、带撤销约 3 秒，可关闭，新提示替换旧提示。票根删除也增加撤销。
- 减少装饰性英文眉题、厚重卡片阴影与重复文案，保留原背景、贴纸、字体选择和用户数据。
- 仅本地安卓包，版本仍为 1.0.0，未提交或推送 GitHub，也未更新网站。请覆盖安装，不要先卸载旧版。
