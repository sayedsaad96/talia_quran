# تقرير التدقيق النهائي للجاهزية للإنتاج — Talia Quran / تاليه

- **تاريخ الأدلة والفحوص:** 7 أكتوبر 2026، Africa/Cairo.
- **تاريخ حفظ التقرير:** 8 أكتوبر 2026.
- **Git HEAD الذي استهدفه التدقيق:** `af6c2e18cfceb7acc28d80758373637f7a60cf00`.
- **نطاق المراجعة:** ملفات مساحة العمل التي فُحصت أثناء التدقيق، وليس commit وحده؛ لم تثبت نظافة مساحة العمل عبر git status بسبب خطأ بيئي.
- **الحكم:** ❌ NOT READY FOR PRODUCTION.
- **حالة التحقق التشغيلي:** غير مكتمل؛ لم تتوفر رحلة Android على النسخة الحالية.
- **الدرجة الإجمالية:** 45/100، تقدير هندسي تحفظي وليس متوسط درجات الأقسام أو نسبة نجاح الاختبارات.
- **سياسة العمل:** التدقيق دون إصلاح المصدر أو المحتوى أو الخادم. إنشاء هذا الملف هو توثيق طلبه المستخدم لاحقًا، وليس موافقة على تنفيذ الإصلاحات.

> هذا الملف يحفظ نتائج التدقيق السابق بالتفصيل. لم تُعد الفحوص في 8 أكتوبر، وأي تغيير لاحق في المصدر أو الاعتماديات أو الخادم يحتاج إعادة تحقق من النتائج المتأثرة. أرقام الأسطر تشير إلى النسخة المفحوصة وقد تتغير لاحقًا.

## دليل قراءة الأدلة

| التصنيف | المقصود |
| --- | --- |
| مثبت بالبيانات | مقارنة حتمية أو فحص مباشر كشف اختلافًا فعليًا |
| مثبت بالمصدر | مسار التنفيذ أو نقص الحماية موجود في الكود؛ ليس بالضرورة عيبًا أعيد إنتاجه على جهاز |
| مختبر آليًا | نجح اختبار موجود في حاضنة الاختبار، وفق حدود البدائل والمنصة المستخدمة |
| موثق على الخادم | فحص metadata حي، دون قراءة سجلات المستخدمين أو تشغيل إجراءات الأعمال |
| خطر أو بوابة مفتوحة | توجد أسباب كافية لطلب تحقق إضافي؛ ليس ادعاء بوقوع فساد أو اختراق |
| غير متحقق | لم تتوفر بيئة أو جهاز أو حساب اختبار أو دليل قبول كافٍ |

### درجات الخطورة

- **P0 — BLOCKER:** يمنع النشر، بما في ذلك الاحتمال الموثوق لالتباس النص القرآني أو هوية الآية.
- **P1 — CRITICAL:** خطر إنتاج جاد أو شرط قبول حرج غير مكتمل.
- **P2 — HIGH:** يجب إصلاحه قبل النشر.
- **P3 — MEDIUM:** مشكلة متوسطة أو قيد يستلزم قرارًا وتحقيقًا.
- **P4 — LOW / POLISH:** تحسين أو تنظيف محدود.

## 1. الملخص التنفيذي

التطبيق يمتلك بنية واسعة ومنظمة نسبيًا، واختبارات كثيرة، وفصلًا متعمدًا لهوية الحسابات ومساري البالغ والأطفال، واهتمامًا بالعربية والمحتوى. نجح التحليل الساكن، ونجح تقسيمان للاختبارات: 3,488 اختبارًا خارج وسم golden، واختباران للمقارنة البصرية للرئيسية.

لكن النجاح الآلي لا يكفي للنشر. بقيت ثلاث بوابات P0:

1. اختلاف 56 تعيين صفحة وتعييني جزء بين بيانات القرآن المحلية وQCF 0.0.8 المستخدم فعليًا.
2. إمكان بقاء معلومات صفحة قديمة بجانب نص صفحة أخرى بسبب الاستجابات غير المتزامنة.
3. عدم حسم عزو وعدد ووقت بعض الأذكار، مع فجوات في توثيق المصادر والحقوق لسجلات الحديث.

كذلك كشف المصدر مخاطر تزامن وتشغيل الصوت، ونتائج بحث قديمة، وتطبيع مدخل حفظ غير صالح إلى آية أخرى، وحاجة إلى وصول دلالي أفضل للمصحف.

لم يتوفر جهاز Android متصل أو AVD معدّ. فشل بناء AAB الحالي بخطأ Java/Gradle في إنشاء اتصال loopback. هذا يمنع اعتماد البناء ولا يثبت عيبًا في ترجمة التطبيق.

فحص Supabase الحي أثبت نشر الترحيلات الأمنية الحالية وتفعيل RLS على 21 جدول بيانات مستخدمين، مع قيود وصول في RPCs الحرجة المفحوصة. لم يثبت التنفيذ الفعلي لسياسات المالك وغير المالك؛ لم تُقرأ بيانات المستخدمين أو تُنفذ عمليات أعمال.

## 2. درجة الجاهزية ونتائج الفحوص

| المجال | الدرجة /100 | سبب التقدير وحدوده |
| --- | ---: | --- |
| الاستقرار الوظيفي | 70 | تغطية آلية واسعة؛ لا قبول تشغيلي على Android |
| تجربة القرآن | 25 | بوابات P0 للخرائط وربط الصفحة بالبيانات |
| الحفظ | 65 | اختبارات منطق واستئناف؛ رحلة جهاز كاملة غير مثبتة |
| تجربة الأطفال | 60 | تغطية الحالة والمكافآت؛ أجهزة الربط والفهم الفعلي غير مختبرة |
| UI/UX | 75 | لغة بصرية متماسكة ومراجعة مصدر؛ لا تقييم شامل للشاشات الحالية |
| الوصول | 50 | دعم جزئي جيد؛ دلالات المصحف وTalkBack غير مكتملة |
| الأداء | 45 | تحسينات مصدرية؛ لا قياسات جهاز أو profile |
| جودة الكود | 75 | تحليل نظيف؛ ثغرات في ملكية العمل غير المتزامن وملفات كبيرة |
| المعمارية | 70 | Cubit/repository/use case/DI؛ فصل الحالة المتزامنة يحتاج ضبطًا |
| الأمان | 65 | metadata حي إيجابي؛ فحوص صلاحيات التنفيذ الفعلية ناقصة |
| سلامة البيانات | 40 | تعارض خرائط القرآن ومخاطر الحالة القديمة |
| سلامة المحتوى الديني | 30 | موافقات موثقة؛ أسئلة عزو ومصدر وحقوق ما زالت مفتوحة |
| إعداد الإصدار | 35 | توقيع مهيأ؛ لا AAB ناجح أو تحقق Console |

