# ربط تطبيق الحلاقة بقاعدة Firebase المشتركة

المشروع الحالي يقرأ الخدمات والإعدادات ويرسل الحجوزات عبر API لوحة التحكم (`/api/mobile/...`)؛ والـ API يحفظ البيانات في Firestore. هذا يحافظ على قاعدة بيانات واحدة ويمنع وضع صلاحيات الإدارة داخل التطبيق.

## إعداد لازم قبل التشغيل
1. انشر مشروع لوحة التحكم والخادم على Vercel.
2. في Vercel > Settings > Environment Variables أضف `FIREBASE_SERVICE_ACCOUNT` بقيمة JSON كاملة لحساب خدمة من مشروع Firebase `understand-me-d31f4`. لا تضع هذا المفتاح في تطبيق الهاتف أو مستودع GitHub.
3. اضبط `ADMIN_EMAILS` أو `ADMIN_UIDS` حسب حسابات المديرين.
4. ابنِ التطبيق مع رابط نشر الخادم:
   `flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-DEPLOYMENT.vercel.app`
   استبدل الرابط بعنوان نشر لوحة التحكم الحقيقي.
5. تأكد أن Firebase Authentication مفعّل لطريقة تسجيل دخول المدير، وأن قواعد Firestore لا تسمح للعميل العام بالكتابة المباشرة إلى بيانات الإدارة.

## ملاحظة إعداد Android
ملف `google-services.json` الذي أرسله المستخدم مسجل لحزمة `com.zizo`، بينما `android/app/build.gradle.kts` في هذا المشروع يعرّف الحزمة `com.razorbook.razor_booking`. لا تضع الملف وتفعّل Google Services قبل تسجيل/مطابقة اسم الحزمة؛ وإلا لن يكون إعداد Android صحيحًا. الاتصال بالبيانات في التطبيق الحالي يتم عبر API أعلاه ولا يحتاج ملف Android هذا حتى يعمل.

## ما الذي سيُحفظ؟
الخدمات والأسعار، إعدادات فتح/إيقاف الحجز، الجوائز/عجلة الحظ، الخصومات، العملاء والحجوزات في Firestore، ويقرأ التطبيق البيانات من API نفسها.


## رابط لوحة التحكم الحالي

تم ضبط التطبيق افتراضيًا لاستخدام خادم لوحة التحكم المنشور هنا: https://zizo-admin3.vercel.app

إذا أردت بناء APK، يمكن ترك `API_BASE_URL` كما هو أو تمرير: `--dart-define=API_BASE_URL=https://zizo-admin3.vercel.app`. هذا يحدد عنوان الخادم فقط؛ يجب التأكد من إعداد `FIREBASE_SERVICE_ACCOUNT` في Vercel حتى يستطيع الخادم القراءة والكتابة في Firestore.
