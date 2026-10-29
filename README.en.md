# Waylore · 客行录

Keep your journeys. Remember your everyday.

[简体中文](README.md) · [Downloads](https://github.com/changanhe/Waylore/releases/tag/v1.0.0) · [Support](docs/SUPPORT.md)

## Windows: the original desktop design

The Windows release has been restored to the original Python / Flet application: its landscape background, large clock, six-item navigation and existing travel, ticket, food, film and notebook layouts. Future improvements will preserve this desktop design. The public version remains **1.0.0**.

![Original Windows interface](docs/screenshots/windows-home.png)

The maintained Windows entry point is root-level `main.py`, built with `build.py` and `build_installer.py`. The Flutter Windows implementation in `mobile/windows/` is an unused experiment, not the current Windows release.

## Android phones and tablets

Android continues to use the Flutter application in `mobile/`, public version **1.0.0**, internal build45. It includes travel journals, photos, collections, creative notebooks, 38 graphic stickers, 12 paper styles, four page transitions, 12 built-in music tracks and MP3 import, a floating record player, daily messages and birthday greetings. Tablet layouts support wide screens and landscape editing.

These Android features are not a claim of full Windows feature parity. Each client retains its own device-appropriate layout.

![Android tablet](docs/screenshots/tablet-home.png)

## Downloads and data

- [Windows installer](https://github.com/changanhe/Waylore/releases/download/v1.0.0/Kexinglu-Setup-1.0.0.exe): Windows10 /11 x64, original desktop design, bundled Python runtime.
- [Android phone/tablet APK](https://github.com/changanhe/Waylore/releases/download/v1.0.0/Kexinglu-Android-1.0.0.apk): Android7 and newer.

SHA-256 checksums are attached to the release. The experimental Flutter Windows portable package has been withdrawn.

Exit the application and install over the previous location without uninstalling or clearing data. The original Windows client keeps its existing data location, normally `%LOCALAPPDATA%/客行录` or a user-selected folder. Export any new records created in the experimental Windows app before switching back. Its `%LOCALAPPDATA%/Waylore` database is preserved, but is not automatically merged into the original desktop database.

See [installation guidance](docs/UNIFIED-RELEASE.md) and [validation](docs/VALIDATION-1.0.0.md).

## Development

For Windows, install `requirements.txt` and run `python main.py`. For Android, open `mobile/` and run `flutter pub get` followed by `flutter run`. Never commit personal databases or signing keys. See [third-party notices](THIRD_PARTY_NOTICES.md) for resource licenses.

## Support

If Waylore helped you keep a journey or a moment worth returning to, consider sharing feedback or buying the developer a cup of tea. **Donations are entirely optional and do not unlock features or affect access.**

<img src="docs/support/wechat.png" width="280" alt="Developer-provided support QR code" />

Contact: **kexinglu@yeah.net**.