### سجل التحقق الجديد

| الأمر / الفحص | النتيجة | حدود الدليل |
| --- | --- | --- |
| `dart analyze` | exit 0؛ No issues found | تحليل ساكن فقط |
| `dart analyze lib test packages` | exit 0؛ No issues found | لا يشمل إثبات السلوك الأصلي للمنصة |
| `flutter test --no-pub --reporter expanded --exclude-tags golden` | exit 0؛ 3,488 نجاحًا؛ 9m48s | اختبارات host، وليست كل رحلات Android |
| `flutter test test/features/home/presentation/widgets/home_night_goldens_test.dart --no-pub --reporter expanded` | exit 0؛ اختباران ناجحان؛ نحو ثانيتين | مقارنة الرئيسية في dark/light ضمن fixtures |
| بحث المجموعة بوسم golden فقط | تعثر قبل التقدم ثم أوقف؛ exit 1 | ليس فشل assertion؛ المجموعة المتبقية شغلت مباشرة |
| بناء AAB release مع `--no-pub --dart-define-from-file=.env` | exit 1؛ Unable to establish loopback connection | خطأ بيئة Java؛ لا artifact صالح للفحص |
| `adb devices -l` | لا أجهزة متصلة | لا QA على Android |
| `emulator.exe -list-avds` | لا AVD معدّ | لا بديل محاكي جاهز |
| اكتشاف الأجهزة عبر Flutter | تعثر وأوقف | لم يُستخدم لإثبات وجود جهاز |
| `flutter pub get` | لم يشغل | الحفاظ على lockfile وعدم تغيير حل الاعتماديات |
| metadata Supabase حي | اكتمل | لا business RPCs أو قراءة بيانات مستخدمين |

**تفسير العد:** 3,488 + 2 = 3,490 نجاحًا عبر تقسيمين مكتملين. لا يوصف ذلك بأنه تشغيل شامل واحد دون انقطاع، ولا يُستخرج منه قياس coverage. ظهر تحذير بأن وسم golden غير معرف في dart_test.yaml.

### هوية الأدلة السابقة

الأدلة في audit_artifacts/production_2026_10_06 كانت مراجعة تاريخية مختلفة في revision وإصدار QCF. استخدمت كمرشحات للتحقق فقط. لم تعتبر الصور القديمة إثباتًا لشاشات النسخة الحالية. تم إسقاط finding اختلاف إصدار QCF السابق: الإصدار الحالي 0.0.8 مطابق لهوية manifest/lock.

## 3. موانع P0

### P0-01 — تعارض خرائط الصفحة والجزء بين مجموعتي القرآن النشطتين

**الحالة:** اختلاف بيانات مثبت؛ أثر الواجهة مستنتج من مسارات المصدر، دون إعادة إنتاج على جهاز.

**الأدلة والمواقع:**

- [بيانات القرآن المحلية](../../assets/data/quran.json).
- [رسم صفحات QCF](../../lib/features/quran/presentation/widgets/app_quran_page_view.dart)، قرب 172.
- [حل الآية بالضغط المطول](../../lib/features/quran/presentation/pages/quran_reader_page.dart)، قرب 512.
- [جلب الصفحة من المستودع](../../lib/features/quran/data/repositories/quran_repository_impl.dart)، قرب 60.
- [هوية الصفحة في الصوت](../../lib/core/services/quran_continuous_player_service.dart)، قرب 171.
- [اختبار البنية المحلية](../../test/assets/corpus_integrity_test.dart).

قورنت 6,236 آية بين quran.json وqcf_quran_plus 0.0.8. معرّفات السورة والآية والرقم العام متطابقة، لكن 56 صفحة وتعييني جزء تختلف.

| المثال | المحلي | QCF |
| --- | --- | --- |
| 5:77 | page 121 | page 120 |
| 3:92 | juz 3 | juz 4 |

**الرحلات المتأثرة:** قراءة المصحف، الانتقال إلى آية، الضغط المطول، خيارات الآية، العلامات، الصفحة المرتبطة بالصوت، التظليل، معلومات الجزء.

**الفشل المحتمل:** QCF يعرض الآية في صفحة، بينما حل الآية أو متابعة الصوت يبحث في صفحة أخرى. الضغط المطول قد يفشل بصمت، والصوت قد ينقل القارئ بعيدًا عن الآية المسموعة أو يفقد تظليلها.

**خطوات إعادة الإنتاج المطلوبة:**

1. افتح QCF page 120.
2. اضغط مطولًا على 5:77؛ افحص ظهور الخيارات ومعرّف الهدف.
3. شغل الآية عبر مسار متاح ثم فعّل متابعة الصوت.
4. افحص الصفحة المعروضة والتظليل والعلامة المحفوظة.
5. افحص الجزء عند الحدود المختلف عليها.

**السبب الجذري:** أكثر من مرجع بنيوي نشط دون عقد يثبت اتفاق page/juz بين الرسم والمنطق.

**الإصلاح المقترح:** مقارنة كل تعيين مع إصدار حفص المعتمد المحدد، وتثبيت مرجع واحد متسق أو طبقة ربط موثقة. لا نقرر تلقائيًا أي الطرفين صحيح، ولا نصحح القرآن بالتخمين.

**خطر الإصلاح:** مرتفع؛ قد يعيد تفسير موضع القراءة والعلامات والتقدم المخزن. يلزم تحليل توافق وترحيل واسترجاع.

