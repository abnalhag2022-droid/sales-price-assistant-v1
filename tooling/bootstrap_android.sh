#!/usr/bin/env bash
set -euo pipefail
flutter create . --platforms=android --org com.salespriceassistant --project-name sales_price_assistant
flutter pub get
