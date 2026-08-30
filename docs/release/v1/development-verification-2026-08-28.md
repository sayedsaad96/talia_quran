# دليل تحقق Talia V1 — مرحلة التطوير

## القرار

**نجاح محلي لمرحلة التطوير، والإصدار للنشر ما زال `NO-GO`.** نجح التحليل وجميع الاختبارات، ولم يُبنَ Android Release بناءً على قرار مالك المشروع بأن العمل ما زال في مرحلة Debug. لا تمثل هذه الوثيقة Release Candidate مجمّدًا أو تصريحًا بالنشر.

## هوية التشغيل

| الحقل | القيمة |
|---|---|
| وقت التشغيل (UTC) | `2026-08-27T23:51:00Z` |
| الفرع | `v1-minimum-safe-release` |
| Git HEAD | `10b274778bbfca6b7defcb88448e1c2f16b84540` |
| حالة مساحة العمل | `DIRTY — NOT FROZEN` |
| إصدار التطبيق | `1.0.0+1` من `pubspec.yaml` |
| Flutter | `3.47.1`، framework `6655482ec0` |
| Dart التنفيذي المستخدم | `3.13.1` |
| Dart المبلّغ عنه بواسطة Flutter | `3.12.2` |
| بصمة لقطة المصدر | `f3ee11d782b4b0831a635a293c0cc0bcead4e093873e344a0512693c4591b234` |
| Android Release artifact | `NOT RUN` |

## الأمر المنفذ

من جذر المستودع على Windows PowerShell:

```powershell
pwsh -NoProfile -File .\scripts\verify_v1_release.ps1
```

هذا هو التشغيل الافتراضي الآمن في مرحلة التطوير. لا يبدأ بناء Android Release. عند الوصول إلى Release Candidate فقط، يتطلب البناء اختيارًا صريحًا موثقًا في الأداة باسم `-BuildAndroidRelease`.

## النتائج القابلة لإعادة التنفيذ

| الفحص | النتيجة | الدليل |
|---|---|---|
| استعادة الاعتمادات مع ملف القفل | `PASS` | `flutter pub get --enforce-lockfile`؛ لم يتغير `pubspec.lock` |
| توليد الترجمة | `PASS` | `flutter gen-l10n` |
| توليد الملفات | `PASS` | `dart run build_runner build --delete-conflicting-outputs` |
| انجراف الملفات المولدة | `PASS` | لا اختلاف في البصمات قبل/بعد التوليد |
| التحليل الساكن | `PASS` | `No issues found` |
| مجموعة اختبارات Flutter الكاملة | `PASS` | `1036/1036`، وتشمل اختبارات Golden الخاصة بالتهيئة |
| Android Release | `NOT RUN` | لم يُطلب في مرحلة Debug |
| فحص أصول حزمة Android | `NOT RUN` | يتطلب artifact مبنيًا صراحة |

السجلات الكاملة محلية تحت [`build/release-evidence/v1/20260827T235100Z`](../../../build/release-evidence/v1/20260827T235100Z/summary.md). أداة التحقق هي [`scripts/verify_v1_release.ps1`](../../../scripts/verify_v1_release.ps1)، وعقدها الآلي في [`test/scripts/v1_release_verification_contract_test.dart`](../../../test/scripts/v1_release_verification_contract_test.dart).

## بصمات المحتوى الحالي

| الملف | SHA-256 |
|---|---|
| [`assets/data/quran.json`](../../../assets/data/quran.json) | `050df81ce2cb4011f77410978850ff641589a4091489e9da0fdd31018dd26f31` |
| [`assets/data/surahs.json`](../../../assets/data/surahs.json) | `125fcff463dce28148ac4c035b77caf3093213535c88b6e67585e09b23fc9ca0` |
| [`assets/data/content_manifest.json`](../../../assets/data/content_manifest.json) | `c93c45e6817659b27048360b50157172989f875812de762bb0d0ef49ef631257` |
| [`assets/data/azkar_release.json`](../../../assets/data/azkar_release.json) | `aba4355998f31581b95610f96182b809b8b3c0bdc11200c58cf1e41e8c8bf3b7` |
| [`scripts/verify_v1_release.ps1`](../../../scripts/verify_v1_release.ps1) | `1293258700a9d97298b0cfb216b677accc5cbf9313c3355ca13adb7f5e3b8b6e` |

