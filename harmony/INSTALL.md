# 鸿蒙 1.0.0 HAP 下载

手机和平板共用同一个 ARM64 HAP：
Kexinglu-HarmonyOS-1.0.0-unsigned.hap
版本名称 1.0.0；内部版本码沿用 2，未改动版本号。
包名 com.changanhe.kexinglu。

重要：这是未签名的开发预览包，不能下载后直接点击安装。
当前发布者只有 app_gallery 商店签名，不能将该商店签名用作任意设备安装。
不经过应用市场安装时，需要与包名、签名证书及测试设备匹配的有效调试或指定设备 Profile，签名后再安装。
随意改后缀、套用其他包名的 Profile 或使用未经匹配的签名，不会使它成为通用安装包。
如果你没有对应签名条件，应等待可用的测试分发，不要先卸载原应用。

自备签名条件的开发者：
1. 从 GitHub 下载 HAP 和 SHA256SUMS.txt，先核对文件 SHA256。
2. 在华为开发工具中准备与 com.changanhe.kexinglu 匹配、且允许目标设备的证书/Profile。若自己的签名仅匹配另一个包名，请从源码按自己的包名构建，不能直接使用当前 HAP。
3. 使用华为 hap-sign-tool 及当前工具文档完成 HAP 签名和 verify-app 校验。私钥和签名密码只在本机处理，不要上传到仓库或发送给他人。
4. 按设备系统支持的开发安装方式安装已签名 HAP。使用 hdc 时先授权连接，再执行 hdc install -r <已签名HAP路径>。覆盖升级必须满足同包名、兼容签名和版本要求；遇到签名不兼容请保留现有应用，勿卸载或清数据。

源码与构建说明：https://github.com/changanhe1205-afk/kexinglu/tree/main/harmony
华为签名文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing

验证边界：已通过开发机测试、手机与平板模拟器基础检查；ARM64 HAP 尚未完成实体设备安装与完整联网链路验证。x64 模拟器 HAP 不作为本次下载文件。
