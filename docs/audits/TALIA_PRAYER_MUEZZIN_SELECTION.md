# Talia Prayer — Muezzin Selection (اختيار المؤذن المفضل)

**التاريخ:** 2026-09-24 · **النطاق:** Android (V2 native delivery) + iOS (legacy FLN)
**الحالة:** مُنفّذ — `flutter analyze` نظيف، اختبارات Dart (+63) وKotlin (مجموعة prayer) ناجحة.

---

## 1. الهدف

إتاحة اختيار صوت الأذان (المؤذن) المفضل لدى المستخدم من قائمة مؤذنين مشهورين
مرخّصين، مع خيار خاص لأذان الفجر، دون أي تأثير على دقة مواعيد التنبيه أو
الأذان — المؤذن يغيّر **أيّ** مقطع يُشغَّل فقط، أما **متى** تُطلق الإنذارات
فيبقى على مسار AlarmManager/FLN الجدولي كما هو دون أي تغيير.

## 2. المؤذنون المرفقون والمصادر والتراخيص

| id | المؤذن | المصدر | الترخيص | المدة |
|---|---|---|---|---|
| `default` | المقطع الافتراضي المرفق مسبقاً | موجود مسبقاً في المشروع | — | ~1:30 |
| `makkah` | علي أحمد ملا — الحرم المكي | archive.org `azaan-of-world-mosques-english` («4th Haram Makkah by Mulla.mp3») | Public Domain Mark 1.0 | ~2:55 |
| `abdulbasit` | عبد الباسط عبد الصمد — القاهرة | archive.org `azaan-of-world-mosques-english` («Cairo Abdul Baset.mp3») | Public Domain Mark 1.0 | ~3:20 |
| `qatami` | ناصر القطامي | archive.org `adhan.notifications` («Nasser_al_Qatami_Adhan.mp3») | Public Domain Mark 1.0 | ~2:12 |
| `suraihi` | عبدالمجيد السريحي — مسجد قباء | archive.org `zied_hadj_hassen1` | Public Domain Mark 1.0 | ~3:29 |
| `afasy_fajr` | مشاري العفاسي (نسخة الفجر) | archive.org `adhan.notifications` («Mishary_Rashid_al_Afasy_Fajr_Adhan.mp3») | Public Domain Mark 1.0 | ~3:07 |

جميع التسجيلات من مجموعة «Adhan Notifications»/«Azaan of World Mosques»
على Internet Archive وهي معلَّمة Public Domain Mark 1.0 (أو مكافئها
`creativecommons.org/publicdomain/mark/1.0`). الروابط:

- https://archive.org/details/adhan.notifications
- https://archive.org/details/azaan-of-world-mosques-english
- https://archive.org/details/zied_hadj_hassen1

> ملاحظة نشر: Public Domain Mark يُستخدم للمصنفات التي يعتقد صاحب الرفع
> أنها في الملك العام. قبل النشر التجاري الواسع يُستحسن حفظ لقطات لصفحات
> المصادر أعلاه ضمن هذا المجلد كإثبات أصل.

## 3. الملفات الصوتية المضافة

- Android (`res/raw/`): `adhan_makkah.mp3`, `adhan_abdulbasit.mp3`,
  `adhan_qatami.mp3`, `adhan_suraihi.mp3`, `adhan_afasy_fajr.mp3`
  (MP3 44.1kHz mono 48kbps — أحجام 0.8–1.3MB).
- iOS (`ios/Runner/`): `adhan_makkah.caf`, `adhan_abdulbasit.caf`,
  `adhan_qatami.caf`, `adhan_suraihi.caf`, `adhan_afasy_fajr.caf`
  (حاوية CAF حقيقية بترميز IMA4 22.05kHz mono — مطابقة لصيغة `adhan.caf`
  الأصلي؛ لا تحتاج أي تعديل على Xcode project لأن مجموعة Runner تتضمن
  الملفات الجديدة تلقائياً عبر file-system synchronized groups).
