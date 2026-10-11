# بناء APK من الهاتف عبر GitHub Actions

هذا المشروع يحتوي على Workflow جاهز لبناء نسخة Android في GitHub دون الحاجة إلى تثبيت Flutter SDK أو Android SDK على الهاتف.

## 1) رفع المشروع إلى GitHub

أنشئ Repository جديدًا في GitHub، ثم ارفع محتويات هذا المجلد إليه.

يجب أن يظهر داخل المستودع:

```text
.github/workflows/android-build.yml
lib/
test/
pubspec.yaml
tooling/
docs/
```

## 2) تشغيل البناء من الهاتف

من تطبيق/موقع GitHub:

1. افتح المستودع.
2. افتح **Actions**.
3. اختر **Android Build**.
4. اضغط **Run workflow**.
5. اترك `Build the APK in local demo mode` مفعّلًا لأول تجربة.
6. اترك `Backend API URL` فارغًا.
7. اضغط **Run workflow**.

## 3) تنزيل APK

بعد نجاح جميع الخطوات:

1. افتح تشغيل الـWorkflow الناجح.
2. انزل إلى **Artifacts**.
3. نزّل `sales-price-assistant-android`.
4. فك الضغط عن الملف.
5. ستجد `app-release.apk`.
6. افتح APK على الهاتف وثبّته.

## 4) أول تجربة

هذه النسخة مبنية بوضع Demo محلي، لذلك لا تحتاج Backend أو اتصالًا بخادم.

المستخدمون التجريبيون:

- `sales`
- `admin`
- `store`

ولا توجد كلمة مرور في Demo.

## 5) بناء نسخة مرتبطة بالـBackend

عند جاهزية الخادم، شغّل Workflow مرة أخرى، وأوقف Demo Mode، ثم أدخل عنوان API مثل:

```text
https://example.com
```

أو عنوان خادم داخل الشبكة أثناء الاختبار:

```text
http://192.168.1.100:8000
```

يفضّل استخدام HTTPS في الإنتاج.

## ملاحظة

الـWorkflow ينشئ مجلد Android تلقائيًا أثناء البناء، ثم يطبق إعدادات الاختبار المطلوبة للاتصال المحلي.
