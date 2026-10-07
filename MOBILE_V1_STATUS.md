# Mobile V1 — Build Status

Date: 2026-10-07

## Implemented in source
- Native Flutter UI structure.
- Arabic RTL interface.
- Sales workflow from Web Demo V4.
- Editable effective selling price.
- Editable line quantity/price.
- Customer default price list + runtime override.
- Fixed per-item price override inside price lists.
- Multiple tickets / pause / resume.
- Price inquiry and history.
- Local persistence.
- Offline queue.
- Idempotency-Key support.
- REST API adapter.
- Admin sections.
- JSON backup/import.
- Android preparation scripts.
- Unit test skeleton.

## Not executed in this environment
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk`

Reason: Flutter SDK and Android SDK are not installed in the current execution environment.

Therefore this package is a **Flutter source candidate for V1**, not a falsely claimed APK build.