- إجمالي الإضافة: ~10MB (5.4MB Android + 10.6MB iOS).

## 4. البنية والتدفق

```
المستخدم يختار المؤذن (settings_notification_tiles.dart → _MuezzinPickerSheet)
  → NotificationSettingsCubit.setMuezzin / setFajrMuezzin
    → SharedPreferences: notifications_prayer_muezzin / …_fajr
    → إعادة جدولة فورية (notification_scheduler.refreshAll)

مسار Android V2:
  PrayerEventBuilder.build(muezzinId, fajrMuezzinId)
    → soundProfile لكل حدث: <id> أو fajr:<id> للفجر فقط
    → MethodChannel talia/prayer_delivery → PrayerAlarmScheduler
    → عند وقت الصلاة: PrayerAlarmReceiver → AdhanPlaybackService
    → AdhanClipResolver.rawResourceName(soundProfile, prayerKey) → res/raw clip

مسار iOS (FLN):
  NotificationScheduler → TaliaNotificationService.schedulePrayerTimesReminders
    → resolvePrayerSound(soundProfile) → DarwinNotificationDetails(sound: <clip>.caf)

معاينة داخل الإعدادات (قبل الحفظ):
  Android: MethodChannel talia/adhan_preview → MediaPlayer في MainActivity
  iOS:     just_audio.setAsset('res/raw/<clip>.caf')
```

### قرارات تصميمية أساسية

1. **حقل `soundProfile` الموجود أصلاً هو قناة النقل الوحيدة** — لا تغيير
   على عقد MethodChannel، ولا على الترميز المحفوظ (encode/decode)، ولا على
   هوية الإنذارات (`requestCode`)، ولا على الاستعادة بعد إعادة التشغيل.
   القيمة الجديدة تسير مجاناً داخل البنية القائمة.
2. **ترميز تجاوز الفجر** `fajr:<id>`: بادئة داخل نفس الحقل بدل عمود جديد —
   كل من لا يفهم البادئة يتعامل معها كقيمة غير معروفة ويسقط إلى الافتراضي
   بأمان (fallback بالتصميم).
3. **القنوات الصوتية على Android**: معرّف القناة يتضمّن لاحقة المؤذن
   (`talia_prayer_times_athan_<id>`) لأن أندرويد يجمّد صوت القناة عند
   الإنشاء؛ `default` يحتفظ بالمعرّف التاريخي `talia_prayer_times_athan`.
   في مسار V2 الأصلي لا تُستخدم أصوات القنوات أصلاً (الخدمة تشغّل الصوت
   بنفسها)، والقنوات تخص مسار FLN/legacy.
4. **الفشل الآمن في كل الاتجاهات**: أي قيمة غير معروفة/فارغة/تالفة تنزل
   إلى المقطع الافتراضي (`adhan`) في كل من `AdhanClipResolver` (Kotlin)
   و`_clipForProfile` (Dart) — لا يمكن أن يفشل الأذان بسبب قيمة تفضيلات.
5. **المعاينة منفصلة تماماً عن التسليم**: قناة `talia/adhan_preview`
   تشغّل MediaPlayer داخل MainActivity (واجهة أمامية، لا حاجة لخدمة
   أمامية)، ولا تلمس الإنذارات أو الإشعارات أو الجدولة إطلاقاً.

## 5. ضمان التزامن (بلا تأخير أو فقدان)

- المؤذن يؤثر فقط على الملف المُشغَّل، وليس على توقيت الإنذارات؛ نفس
  الإنذارات الدقيقة (setExactAndAllowWhileIdle) وبنفس `requestCode`.
- تغيير المؤذن يستدعي `_reschedule` فوراً: إلغاء-أولاً ثم تسجيل أحداث
  جديدة — القاعدة الذهبية (لا يبقى إنذار قديم وجديد لنفس الوقعة).
- تغيير المؤذن لا يلمس `prayer_delivery_version` ولا يسبب هجرة.
- اختيار المؤذن مضاف إلى `load()` الافتراضي في الحالة عبر القراءة المباشرة
  من prefs عند فتح الـsheet (لا يلزم حقن جديد في الـcubit state).