**شرط الإغلاق:** مقارنة حتمية لكل الآيات، وحسم كل اختلاف، ثم اختبارات actions/audio/bookmarks/progress على الصفحات الحدودية والجهاز.

### P0-02 — استجابة صفحة قديمة يمكن أن تغيّر بيانات الصفحة الحالية

**الحالة:** مسار مصدر مثبت؛ أثر مرئي لم يختبر على Android.

**المواقع:**

- [QuranPageCubit.loadPage](../../lib/features/quran/presentation/cubits/quran_page_cubit.dart)، قرب 62.
- [مستمع تفاصيل القارئ](../../lib/features/quran/presentation/pages/quran_reader_page.dart)، قرب 673.
- نفس القارئ قرب 698 و767 و803: الاحتفاظ بـ_currentDetail، طلبات التنقل، وبيانات الشريط.
- [PageView المستقل](../../lib/features/quran/presentation/widgets/app_quran_page_view.dart)، قرب 130.

**الوصف:** لا request generation بعد انتظار المستودع. يستقبل القارئ نجاح أي طلب ويحتفظ بالتفاصيل السابقة أثناء التحميل والخطأ، بينما PageController يعرض QCF page أخرى.

**لماذا يمنع النشر:** يمكن أن يكون النص صحيحًا بذاته لكن الصفحة/السورة/الجزء أو سياق الإجراء مرتبطًا بصفحة مختلفة؛ هذا يربك هوية القرآن.

**إعادة الإنتاج:** أخّر طلب A، انتقل إلى B، أعد نتيجة B ثم A. افحص النص والعنوان والصفحة والإجراء. أعد السيناريو مع فشل B بعد نجاح A، ثم اخرج قبل اكتمال الطلب لاختبار emit بعد close.

**السبب:** عدم ربط نتيجة الطلب بهوية الصفحة المعروضة أو عمر Cubit.

**الإصلاح:** latest-request-wins، والتحقق من الصفحة المطلوبة وisClosed بعد await، وإظهار خطأ استردادي إذا لم توجد تفاصيل مطابقة بدل استعمال تفاصيل قديمة.

**خطر الإصلاح:** متوسط؛ المؤقت والتأكيد والتمرير والتمييز والعلامات تحتاج regression.

**شرط الإغلاق:** اختبار deterministic لترتيب النتائج المعكوس، والخروج أثناء الطلب، وفشل التحميل، ثم فحص جهاز لارتباط كل إجراء بالنص المرئي.

### P0-03 — نسب وقيد تعبدي يحتاجان حسمًا مع فجوات مصدرية أوسع

**الحالة:** بوابة محتوى غير محسومة؛ ليست دعوى أن الأذكار كلها خاطئة أو لم يراجعها أحد.

**المواقع:**

- [azkar_release.json](../../assets/data/azkar_release.json)، سجلا m12 وe13 في السطر المضغوط 2/3.
- [manifest](../../assets/data/content_manifest.json)، قرب 75.
- [ZikrModel](../../lib/features/azkar/data/models/zikr_model.dart)، قرب 58.
- [مصدر الأذكار](../../lib/features/azkar/data/datasources/azkar_local_datasource.dart)، قرب 30.
- [سياسة مصادر المحتوى](../TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md).

**الأدلة:** من 116 سجلًا توجد 85 hadith، و30 quran، و1 dua. سجلات hadith الـ85 بلا sourceUrl أو authenticityGrade؛ 66 منها بلا رقم حديث. الموافقة وإعادة تأكيد المالك موثقتان، لكن ذلك لا يغلق أسئلة التوثيق والحقوق.

**المثال المحدد:** m12/e13 يستخدمان عزوًا عامًا لسنن أبي داود وعدد 7 في سياق الصباح/المساء. المصدر المفحوص يميّز الرواية المرفوعة والموقوفة، ويورد نقدًا واختلافًا في الزيادات؛ يلزم قرار مختص على الرواية والقيد المقصودين.

