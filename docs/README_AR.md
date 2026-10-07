# مساعد المبيعات — النسخة الهاتفية V1

هذه الحزمة هي **مصدر Flutter الفعلي** المبني على تجربة Web Demo V4 والقرارات المتراكمة في المشروع. لا تحتوي الحزمة على APK جاهز لأن بيئة البناء الحالية لا تحتوي Flutter SDK/Android SDK.

## ما تم نقله إلى V1
- شاشة مبيعات سريعة.
- البحث بجزء من اسم الصنف أو رقمه.
- عميل + قائمة سعرية افتراضية.
- تغيير القائمة السعرية أثناء المعاملة.
- السعر المقترح من القائمة مرجعي، وسعر البيع الفعلي قابل للتحرير.
- تعديل كمية/سعر السطر بعد إضافته.
- معاملات متعددة مع تعليق واستئناف.
- إتمام البيع.
- استعلام أسعار مستقل.
- سجل الأسعار/المعاملات.
- Offline-first مع Queue وIdempotency-Key.
- إدارة الأصناف والعملاء والقوائم والمستخدمين حسب الدور.
- تخزين محلي.
- REST API قابلة لتغيير العنوان بواسطة `API_BASE_URL`.
- وضع Demo محلي للاختبار الأول.

## تشغيل تجريبي على Android
1. ثبّت Flutter SDK وAndroid SDK على الكمبيوتر.
2. فك الحزمة.
3. من داخل المجلد نفّذ:
   - `flutter pub get`
   - `flutter run --dart-define=DEMO_MODE=true`
4. لاستخدام Backend:
   - `flutter run --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://SERVER:8000`

## ملاحظة عن Backend
تم عزل كل اتصال الشبكة في `lib/services/api_service.dart`. مسارات REST المستخدمة موثقة في `docs/API_CONTRACT.md`. إذا كانت نسخة Backend الحالية تستخدم أسماء مسارات مختلفة، يتم تعديل هذا الملف فقط دون إعادة بناء واجهات التطبيق.

## بناء APK
بعد تثبيت Flutter/Android SDK:
`flutter build apk --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://SERVER:8000`

لنسخة App Bundle:
`flutter build appbundle --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://SERVER`

## بناء APK من الهاتف

يمكن استخدام GitHub Actions لبناء APK سحابيًا دون تثبيت Flutter SDK وAndroid SDK على الهاتف. راجع:
`docs/GITHUB_ACTIONS_ANDROID_AR.md`
