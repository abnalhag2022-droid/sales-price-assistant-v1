# Sales Price Assistant

تطبيق Flutter عربي RTL لمساعد المبيعات والأسعار.

## أسرع طريقة للحصول على APK

1. افتح المستودع على GitHub.
2. ادخل إلى تبويب **Actions**.
3. اختر Workflow باسم **Android Build**.
4. اضغط **Run workflow**.
5. اترك `demo_mode = true` للنسخة الأولية بدون Backend.
6. بعد انتهاء التشغيل بنجاح، افتح Artifact باسم:
   `sales-price-assistant-android`
7. نزّل ملف APK وثبته على الهاتف.

## تشغيل محلي عند توفر Flutter

```bash
flutter pub get
flutter run --dart-define=DEMO_MODE=true
```

لبناء APK محليًا:

```bash
flutter build apk --release --dart-define=DEMO_MODE=true
```

## ما تحتويه النسخة الأولية

- تسجيل دخول Demo للمستخدمين `sales` و `admin`.
- واجهة عربية RTL.
- مبيعات سريعة.
- بحث جزئي عن الأصناف.
- اختيار العميل والقائمة السعرية.
- سعر مرجعي وسعر بيع فعلي قابل للتعديل.
- تعديل الكمية والسعر بعد الإضافة.
- تعليق واستئناف معاملات.
- استعلام أسعار مستقل.
- سجل محلي.
- إدارة أساسية للأصناف والعملاء والقوائم والمستخدمين.
- حفظ محلي ونسخ احتياطي JSON.
- Sync Queue تمهيدي ينتظر Backend عند توفره.

## ملاحظة مهمة

هذه نسخة أولية قابلة للتثبيت والتجربة. النسخة الإنتاجية الكاملة تحتاج Backend فعلي حسب `docs/API_CONTRACT.md`.
