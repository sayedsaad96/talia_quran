## إصلاح أخطاء الـ debug

### أولاً: تعديلات الكود (خطأ الإشعارات NPE)
1. **`lib/core/services/app_initializer.dart`**: إضافة باراميتر `bool background = false` لـ `AppInitializer.initialize()` — عند `background: true` تتخطى `_initNotifications()` استدعاء `requestPermissions()` (طلب الصلاحيات يحتاج Activity غير متاحة في الـ Workmanager background isolate، وهذا سبب الـ NullPointerException).
2. **`lib/core/sync/background_sync_scheduler.dart`**: تمرير `background: true` عند استدعاء `AppInitializer.initialize()` من `cloudSyncCallbackDispatcher`.
3. **`lib/core/services/notification_service.dart` (`requestPermissions`)**: تغليف فرع Android بـ try/catch لمنع أي PlatformException غير معالج مستقبلاً.

### ثانياً: ملف SQL للـ Supabase (اختيار المستخدم: يطبقه بنفسه)
4. إنشاء `supabase/apply_bookmark_functions.sql` يحتوي دوال `upsert_quran_bookmark` + `pull_quran_bookmarks` + الـ REVOKE/GRANT (مستخرجة من migration `20260820221531` — idempotent عبر CREATE OR REPLACE)، مع تعليقات أعلى الملف تشرح خطوات التطبيق من Supabase Dashboard → SQL Editor. يعالج هذا خطأ PGRST202 الفاشل في مزامنة الـ bookmarks.

### ثالثاً: تنظيف كاش Kotlin (أوامر تُنفَّذ)
5. إضافة `kotlin.incremental=false` إلى `android/gradle.properties` (مشكلة Windows cross-drive: pub cache على C: والمشروع على D: تُف sled كاش incremental compilation).
6. إيقاف الـ daemons: `gradlew --stop` من مجلد android.
7. `flutter clean` + حذف `android/.gradle`.
8. `flutter pub get` ثم بناء تجريبي `flutter build apk --debug` للتحقق من: اختفاء أخطاء "Daemon compilation failed"، ونجاح compileSdk = 37 (المضبوط أصلاً في build.gradle.kts — لو platform 37 غير منصّب يظهر خطأ صريح نعالجه).

### رابعاً: تعليمات يدوية للمستخدم (تُذكر في الرد النهائي)
- إلغاء تثبيت التطبيق القديم من الموبايل مرة واحدة (حل INSTALL_FAILED_UPDATE_INCOMPATIBLE ومسح البيانات المتكرر).
- تطبيق ملف الـ SQL على Supabase من الـ Dashboard ثم إعادة تشغيل التطبيق للتأكد من نجاح مزامنة الـ bookmarks.