- بعد إعادة تشغيل الجهاز: `PrayerRecoveryReceiver` يعيد تسليح نفس الأحداث
  المحفوظة — تشمل `soundProfile`، فالأذان المختار يبقى صحيحاً.

## 6. الملفات المتغيّرة

**صوتيات (جديدة):** 5 × `res/raw/adhan_*.mp3` + 5 × `ios/Runner/adhan_*.caf`

**Android Kotlin:**
- `prayer/AdhanClipResolver.kt` — خريطة المؤذنين + `fajr:` + fallback.
- `prayer/AdhanPreviewBridge.kt` (جديد) — نسخ المقطع إلى cache وإرجاع
  `content://` عبر FileProvider للاحتياط.
- `MainActivity.kt` — قناة `talia/adhan_preview` (resolve/previewStart/
  previewStop) مع MediaPlayer مُدار.
- `AndroidManifest.xml` + `res/xml/file_paths.xml` — FileProvider للمعاينة.

**Dart:**
- `core/services/prayer_sound.dart` — `Muezzin`, `MuezzinCatalog`,
  `soundProfileForPrayer`, وتوسيع `resolvePrayerSound`.
- `core/services/adhan_preview_service.dart` (جديد) — معاينة متعددة
  المنصات (قناة أصلية على Android، just_audio على iOS).
- `core/prayer_delivery/prayer_event_builder.dart` — تمرير المؤذن إلى
  `soundProfile` لكل حدث.
- `core/services/notification_service.dart` — مفاتيح prefs جديدة +
  `_prayerAthanDetails(soundProfile:)` + تمرير عبر
  `schedulePrayerTimesReminders`.
- `core/services/notification_scheduler.dart` — قراءة المؤذنين من prefs
  وتمريرهما للمسارين (V2 وlegacy).
- `features/settings/presentation/cubits/notification_settings_cubit.dart`
  — `setMuezzin`/`setFajrMuezzin` + getter `prefs`.
- `features/settings/presentation/widgets/settings_notification_tiles.dart`
  — صف اختيار المؤذن + bottom sheet معاينة + قسم الفجر.
- l10n: `app_ar.arb` / `app_en.arb` (11 مفتاحاً جديداً) + إعادة التوليد.

**اختبارات:**
- `android/.../AdhanClipResolverTest.kt` (جديد — 7 اختبارات).
- `test/core/services/prayer_sound_muezzin_test.dart` (جديد — 12 اختباراً).

## 7. مصفوفة التحقق اليدوي المقترحة

| الحالة | المتوقع |
|---|---|
| فتح الإعدادات → إشعارات → مواقيت الصلاة + الأذان الكامل | يظهر صف «اختيار المؤذن» |
| الضغط على صف المؤذن | bottom sheet بقائمة المؤذنين + زر معاينة لكل صف |
| تشغيل معاينة ثم اختيار مقطع آخر | المعاينة الأولى تتوقف تلقائياً |
| اختيار «علي أحمد ملا» + حفظ | يعود الصف باسم المؤذن؛ الأذان القادم بصوته |
| قسم «أذان الفجر» → «مشاري العفاسي» | أذان الفجر فقط يتغير، والباقي يبقى |
| تغيير المؤذن قبل أقرب صلاة بدقائق | الأذان القادم يأتي بالمقطع الجديد (إعادة جدولة فورية) |
| إغلاق التطبيق كلياً ثم انتظار وقت الصلاة | الأذان يعمل بالمؤذن المختار (AlarmManager مستقل عن التطبيق) |
| إعادة تشغيل الهاتف | الاستعادة تعيد نفس المؤذن (soundProfile محفوظ مع الحدث) |
| قيمة prefs تالفة (مثلاً "xyz") | يُستخدم الافتراضي ولا يفشل الأذان |
| وضع «صامت/لا تُزعج» | سلوك التركيز الصوتي القائم كما هو (الخدمة تلتزم) |
