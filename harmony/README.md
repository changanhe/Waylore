# 客行录 · HarmonyOS 手机与平板适配

原生鸿蒙客户端正在开发，公开版本计划为 **1.0.0**。现提供 [未签名 HAP 下载](https://github.com/changanhe1205-afk/kexinglu/releases/download/v1.0.0-harmony-preview2/Kexinglu-HarmonyOS-1.0.0-unsigned.hap)，须自行准备匹配包名与目标设备的有效签名后安装，详见 [INSTALL.md](INSTALL.md)。这不代表已通过华为应用市场审核。Android APK 不应标注为鸿蒙原生安装包。

## 工程与数据

- 复用 `mobile/lib` 与 `mobile/assets`，保留旅行、票根轨迹、自由手账、食光、影视和可选同步。
- 原生入口声明 `phone`、`tablet`，界面按窗口宽度切换布局；保留浮动导航、地图缩放和横竖屏布局。
- 独立生成到 `build/harmony-app`，不改动 Android 的依赖锁文件、签名和已安装应用数据。
- 社区插件按 `toolchain.lock.json` 中的提交固定，覆盖数据库、文件、照片、定位、分享、浏览器回调和会话存储。构建工作副本从固定提交导出到 `build/hp`，避免 Hvigor 改写插件生成文件后影响下一次构建。
- 文件选择和安全存储使用专用适配；修正定位插件声明的实现包名。登录回调沿用 `com.changanhe.kexinglu://login-callback`。
- `prepare.py` 仅生成开发工程，不读取或上传个人资料库。重复执行保留生成目录内的本地签名配置。版本由 `release.json` 管理；重新生成时刷新受管理的原生入口和版本号，避免旧工作目录遗漏更新。

## 本机构建

1. 安装华为官方 DevEco Studio 正式版及配套 SDK。
2. 安装 `toolchain.lock.json` 指定 tag 的 Flutter OH SDK，需获取该 tag，避免浅克隆导致版本识别失败。
3. Python 安装 PyYAML。运行 `python harmony/prepare.py`，首次会按锁定提交获取插件。
4. Windows 可运行 `harmony/build.ps1`，按机器设置 `FlutterRoot`、`StudioRoot`、`PluginCache`、`Python`。
5. 在 DevEco Studio 打开生成目录中的 `ohos`。本地配置签名后，使用 `-Signed` 构建设备包；商店交付使用 `-Package app -Signed`。
6. DevEco CLI 生成本机发布签名配置后，可用 `harmony/configure-release.ps1 -Profile <本机发布.p7b路径>` 校验并关联 AppGallery Profile。脚本核对包名、发布类型和完整证书链，仅修改忽略的生成目录。

模拟器构建使用 `-BuildMode debug -TargetPlatform ohos-x64`。未签名构建临时解除产品的签名引用，结束后恢复本机签名配置。

签名材料只保存在本机生成目录，不得提交证书、私钥、Profile 或含密码的签名配置。未签名包和绑定开发设备的调试包不能当作普通用户安装包发布。

## 验证状态（2026-10-25 · 1.0.0 build 2）

- 鸿蒙 Flutter 3.41.9+ohos-1.0.2 下 Dart 静态检查通过。
- 98 项开发机自动化测试（另有 4 项平台条件跳过），以及 2 项工程生成回归测试通过，包括窗口缩放、平板布局、地图和记录编辑。
- DevEco Studio 26.0.0.851 / Release SDK 26.0.0.105 下 ARM64 原生 Release HAP 编译通过，包含 11 个原生插件。
- AppGallery Release Profile 已关联，ARM64 商店 APP 包构建完成，华为签名工具校验通过。商店 APP 用于后台上传，不能作为普通用户直接安装的 HAP。
- 手机模拟器上已验证启动、拒绝定位后手动选择入口、浮动导航、旅途/票夹中国地图、新增日志保存，以及全屏地图切换横屏。
- 完整 tablet 系统镜像（MatePad Pro 13 模拟器，2880×1920 / 1920×2880）已验证五个主页面导航、首页双列、记录与地图并排布局、设置页居中限宽、日志新增和强制结束后重启保留。全屏地图显示与屏幕旋转已检查。
- 手机 build 1 → build 2 采用覆盖安装，原测试日志与票根仍保留；主题和语言选择面板已核对截图。
- **尚需完成**：完整联网功能、真机验证、上架资料补齐，以及华为应用市场审核。模拟器测试不等于真机兼容性验证。

验证摘要见 [VALIDATION.md](VALIDATION.md)，上架介绍与交付说明见 [STORE.md](STORE.md)。

本机模拟器可运行 `python harmony/smoke.py --device 127.0.0.1:5555 --kind phone`（平板改为 `tablet`）。只接受本机模拟器，不清除资料、不登录账号。首次启动先处理系统锁屏及权限提示。

## English

The native HarmonyOS phone/tablet port is in development. It reuses the maintained Flutter UI in an isolated generated workspace with pinned OHOS plugins. Host-side analysis, 98 tests (4 platform-conditional skips), 2 workspace regression checks, and an ARM64 native release build passed with DevEco Studio 26.0.0.851. The AppGallery APP package is signed and its signature verified. Basic phone-emulator navigation and journal creation work. Full tablet-system emulator navigation, journal persistence and rotated layouts were checked. Real-device, complete online-feature verification and store review remain pending. An unsigned ARM64 HAP is available for download; valid bundle/device-matched signing is required before installation. See INSTALL.md.

Official resources: [DevEco Studio](https://developer.huawei.com/consumer/cn/download/) · [App submission](https://developer.huawei.com/consumer/cn/app/submit/) · [Flutter OH](https://gitcode.com/CPF-Flutter/flutter_flutter).
