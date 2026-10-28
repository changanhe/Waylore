# Waylore 客行录 1.0.0 · Windows 与安卓平板

本轮统一客户端位于 `mobile/`，入口为 `mobile/lib/main.dart`。不要运行根目录 `main.py` 来预览新版，它属于旧桌面实现。

## 安装

- Windows：退出旧应用后运行 `Kexinglu-Setup-1.0.0.exe`。新版沿用旧安装标识，并兼容原快捷方式使用的「客行录.exe」名称。原始记录目录不删除。
- 便携版：完整解压 `Waylore-Windows-1.0.0-portable.zip`，运行 `Waylore.exe`。
- Android手机与平板：同一 `Kexinglu-Android-1.0.0.apk`，公开版本1.0.0、内部构建45。请覆盖安装，勿先卸载。
- 安卓平板：900dp以上使用首页双栏、旅途与票夹记录/地图并排布局，支持横竖屏与分屏。宽度变小时恢复纵向布局。
- 横屏手帐：工具栏移至侧边，纸页上下浏览；翻页有平滑、折页、书页和淡入四种效果。

Windows 安装程序会注册浏览器登录回调；需要第三方网页登录时请使用安装版。便携版适合本机记录，未注册回调时请使用邮箱密码登录。第三方登录仍取决于云端配置与提供商服务。

## 从旧Windows版迁移

1. 保留旧版整个数据文件夹及配置，不要只备份一个EXE。
2. 打开新版「我的 → 数据备份 → 从备份导入」，选择旧数据目录中的 `yingjianlu.db`。
3. 检查发现的记录数量与缺失图片数量，确认后导入。
4. 原数据库只读打开，不会被改写。重复导入同一路径会跳过已有ID，不覆盖你在新版的编辑。
5. 本地照片会复制到新版备份恢复目录。旧版内嵌手帐图片、文字和基本排版会转换；缺失的原照片无法凭空恢复，复杂旧版专有样式可能以对应的基础纸张显示。原库请继续保留。
6. 新版Windows数据库默认位于 `%LOCALAPPDATA%\Waylore`；旧版通常在 `%LOCALAPPDATA%\客行录` 或用户自选目录。新版照片与音乐由系统文档目录中的应用文件管理。不要在应用运行时直接编辑数据库。

## 版本与范围

Windows、安卓手机、安卓平板对外版本名均为1.0.0。当前没有交付Linux、macOS或原生鸿蒙安装包。Windows的音乐播放与数据库使用桌面原生插件；核心界面与手机共用代码。鼠标支持拖动、滚动与点击，具体触控效果仍取决于设备。

GitHub仅发布源码、说明、演示截图和检查通过的安装包，不包含用户记录、私钥、密码或管理员服务密钥。赞赏完全自愿，不影响功能。

## English

Open `mobile/` for the current Flutter client. Keep the complete old desktop data folder. The Windows backup-import dialog accepts the old `yingjianlu.db` in read-only mode, copies available media and skips previously imported records. Back up before upgrading. Phone and Android tablet use the same signed APK; do not uninstall the old application first. Native HarmonyOS, macOS and Linux packages are not included in this release.