[نقاش الدرر السنية للسجلات ذات الصلة](https://dorar.net/azkar/adhkar/343).

**الأثر:** صحة أصل لفظ الدعاء لا تثبت بذاتها نسبته أو وقته أو عدده أو فضله. display/share ينشران السجلات؛ notification filter يستبعد غير المتحقق من درجته بشكل صحيح.

**الإصلاح:** حسم العنصر محل التعارض بمراجع محددة، وتوثيق اللفظ والرواية والعدد والوقت والفضل والحكم ومَن أصدره وقرار المراجعة. إكمال provenance والحقوق لباقي العناصر. لا اختراع تصحيح أو تخريج.

**خطر الإصلاح:** متوسط؛ سحب عنصر أو إعادة تصنيفه قد يمس المفضلات والعدّ والسجل. حافظ على stable IDs.

**شرط الإغلاق:** قرار موثق للعناصر المختلف عليها، وإثبات مصدر وحقوق لكل نطاق منشور وفق السياسة.

## 4. P1 — مشكلات حرجة

### P1-01 — تزامن أوامر الصوت قد يعيد تشغيل طلب قديم بعد Stop

**الحالة:** خطر تزامن مدعوم بالمصدر؛ لا إعادة إنتاج جهاز.

**الموقع:** [QuranContinuousPlayerService](../../lib/core/services/quran_continuous_player_service.dart)، قرب 219، 379، 432، 507، 530.

**الوصف:** playSurah/playPage/playAyah تنتظر جلب البيانات ثم تغير queue المشتركة. إعداد القائمة ينتظر handler/stop/setAudioSources؛ لا token يلغي إكمال الطلب السابق. Stop لا يبطل تلك الأعمال. play() غير awaited أو ملتقط الفشل المستقبل، فلا يحميه catch المحيط عند رفض Future لاحقًا.

**الرحلات:** تشغيل A ثم B، Stop أثناء loading، تغيير القارئ، الخروج، فقد الشبكة، foreground/background.

**الأثر:** إعادة تشغيل غير مقصودة، queue قديمة، أو حالة playing مضللة بعد فشل التشغيل.

**إعادة الإنتاج:** اضبط مصدر/مشغل اختبار مع await قابل للتحكم؛ ابدأ A ثم B أو Stop ثم أكمل A. أعد مع rejected play Future.

**الإصلاح:** ملكية operation واضحة ورفض النتائج القديمة، أو تسلسل آمن للأوامر، ومعالجة asynchronous playback failure. لا يكفي await play مباشرة دون فهم عمر Future في مشغل الصوت.

**خطر الإصلاح:** متوسط إلى مرتفع؛ إشعار الوسائط وqueue والتشغيل المتصل والتخلص تحتاج فحصًا.

**شرط الإغلاق:** اختبارات race/error ثم جهاز للشبكة والانقطاع والوسائط والخلفية.

### P1-02 — لا artifact إصدار حالي ناجح أو قبول جهاز

**الحالة:** بوابة إصدار غير مكتملة، وليست عيب ترجمة مثبتًا.

**الدليل:** بناء AAB الحالي فشل بـJava IOException: Unable to establish loopback connection. لم ينتج artifact صالح ولم يُفحص أو يثبت.

**الإصلاح:** استعادة بيئة بناء سليمة أو CI نظيف، بناء موقّع، حفظ SHA-256، فحص merged manifest والتوقيع والمكتبات ثم تثبيت النسخة نفسها.

**خطر الإصلاح:** منخفض لإصلاح البيئة؛ أعلى إن لزم تغيير toolchain/dependencies.

**شرط الإغلاق:** artifact ناجح مطابق للمصدر، ثم fresh install/upgrade وcritical journey checklist.

### P1-03 — اعتماد الخصوصية وبيانات الأطفال غير مكتمل

**الحالة:** فجوة حوكمة موثقة؛ لا حكم قانوني نهائي على دولة غير محددة.

**الموقع:** [STORE_PRIVACY_READINESS](../legal/STORE_PRIVACY_READINESS.md)، قرب 15–21.

**الأدلة:** الوثيقة تسجل نشر public HTTPS URLs، البريد والمواعيد، الاحتفاظ، المعالجين، النقل الدولي، جمهور المتجر والموافقة الأبوية القانونية كأعمال غير مغلقة. هذه أدلة نقص الاعتماد، وليست proof بأن رابطًا ما غير متاح الآن.

**الأثر:** cloud identity/progress/age/nickname وguardian sharing يحتاج إفصاحًا واتفاقًا مع الجمهور المقصود. QR linking وPIN ليسا إثبات موافقة قانونية.

**الإصلاح:** اعتماد الجمهور والبلدان ومسار الموافقة إن لزم؛ نشر السياسة والحذف؛ مواءمة Data Safety مع التشغيل الفعلي والاحتفاظ.

**خطر الإصلاح:** متوسط؛ تقييد الأطفال أو السحابة قد يغير الرحلات ومزامنة الحسابات.

**شرط الإغلاق:** أدلة URL/disclosures/consent/retention/contact والقرار في Console، وفحص حذف حساب اختبار.

## 5. P2 — أولوية عالية

### P2-01 — البحث قد يستبدل الاستعلام الحالي بنتيجة قديمة

- **الحالة:** نقص حارس نتائج مثبت بالمصدر؛ لا إعادة إنتاج جهاز.
- **الموقع:** [QuranSearchPage](../../lib/features/quran/presentation/pages/quran_search_page.dart)، قرب 34–60.
- **السبب:** debounce يلغي timer، لا future بدأ فعليًا؛ النتيجة تطبق إن mounted فقط.
- **إعادة الإنتاج:** A ثم B أو مسح الحقل، وأكمل A بعد النتيجة الحديثة.
- **الأثر:** نتائج لا توافق الحقل واختيار آية غير التي يتوقعها المستخدم.
- **الإصلاح:** generation/query check وإبطال العمل عند كل تغيير ومسح.
- **خطر الإصلاح:** منخفض؛ حافظ على loading/error/empty.
- **الإغلاق:** اختبار reordered futures وclear أثناء البحث.

### P2-02 — مدخل حفظ غير صالح يتحول بصمت إلى آية أخرى

- **المواقع:** [حارس route](../../lib/core/router/app_router.dart)، قرب 254؛ [session slicing](../../lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart)، قرب 480–490.
- **السبب:** التحقق من الحدود الدنيا فقط ثم clamp لآخر آية؛ blockSize كبير يشمل بقية السورة.
- **إعادة الإنتاج:** مرر surahId=1/startAyah=999/blockSize=999 إلى route V2 الداخلي.
- **الأثر:** تبدأ جلسة passage غير المقصود وقد تسجل نتائج عليه.
- **حد الدليل:** لم يثبت وصول خارجي عبر Android intent؛ manifest الخارجي المكتشف يخص password recovery، فلا تدعي shared-link reproduction.
- **الإصلاح:** تحقق من العدد الفعلي للسورة وحدود block product، وارفض البداية غير الصالحة برسالة قابلة للاسترداد.
- **خطر الإصلاح:** متوسط؛ end-of-surah truncation والاستئناف والمراجعة المشروعة يجب حفظها.

### P2-03 — التشغيل المتصل لا يستعمل cache الصوت المتاح

- **المواقع:** [audioSources](../../lib/core/services/quran_continuous_player_service.dart)، قرب 461؛ [AudioCacheService](../../lib/core/services/audio_cache_service.dart)، قرب 62.
- **الحالة:** مصدر يثبت إنشاء URI بعيد فقط؛ السيناريو offline يحتاج جهاز.
- **الأثر:** تنزيل آية للحفظ لا يثبت تشغيلها offline في القارئ المتصل.
- **إعادة الإنتاج:** cache آية عبر الحفظ، فعّل وضع الطيران، ثم شغلها في reader continuous.
- **الإصلاح:** توحيد حل مصدر الوسائط cached/local ثم remote، مع هوية القارئ والآية.
- **خطر الإصلاح:** متوسط؛ latency/prebuffer/cache validity.
- **الإغلاق:** cached/uncached/mixed playlist tests وجهاز دون شبكة.

### P2-04 — المصحف لا يملك مسار semantics عربي موثق للآيات

- **الموقع:** [AppQuranPageView](../../lib/features/quran/presentation/widgets/app_quran_page_view.dart)، قرب 172؛ QCF 0.0.8، lib/src/widgets/quran_line.dart.
- **الدليل:** RichText/Text.rich يرسمان qcfData/glyph دون Semantics/semanticsLabel عربي للآيات.
- **الأثر:** قارئ الشاشة قد يقرأ رموز الخط أو يفقد نص وحدود الآية. هذا مستنتج؛ لم يُختبر TalkBack فعليًا.
- **الإصلاح:** canonical Arabic semantics مع surah/ayah association، أو وضع قراءة قابل للوصول.
- **خطر الإصلاح:** متوسط؛ لا تسمح باختلاف boundaries أو ترتيب الآيات عن العرض.
- **الإغلاق:** semantics tests ثم TalkBack على artifact الحالي.

### P2-05 — حماية كلمات المرور المسربة معطلة

- **الموقع:** إعداد Supabase Auth الحي، وليس ملف تطبيق.
- **الدليل:** live advisor: auth_leaked_password_protection disabled.
- **الأثر:** فجوة وقائية لكلمات مرور معروفة بالتسريب؛ لا دليل اختراق أو فقد حساب.
- **الإصلاح:** تفعيل الحماية وفق خطة الخدمة وفحص signup/password-change/error copy.
- **خطر الإصلاح:** منخفض؛ بعض كلمات المرور الجديدة قد تُرفض.
- **التصنيف:** أولوية أمنية عالية، وليس ادعاء أن جميع الحسابات الحالية غير آمنة.

## 6. P3 — مشكلات متوسطة

| الرمز | الوصف / الدليل | الأثر والسبب | الإصلاح وخطره |
| --- | --- | --- | --- |
| P3-01 | [kids_gamified_stage_page](../../lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart)، قرب 67؛ route يعيد locked placeholder | عند فشل getKidsJourney تبقى المرحلة مقفلة بلا retry واضح؛ لا تعتمد حالة route للترخيص | loading/error/retry موثق؛ متوسط، منع unlock غير مشروع |
| P3-02 | [app_shell](../../lib/core/widgets/app_shell.dart)، قرب 359/374 | durations ثابتة لـAnimatedContainer/AnimatedScale رغم reduced motion | Duration.zero عند disableAnimations؛ منخفض |
| P3-03 | [kids_house_card](../../lib/features/memorization_plus/presentation/widgets/kids_house_card.dart)، قرب 325؛ house_current.png | English QURAN CLASS/WELCOME داخل raster حتى بالعربية؛ لا يستطيع l10n تبديلها | art دون نص أو variants؛ متوسط بصريًا، لا دليل فساد نص قرآن |
| P3-04 | [qcf_hifz_verse_view](../../lib/core/widgets/qcf_hifz_verse_view.dart)، قرب 338 | حالة مقفل literal Arabic ضمن تجربة قابلة للإنجليزية | l10n key؛ منخفض، احفظ عدم كشف الآية المقفلة |
| P3-05 | [main](../../lib/main.dart)، قرب 85 | portrait lock يقلل خيارات منخفضي البصر/الأجهزة اللوحية؛ قيد نطاق لا عيب layout مثبت | قرار دعم وتحقق landscape إذا وسع النطاق؛ متوسط |
| P3-06 | live create_parent_reward(uuid,text) | SECURITY DEFINER مع search_path=public؛ تعتمد السلامة على schema privileges؛ لا exploit مثبت | empty path + fully qualified names، contract tests؛ متوسط |

## 7. P4 — تحسينات وتنظيف

| الفرصة | الموقع / السبب | المقترح والخطر |
| --- | --- | --- |
| PIN خارج localization | [family_dashboard_access](../../lib/features/memorization_plus/presentation/pages/family_dashboard_access.dart)، قرب 72 | تسمية مترجمة؛ خطر ضئيل |
| تحذير golden tag | test/features/home/presentation/widgets/home_night_goldens_test.dart | تعريف tag في test config؛ منخفض |
| ملفات تنسيق ضخمة | core/router/app_router.dart، core/di/injection.dart، memorization_session_cubit.dart، kids_mode_cubit.dart | تجاوز واضح لتوجيه 500 سطر؛ تقسيم لاحق موجه بالمسؤولية؛ refactor واسع قبل الإصدار خطره أعلى من فائدته |
| إرث البيانات/artwork | hifz، azkar.json غير النشط، assets/talia الأقدم | جرد owners/references قبل أي حذف؛ لا تقترح حذفًا تلقائيًا |

## 8. القرآن والمحتوى الديني

### المصادر والمحتوى المكتشف

| النوع | المورد الحالي | حالة المصدر / الحقوق / المراجعة |
| --- | --- | --- |
| القرآن العربي | assets/data/quran.json؛ manifest يذكر alquran.cloud quran-uthmani/Tanzil | موافقة مالك وhash وإدعاء تحقق upstream موثق في manifest؛ لم نقارن كل حرف upstream مستقلاً في هذا التدقيق |
| بنية السور | assets/data/surahs.json | مشتقة من corpus؛ اتساق داخلي مثبت، لا يحسم خلاف QCF |
| رسم المصحف | qcf_quran_plus 0.0.8 | dependency/locked hash مطابقان؛ page/juz disagreements ما زالت موجودة |
| آية اليوم | assets/data/daily_ayahs.json | 126 مرجعًا صالحًا وفريدًا؛ لا content مولد |
| الأذكار | assets/data/azkar_release.json | 116 approved records؛ owner reconfirmed،85 source/grade gaps،حقوق unknown |
| دعاء الختم | assets/data/khatm_dua.json | attribution إلى ملحق مجمع الملك فهد،مراجعة scholar/owner في manifest؛ fingerprint مطابق |
| التلاوة | روابط EveryAyah من خدمات الصوت | attribution موجود؛ لم يتحقق كل recording/right/segmentation مستقلاً |
| أذان | مصدر AWQAT وdocs/licenses/AWQAT_AUDIO_LICENSE.md | ملف حقوق موجود؛ lifecycle/native delivery غير مختبر جهازًا |
| تفسير/غريب/قصص مستقلة | لم يكتشف feature نشط | لا تسجل كميزات ناجحة أو مفقودة عيبًا دون وعد منتج |

### نتائج إيجابية وحدودها

- 114 سورة و6,236 معرّفًا مرتبًا.
- local hashes تطابق manifest.
- QCF0.0.8 locked identity PASS؛ issue upgrade القديم مغلق.
- daily ayah IDs صالحة.
- basmalah runtime split يعيد substrings ثابتة؛ corpus لا يكتب وقت التشغيل.
- لا confirmed Quran-text mismatch ضمن الفحوص المحلية.
- **لم يثبت التطابق المستقل لكل حرف مع المصدر الرسمي**؛ hash ليس canonical certification.
- [azkar_quran_text_contract_test](../../test/assets/azkar_quran_text_contract_test.dart) يستخدم skeleton lossy ويحذف مجموعات حروف ويبحث في آيات concatenated؛ لا يثبت النص الحرفي أو مرجع الآية.
- [all_surahs_ayah_long_press_test](../../test/features/quran/all_surahs_ayah_long_press_test.dart) يفحص page المحلي ضد نفسه، لا ضد QCF؛ لذلك لا يكشف P0-01.
- لا يجوز تصحيح النص أو الخرائط أو تخريج الحديث من ذاكرة نموذج.

[شروط نص Tanzil](https://tanzil.net/docs/Text_License) و[منصة المجمع](https://qurancomplex.gov.sa/en/techquran/dev/) مراجع لحسم الطبعة والنص والحقوق. notice الحالي في SourcesLicensesPage مختصر؛ يحتاج مراجعة مقابل شروط الإصدار المنقول، لا مجرد وجود رابط.

## 9. مسار البالغ

### الجرد

splash/onboarding → auth أو guest → home → Quran/index/search/bookmarks/reader/audio → memorization hub/practice/daily/custom/V2/recitation/review → progress/achievements/certificates؛ khatmah/azkar/settings/prayer/tutorial مسارات مرتبطة.

### التقييم

- ملفات repositories/usecases والقواعد والمسارات موثقة في الجرد.
- اختبارات host تفحص أجزاء من القراءة والحفظ والمراجعة والحساب والمزامنة.
- أهم المخاطر: page association،audio concurrency،search race،invalid V2 target.
- لم تُثبت رحلة مستخدم بالغ كاملة على device، أو حفظ التقدم عبر termination/upgrade.
- لا تعتبر compile أو وجود screen إثبات قابلية الاستخدام.

## 10. مسار الأطفال والعائلة

### الجرد

child onboarding/name/age/path → kids home → journey/stage → listen/recall/session → completion/next stage؛ missions/treasures/rewards؛ guardian PIN/session/QR linking/recovery → family dashboard/linked child/policies/reward approval.

### إيجابيات

- duplicate-completion protections وresume rules موجودة وتغطيها اختبارات.
- host guardian gift cycle PASS.
- source responsive grids وTalia learning-state mappings.
- guardian session/inactivity safeguards واختباراتها موجودة.

### بوابات قبول باقية

- الربط واستعادة PIN بجهازين، ورفض الكاميرا والرمز المتكرر والمنتهي.
- current/locked/completed stage بعد فشل البيانات أو restart.
- منع تخطي الخطوات الإلزامية تحت rapid taps/back/process death.
- عزل بيانات طفلين وحساب ولي الأمر عند تغيير الجلسة.
- السياسة والمهمات والمكافآت offline→online دون تكرار.
- فهم الطفل التعليمات دون شرح خارجي.
- الموافقة القانونية/الجمهور قبل cloud child processing.

### تجنب نقل findings قديمة

docs/REVIEW_kids_guardian_family_2026-10-07.md كان مصدر leads فقط. لم يُنقل كل finding فيه كحقيقة حالية دون إعادة تحقق. أمثلة ماسح QR والطفل المحلي الوهمي وتوقيت polling ليست عيوبًا مؤكدة في هذا التقرير لمجرد وجودها في الوثيقة التاريخية.

## 11. UI/UX وهوية Talia

فُحصت صور master character وtalia_happy وhouse_current بصريًا. الشخصية بألوان teal/gold والبيئة cream/gold متجانستان عمومًا. حالات listening/thinking/speaking/encourage/celebrate تتوافق مع التعلم في المصدر.

لكن لم تفحص كل شاشة حية: الحجم والموضع والحجب والوقت والتكرار والتفاعل العاطفي واللمس تحتاج الجهاز. English raster copy finding واضح في asset، لا يلزم تصوير قديم لإثبات وجود النص في الصورة.

الرسوم ذات مظهر rendered 3D لا تثبت وجود محرك 3D runtime. لا يوجد قياس GPU أو توصية أداء بناء على المظهر وحده.

## 12. الوصول وRTL والاستجابة

### ما تدعمه الأدلة

- Arabic/English localizations وRTL/LTR.
- icons direction-aware.
- shell nav selected semantics.
- kids cards meaningful labels.
- responsive grid shifts حسب العرض/text scale.
- reduced motion في كثير من onboarding/kids/home/azkar.
- settings RTL/LTR/dark/light وArabic2x pass في host tests.

### ما يحتاج اختبارًا

TalkBack boundaries/actions،focus order،IME/mixed numbers/punctuation،keyboard overlap،largest system fonts،tablet/split-screen،touch targets وcontrast measurements. صورة جميلة أو نص contrast يبدو جيدًا لا تثبت نسبة contrast معيارية.

P2-04 للمصحف وP3 shell motion/localization تعالج قبل claim accessibility-ready.

## 13. الأداء

### أدلة مصدرية إيجابية

- cache/index لبيانات القرآن والبحث.
- compute parsing وتحميل in-flight مشترك بدل تكرار decode.
- bundled fonts ومنع runtime Google Fonts fetch.
- repaint boundaries وتخفيف بعض تأثيرات الحركة.
- cleanup موجود لعدد من timers/subscriptions/audio components.

### قياسات لم تنفذ

startup/frame times/CPU/GPU/memory growth/image decode/shader warmup/battery/audio endurance/database contention.

**لا performance certification.** profile signed artifact على جهاز low-end مدعوم، مع تكرار page turns وkids scenes وaudio/navigation، ومتابعة memory قبل وبعد الخروج والخلفية.

## 14. الكود والمعمارية

التنظيم feature-first وCubit/repository/usecases/GetIt/GoRouter ظاهر بوضوح. core يحتضن identity/storage/sync/audio/prayer/memorization shared policies. StatefulShellRoute يحوي خمس وجهات للبالغ.

المشكلة الأهم في المراجعة ليست lint بل ملكية العمل async: ردود الصفحة والصوت تستطيع أن تعيش بعد intent المستخدم. clean analyzer لا يرصد هذا تلقائيًا.

ملفات router/DI/major Cubits تجاوزت project max-file guidance. الأولوية correctness قبل refactor.

### خطر تحقيق لم يثبت

initial V2 checkpoint save يبدأ unawaited. لم يثبت أنه يكتب حالة قديمة فوق أحدث لأن Isar قد يسلسل transactions. **ليس P1 data-loss مثبتًا**؛ يحتاج test controlled ordering إن تغير هذا المسار مستقبلًا.

## 15. الأمان والخصوصية

### metadata حي مثبت

المشروع المطابق: Talia_Quran، ref vxsqwozctxkvhgxkciua؛ ACTIVE_HEALTHY أثناء الفحص.

- security migrations حتى 20261005194008_harden_revoke_guardian_link منشورة.
- 21 public user-data tables مع RLS.
- sample profiles/parent_child_links/parent_rewards/kids_progress_cloud/kids_session_logs بلا anon DML grants.
- RPCs deletion/child identity/guardian/reward/PIN recovery sampled: postgres-owned SECURITY DEFINER؛PUBLIC/anon denied؛authenticated granted؛auth.uid guards وactive-link checks حيث ينطبق.
- delete_current_user يحتوي live auth.sessions check.
- parent_pin_recovery_requests: RLS بلا policies وبلا client table grants؛ وصول RPC فقط، فلا يُعامل advisor INFO كـleak.
- تحذيرات SECURITY DEFINER ليست كلها vulnerabilities؛ يجب قراءة grants/body.
- leaked-password protection disabled وsearch_pathpublic لأحدreward RPCs مسجلان كfindings.

لم تُقرأ سجلات مستخدمين، ولم تُشغل business RPCs أو deletes/mutations.

### أدلة مصدرية

Supabase URL/client anon key عبر dart-defines. .env ليس asset، وملفات env/signing مستثناة. client publishable/anon key ليس server service-role secret؛ سلامته تعتمد على RLS/authorization. لم يكتشف source-embedded production secret في المسارات المفحوصة.

### غير مثبت

التنفيذ الفعلي owner/non-owner/expired/revoked sessions؛الحذف مع interruption؛الاحتفاظ بالنسخ؛processor contracts؛system speech cloud handling؛privacy email operations. لا يُستنتج هذا من SQL definitions.

## 16. الإصدار وGoogle Play

### إعدادات مشروع مثبتة

| البند | الحالة |
| --- | --- |
| applicationId | com.talia.quran |
| version | 1.0.0+1 |
| compileSdk | 37 صريحًا |
| targetSdk | 36 من Flutter SDK المفحوص |
| minSdk | 24 من Flutter SDK المفحوص |
| signing | release configuration مستخدم؛ key.properties موجود محليًا؛ شهادة artifact لم تفحص |
| backup | disabled ومع dataExtractionRules |
| permissions | camera/mic/internet/notification/FGSmedia/boot/wake/exactalarm،مرتبطة بميزات |
| cleartext | لم يظهر إعداد cleartext في المسارات المفحوصة |
| native | prayer Kotlin/alarm/adhan وFlutter/dependency libraries؛ لا artifact acceptance |

تعليق signing القديم يقول debug، لكن configuration الفعلي release؛ لا finding debug-signing بناء على التعليق.

Target36 يوافق متطلب submissions الحالي حسب [Google Play target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en). eligibility وextension إن وجدت يحددان من Console.

16KB native compatibility **غير متحقق**. [Android page-size guidance](https://developer.android.com/guide/practices/page-sizes) المفحوص يذكر 1 فبراير2027 لإنفاذ تحديثات غير داعمة. لا تستعمل blog deadline قديم بدل النص الحالي وConsole؛ فحص ELF/ZIP/runtime لازم للartifact.

SCHEDULE_EXACT_ALARM ليس USE_EXACT_ALARM، ووجوده لا يثبت policy violation. فحص grant/deny/revoke/reboot/fallback وConsole eligibility مطلوب.

### Console/التشغيل الخارجي

- public HTTPS policy/deletion URLs تعمل دون login.
- Data Safety/target audience/Families/content rating/app access.
- release signing enrollment وversion-code uniqueness.
- foreground service declarations/permission review.
- pre-launch report/native compatibility/upload acceptance.
- retention/privacy contact/delete-request SLA وprocessor decisions.

[Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)،[User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)،[Account Deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) مراجع متطلبات، لا أدلة أن النماذج أرسلت.

### منصات أخرى

iOS purpose strings/background/deeplink مصدرها موجود، لكن archive/signing/VoiceOver غير متحقق على Windows. web/desktop ليست أساس الحكم الحالي ولا تُحتسب template leftovers فيها كعوائق Android تلقائية.

## 17. الميزات المتحقق منها بنجاح

**Test Verified في حاضنة host فقط:**

1. corpus structures/hash/QCF locked identity.
2. listening quiz uniqueness/next-ayah contracts.
3. host integration account switching/cloud merge/offline plan sync/progress snapshot.
4. guardian gift cycle وguardian-session tests.
5. settings RTL/LTR/theme و2x text scale case.
6. home loaded dark/light goldens.

**Metadata Verified:** نشر الترحيلات وRLS/grants/criticalRPC safeguards المفحوصة.

**Runtime Verified على Android الحالي:** لا رحلات كاملة.

يوجد test/integration بخمسة ملفات؛ تصحيح ادعاء سابق بعدم وجود integration tests: توجد host integration tests، لكن لم يكتشف integration_test device harness ولم يشغل جهاز E2E.

## 18. المناطق غير المتحقق منها ومصفوفة التغطية

| المنطقة | source/host evidence | device acceptance |
| --- | --- | --- |
| first launch/onboarding/return/login/recovery/delete | inventory/tests/metadata | غير متحقق |
| Quran navigation/actions/bookmarks/resume/dark/font | tests + P0 comparisons | غير متحقق |
| memorization/listen/recite/review/mandatorysteps/resume | extensive unit/widget/host tests | غير متحقق |
| child learning/missions/rewards/guardian | source + host integration | غير متحقق |
| khatmah/azkar/tasbeeh/sharing/certificates | source/host checks | غير متحقق |
| prayer/adhan/notification/deeplink/permissions | Dart/native source | غير متحقق |
| offline/weaknetwork/timeout/malformed/lifecycle/processdeath | partial simulated logic | غير متحقق شاملًا |
| accessibility/RTL/tablet/largefont | partial host cases | غير متحقق |
| performance/memory/GPU | source safeguards | غير مقاس |
| actual auth/RLS/deletion/2devices | live metadata only | لم تنفذ |
| exact authoritative all-character Quran verification | local frozen hashes | غير مكتمل |
| recitation-by-ear/rights/segmentation | attribution/source code | غير مكتمل |
| signed AAB/PlayConsole | config/docs + failedbuild | غير مكتمل |

لم يتحقق كل زر/card/dialog/sheet/filter/search/action على device. السبب محدد: لا جهاز/AVD، ولا artifact إصدار ناجح. لا يوصف التقرير بأنه full runtime coverage.

## 19. ترتيب الإصلاح الأكثر أمانًا

| الترتيب | العمل | شرط الانتقال |
| --- | --- | --- |
| 1 | حسم مرجع خرائط القرآن والعزو التعبدي والحقوق | authoritative decisions + deterministic comparisons + stored-state impact |
| 2 | latest-page ownership وdisposal/error recovery | reordered/failure/close tests + matching visible verse/actions |
| 3 | audio operation ownership/error/cache | races/stop/reciter/offline + media notification/lifecycle validation |
| 4 | search/session target validation/kids stage retry | specific regressions without weakening mandatory locks |
| 5 | privacy/child consent/retention/URLs | approved operational/legal evidence and Console reconciliation |
| 6 | Mushaf semantics/motion/localization/scope | TalkBack/RTL/largefont and visual validation |
| 7 | healthy signed release build | AAB SHA + mergedmanifest/signing/native16KB inspection |
| 8 | device gate on exact artifact | install/upgrade/offline/processdeath/audio/guardian/prayer/privacy paths |
| 9 | final acceptance | allP0 closed،P1 resolved،P2 fixed or explicitly reviewed،Console evidence complete |

### اختبارات رجوع مطلوبة قبل إغلاق النتائج

- مقارنة page/juz لكل6236آية بين الرسم والمنطق.
- QCF boundary verse longpress/bookmark/audio-follow identity.
- reader reordered loads/error/leave-during-load.
- audio A→B→Stop،change-reciter،rejected play،cached offline.
- search old response after new/clear.
- session start beyond surah count وoversized block.
- kids stage authoritative failure/retry.
- semantic verse text and IDs مع TalkBack.
- auth owners/nonowners/expiredsession وguardian two-device test accounts.
- deletion fail/restart/recovery.
- native alarms permissiondeny/revoke/reboot/timechange وآذان+Quran interruption.
- artifact install/upgrade ومطابقة hash.

هذه قائمة تحقق مقترحة؛ لم تُنشأ اختبارات أو إصلاحات بهذا التدقيق.

## 20. الحكم النهائي وشروط الإصدار

# ❌ NOT READY FOR PRODUCTION

سبب القرار هو بوابات القرآن والمحتوى المفتوحة، ومخاطر الصوت، وعدم اكتمال قبول خصوصية الأطفال وإصدار Android الفعلي.

**شروط الموافقة اللاحقة:**

1. حسم وإغلاق P0-01/P0-02/P0-03 بأدلة أصلية واختبارات مع الحفاظ على بيانات المستخدم.
2. معالجة مخاطر الصوت والمتطلبات الحرجة للخصوصية.
3. نجاح بناء موقّع وفحص artifact الحالي.
4. التحقق من الرحلات الحساسة على device للبالغ والطفل وولي الأمر.
5. اعتماد متطلبات Console والتشغيل الخارجي دون تخمين.
6. تحديث التقرير بنتائج الإغلاق الفعلية؛ لا تغيير severity لمجرد أن إعادة الإنتاج صعبة.

الاختبارات الناجحة تدعم الجودة، لكنها لا تلغي هذه الشروط. هذا التقرير لا يصرح بتنفيذ أي تعديل أو نشر.

## مراجع الأدلة المحلية

- [قواعد المشروع](../../.codex/AGENTS.md).
- [سياسة المحتوى الإسلامي](../TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md).
- [manifest المحتوى](../../assets/data/content_manifest.json).
- [اعتماديات التطبيق](../../pubspec.yaml).
- [lockfile](../../pubspec.lock).
- [إعداد Android](../../android/app/build.gradle.kts).
- [manifest Android](../../android/app/src/main/AndroidManifest.xml).
- [جاهزية الخصوصية](../legal/STORE_PRIVACY_READINESS.md).
- [قائمة تشغيل Android](../release/v1/physical-android-checklist.md).
- [قائمة prayer runtime](../release/v1/prayer-companion-runtime-checklist.md).
- [قائمة backend](../backend/supabase_runtime_readiness_checklist.md).
- [اختبارات host integration](../../test/integration).
- [أدلة التدقيق التاريخي — ليست بديلًا للأدلة الحالية](../../audit_artifacts/production_2026_10_06/README.md).

### حفظ الأدلة

الفحوص الجديدة ومراجعات الوكلاء موثقة في سجل هذه المحادثة. لم تنشأ ملفات logs جديدة مستقلة للفحوص هنا. ملفات audit_artifacts التاريخية لا يجوز نسبتها لهذا التشغيل. لم تثبت مطابقة كاملة لكل ملفات workspace قبل وبعد الفحص بسبب تعذر git status؛ لم ننفذ تغييرًا مقصودًا للمصدر أو baseline أو المحتوى أو الخادم.
