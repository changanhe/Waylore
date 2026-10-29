# Waylore 1.0.0 安装与恢复说明

2026年10月29日更正：Windows恢复原有桌面设计，安卓手机和平板继续使用现有Flutter版本。

- Windows：退出应用后，运行发布页的 `Kexinglu-Setup-1.0.0.exe`，覆盖安装到原安装目录。无需卸载，不要清空数据。
- 原Windows数据目录通常为 `%LOCALAPPDATA%/客行录`，也可能是用户在设置中选择的位置。该版本继续读取原数据库。
- 如已在实验Flutter Windows版新增记录，请先导出备份。其 `%LOCALAPPDATA%/Waylore` 数据仍保留，不会自动合并到原桌面版。
- 安卓手机与平板：继续使用 `Kexinglu-Android-1.0.0.apk`，公开版本1.0.0、内部构建45，保持原签名，覆盖安装。
- 手机布局的Windows便携包已撤下。根目录 `main.py` 为正式Windows入口，`mobile/lib/main.dart` 为安卓入口。

Windows has been restored to its original desktop design. Exit the app and install over its existing installation directory. Do not uninstall or delete your data. Records created in the experimental Flutter Windows application remain in its separate data folder and are not automatically merged. Android packages are unchanged.