قائمة الأذكار المسموح بها حاليًا تحتوي **صفر سجل** في فئات `morning` و`evening` و`general` و`duas`. واجهة الأذكار محفوظة كحالة فارغة آمنة؛ ملف المرشحين `assets/data/azkar.json` ليس ضمن أصول Flutter، لكن غيابه من الحزمة النهائية يبقى `NOT RUN` إلى أن يُبنى artifact الإصدار صراحة.

## حالة بوابات G0–G9

| البوابة | الحالة الحالية | المالك | سبب عدم الإغلاق إن وجد |
|---|---|---|---|
| G0 — إيقاف توسع النطاق | `BLOCKED` | مدير الإصدار | النطاق محصور في V1-M، لكن مساحة العمل غير ملتزمة وRC غير مجمّد |
| G1 — سلامة القرآن | `PASS (LOCAL)` | هندسة Flutter/المحتوى | اختبارات البنية والبصمات والعرض الدقيق نجحت؛ الاعتماد الشرعي النهائي في G8 |
| G2 — المحتوى الديني | `BLOCKED` | هندسة المحتوى | allowlist الآمنة واختباراتها نجحت محليًا؛ فحص غياب المرشحين من artifact لم يُنفّذ |
| G3 — سلامة بيانات المستخدم | `PASS (LOCAL)` | هندسة المزامنة | اختبارات الإشارات المرجعية وتبديل الحساب نجحت |
| G4 — الخلفية/الأمان | `BLOCKED / NOT RUN` | مالك الخلفية/الأمان | Fresh/Staging/Production Supabase غير متاحة في هذا التشغيل |
| G5 — Offline/الخصوصية | `PASS (LOCAL)` | Flutter/المنتج | مسارات Adult/Kids اليدوية ونصوص الخصوصية واختباراتها نجحت |
| G6 — التحقق الهندسي | `BLOCKED` | مهندس الإصدار | analyzer والاختبارات نجحا؛ Android Release artifact لم يُبنَ |
| G7 — الجهاز/المتجر | `NOT RUN` | QA/الإصدار | يحتاج أجهزة فعلية ونسخة داخلية موقعة |
| G8 — الاعتماد الإسلامي | `NOT RUN` | المراجع الإسلامي المؤهل | حزمة المراجعة جاهزة، ولا توجد موافقة بشرية بعد |
| G9 — هوية artifact | `NOT RUN` | مدير الإصدار | لا يوجد artifact إصدار مجمّد/موقع |

## موانع الإصدار الحالية

- `applicationId` ما زال `com.example.talia_quran`، وتوقيع Release مضبوط على مفتاح Debug؛ يلزم قرار هوية وتوقيع حقيقي عند بدء مرحلة الإصدار.
- متغيرات `TALIA_SUPABASE_FRESH_DB_URL` و`TALIA_SUPABASE_STAGING_DB_URL` و`SUPABASE_DB_URL` لم تكن متاحة؛ فحوص الخلفية `NOT RUN`.
- بناء Android Release، فحص أصوله، التثبيت النظيف/الترقية، المسار الداخلي، وسياسات المتجر `NOT RUN`.
- مساحة العمل غير نظيفة؛ لذلك commit/manifest/artifact غير مجمدة ولا تصلح لاعتماد نهائي.
- موافقة المراجع الإسلامي المؤهل `NOT RUN`.

## ما يلزم عند الانتقال من Debug إلى RC

1. تثبيت هوية Android والتوقيع وقيم الإنتاج دون وضع أسرار في المستودع.
2. تجميد commit نظيف، ثم تشغيل الأداة مع `-BuildAndroidRelease` من ذلك commit.
3. إثبات أصول artifact وبصمته، وتشغيل Fresh/Staging/Production contracts.
4. تنفيذ [قائمة فحص Android الفعلي](physical-android-checklist.md).
5. إرسال [حزمة المراجعة الإسلامية](islamic-review-packet.md) مع artifact والبصمات واللقطات، ثم عدم تغيير المحتوى بعد الاعتماد.
