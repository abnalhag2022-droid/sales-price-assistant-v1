# Mobile V1 — Build Status

Date: 2026-10-11

## Current target

The immediate target is an installable initial APK built through GitHub Actions in Demo Mode. This is intentionally narrower than full Production-Ready so the owner can test the workflow on a phone first.

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
- Persistent local app-state file.
- Queue operation status/retry/backoff model.
- API adapter prepared for access token, refresh token, 401 handling, and idempotency.
- Requirement traceability summary in `docs/TRACEABILITY_MATRIX.md`.
- APK build instructions in `docs/INITIAL_APK_BUILD_AR.md`.

## Not executed in this environment
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk`
- `flutter build appbundle`

Reason: Flutter SDK and Android SDK are not installed in the current execution environment.

Therefore this package is a **Flutter source candidate for an initial APK**, not a falsely claimed local APK build.

## Recommended build path

Use GitHub Actions:

1. Open Actions.
2. Run `Android Build`.
3. Use `demo_mode=true`.
4. Download artifact `sales-price-assistant-android`.
