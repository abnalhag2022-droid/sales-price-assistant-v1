#!/usr/bin/env bash
set -euo pipefail
flutter create . --platforms=android --org com.salespriceassistant --project-name sales_price_assistant
python tooling/patch_android_manifest.py
flutter pub get
