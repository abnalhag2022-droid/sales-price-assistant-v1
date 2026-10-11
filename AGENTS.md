# AGENTS.md

## Project Goal

Build `sales-price-assistant` as an Arabic RTL Flutter mobile app for sales price lookup, sales tickets, paused tickets, inquiry, history, admin data, local-first operation, and future Backend sync.

## Source of Truth

The Arabic handoff document from the project conversation is the requirements source of truth. Do not reduce the product to a simple price-search screen.

## Do Not Remove

- Arabic RTL.
- Partial instant item search.
- Customer selection.
- Customer default price list.
- Runtime price-list override.
- Reference price and editable actual sale price.
- Fixed line price after a line is added.
- Multiple tickets.
- Pause/resume.
- Independent price inquiry.
- Local persistence.
- Backup/import.
- Offline queue and idempotency preparation.
- Admin sections.

## Current Delivery Strategy

Phase 1 is a demo APK that builds through GitHub Actions with `DEMO_MODE=true`.

Phase 2 adds the production Backend, secure auth, server-side RBAC, conflict handling, and real sync verification.

## Validation

When Flutter is available, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=DEMO_MODE=true
```

If Flutter is not available locally, use GitHub Actions.
