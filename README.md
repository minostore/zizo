# تطبيق صالون الحلاقة — Flutter لـ Android وiOS

هذا هو تطبيق العميل الأصلي للهاتف، بالعربية RTL وبألوان الشعار الأسود والذهبي. لا يُقدَّم كتطبيق ويب. يتصل بمخدم Node.js عبر واجهة REST.

## التشغيل والفحوص

من هذا المجلد:

```sh
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=https://YOUR-SALON-DOMAIN
```

استبدل النطاق بعنوان خادم الصالون بعد نشره. Android Emulator مع مخدم محلي يستخدم `http://10.0.2.2:3000`، وiOS Simulator يستخدم `http://127.0.0.1:3000`. على هاتف حقيقي استخدم عنوانًا يمكن للهاتف الوصول إليه، ويفضّل HTTPS.

## بناء التطبيقين

```sh
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-SALON-DOMAIN
flutter build ios --release --dart-define=API_BASE_URL=https://YOUR-SALON-DOMAIN
```

بناء وتوقيع iOS يتطلب macOS/Xcode وحساب Apple. لم يُنتج APK أو IPA موقّع في بيئة Sandbox؛ ملفات مصدر Android وiOS مضمّنة.

## الحساب والأسعار

الحجز متاح كضيف بالاسم ورقم الهاتف. واجهتا الدخول والتسجيل موجودتان، لكن التحقق الفعلي من ملكية الهاتف يتطلب مزود SMS/OTP. أسعار الخدمات الابتدائية أمثلة بالجنيه المصري؛ اضبطها من لوحة الإدارة قبل استقبال حجوزات فعلية.
