# بناء تطبيق Android — خطوة بخطوة

> بيئة إعداد المصدر الحالية لا تحتوي Flutter SDK وAndroid SDK، لذلك لم يتم الادعاء ببناء APK من هنا.

## 1. تثبيت الأدوات
على الكمبيوتر ثبّت:
- Flutter SDK حديث مستقر.
- Android Studio.
- Android SDK + Platform Tools + Build Tools.
- جهاز Android أو محاكي.

ثم نفّذ:

```bash
flutter doctor
```

يجب معالجة عناصر Android التي تظهر كغير جاهزة.

## 2. فتح المشروع
افتح مجلد `sales_price_assistant_mobile_v1` في Android Studio أو VS Code.

## 3. إنشاء ملفات Android الأصلية
من داخل المجلد:

### Windows PowerShell
```powershell
.\tooling\prepare_android.ps1
```

### Linux/macOS
```bash
./tooling/prepare_android.sh
```

السكربت ينشئ مجلد Android، يضيف Internet permission، ويسمح مؤقتًا باتصالات HTTP المحلية اللازمة لاختبار Backend داخل الشبكة.

## 4. تجربة Demo محلية على الهاتف
```bash
flutter run --dart-define=DEMO_MODE=true
```

الحساب التجريبي:
- `sales`
- أو `admin`
- كلمة المرور غير مطلوبة في Demo.

## 5. تشغيل Backend فعلي
مثال:

```bash
flutter run --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

استبدل العنوان بعنوان خادم Backend داخل الشبكة.

## 6. APK Release
```bash
flutter build apk --release --dart-define=DEMO_MODE=false --dart-define=API_BASE_URL=https://YOUR-SERVER
```

الملف الناتج يكون تحت `build/app/outputs/flutter-apk/`.

## 7. ملاحظة أمنية
خيار HTTP المحلي مفعّل فقط لتسهيل الاختبار الأول. في النسخة النهائية يفضّل HTTPS، ولا ينبغي نشر API الإنتاج عبر HTTP غير مشفر.
