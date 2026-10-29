# Current delivery agreement (2026-10-19)

The previous version instructions were revoked by the user.
- Windows, Android (phones/tablets), and Linux public versions are 1.0.0.
- Preserve user data during updates. Never uninstall or clear data for an upgrade.
- Android internal versionCode must increase for each delivered build.
- Release packages: Kexinglu-Setup-1.0.0.exe and Kexinglu-Android-1.0.0.apk.
- Local Windows installer: 客行录-安装程序-1.0.0.exe.
- Linux packages: Kexinglu-Linux-1.0.0-amd64.deb and Kexinglu-Linux-1.0.0-x86_64.tar.gz; build and smoke-test on Ubuntu before publishing.
- Never commit signing keys, weather credentials, local databases or personal configuration.

# Windows design agreement (2026-10-29)

- The user rejected replacing the Windows UI with the mobile Flutter UI.
- The supported Windows client remains the root-level Python/Flet app (`main.py`). Preserve its existing landscape background, large clock, six-item navigation and page layouts. Make only scoped improvements within that design unless the user explicitly requests a redesign.
- `mobile/` is the Android phone/tablet client. Its experimental Windows runner must not replace the supported Windows release.
- All public version names remain 1.0.0. Preserve both original and experimental data folders during recovery; never clear user data.
