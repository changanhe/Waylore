> 当前正式 Windows 版使用根目录的 Python / Flet 实现。下文关于 Flutter Windows 的内容仅属于未采用的实验实现；本目录当前主要维护安卓手机和平板。

# Waylore · 客行录 1.0.0

这里是 Android 手机与安卓平板的 Flutter 源码。请在 VS Code 或 Android Studio 中打开本目录，运行 `lib/main.dart`。项目根目录的 Python 程序是当前正式桌面客户端。

## 预览与构建

安装 Flutter 与 Dart 插件后，选择已启动的安卓模拟器或连接的手机，执行：

```sh
flutter pub get
flutter run
```

运行后修改 Dart 文件并保存，可使用热重载查看效果。Windows 预览执行 `flutter run -d windows`，需要安装 Visual Studio 的“使用 C++ 的桌面开发”工作负载。

```sh
flutter analyze
flutter test
flutter build apk --release
flutter build windows --release
```

公开版本名为 **1.0.0**。安卓发布签名配置和私钥不包含在仓库中；正式升级必须使用相同包名与签名。

## 手机、平板与桌面

同一套界面包含旅行记录、照片配乐、票根、影视与美食收藏、旅行手帐、每日寄语及生日祝福。900dp 以上的宽窗口使用首页双栏、记录与地图并排布局；较窄窗口恢复纵向排版。手帐支持横屏侧边工具栏及四种翻页效果，桌面支持鼠标拖动。

安卓手机和平板共用一个 APK。Windows 安装程序和便携包使用同一 Flutter 客户端。详见[项目介绍](../README.md)及[安装与数据说明](../docs/UNIFIED-RELEASE.md)。

## 数据与备份

安卓保留现有本地数据目录；Windows 新版数据位于 `%LOCALAPPDATA%/Waylore`。可在应用中导出和导入 JSON 备份。Windows 也可选择旧版 SQLite 数据库导入，读取原文件而不修改它，并跳过已导入记录。导入前请保留原始备份。

导入的 MP3 目前不随备份或云同步传输，换设备时需重新选择。账号与云同步为可选功能，配置说明见[云端设置](../cloud/SETUP.zh-CN.md)。

## 验证

测试覆盖记录编辑、备份、旧版数据库导入、布局与手帐交互。发布时另外验证安卓模拟器及 Windows 原生启动；真机性能、系统照片选择器与分享目标仍需在实际设备体验。
