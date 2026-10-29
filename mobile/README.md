# Waylore · 安卓手机与平板 1.0.0

本目录维护安卓手机与安卓平板的Flutter客户端，入口为 `lib/main.dart`。当前正式Windows版使用项目根目录的Python/Flet实现，入口为 `main.py`。本目录中的Windows runner仅保留为未采用的实验实现，不用于Windows正式发布。

## 预览与构建

在VS Code或Android Studio打开本目录，安装Flutter/Dart插件，选择已启动的安卓模拟器或连接的手机：

```sh
flutter pub get
flutter run
```

修改Dart文件后可以热重载预览。发布检查和构建：

```sh
flutter analyze
flutter test
flutter build apk --release
```

公开版本1.0.0，内部构建45。正式覆盖安装需使用相同包名与签名。签名配置和私钥不包含在仓库中。

## 平板与数据

同一APK适配手机和平板，支持宽屏双栏、横竖屏和手帐侧边工具栏。手机布局不用于替换Windows原有界面。

记录和图片保存在本机，可导出JSON备份。导入MP3目前不随备份或云同步迁移。可选账号服务说明见[云端设置](../cloud/SETUP.zh-CN.md)。

[项目说明](../README.md) · [下载](https://github.com/changanhe/Waylore/releases/tag/v1.0.0)
