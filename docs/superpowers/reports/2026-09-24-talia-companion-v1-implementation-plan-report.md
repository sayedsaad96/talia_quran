# تقرير خطة تنفيذ Talia Companion V1 — تحقق جديد من الصفر

**التاريخ:** 2026-09-24
**المصادر المعتمدة فقط:**
- المواصفة المعتمدة: `docs/superpowers/specs/2026-09-19-talia-companion-v1-design.md`
- خطة تدقيق المرحلة صفر: `docs/2026-09-19-talia-companion-v1-phase0-audit.md`

**منهجية هذا التقرير:** كل الحقائق الواردة أدناه جُمعت بفحص مباشر للمستودع الحالي (قراءة ملفات، `grep`، `git`) في جلسة اليوم. **لم يُعتمد على أي تقرير أو خطة أو ملف محفوظ مسبقًا لنفس المهمة**، بناءً على تعليمات صريحة. مواضع عدم التحقق مُعلَّمة صراحة بدل التخمين.

---

## 1. خريطة الطريق التنظيمية (بوابات إلزامية)

```text
القرار 0: حسم شجرة العمل الملوثة + قرار الأصول والمزود
      ↓ بوابة: لا تعديلات غير مُرسلة تخص ميزات أخرى، وقرارات القسم 8 محسومة
المرحلة 1: إتمام تدقيق Phase 0 كاملًا (خطة 6 مهام) → تقرير تدقيق بلا placeholders
      ↓ بوابة: docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md مكتمل
المرحلة 2: كتابة خطتي TDD (Core ثم Voice Pilot) بمسارات حقيقية من التدقيق
      ↓ بوابة: خطتان file-by-file + كل بند من §31 له مالك
المرحلة 3: تنفيذ Core (الصوت مُعطَّل) → المرحلة 4: تنفيذ Voice Pilot
      ↓ بوابة: §28 + اختبارات §27 + قياس أداء فعلي
المرحلة 5: QA تشغيلي + kill switches + إطلاق
```

هذا الترتيب مفروض من المواصفة نفسها (§3، §29، البند 23 من §31): التدقيق الحديث شرط مسبق، والتنفيذ يبدأ بالـ Core كاملًا والصوت مُعطَّل.

---

## 2. لقطة المستودع الحالية (حقائق مضبوطة اليوم)

| البند | الحقيقة المُتحقق منها |
|---|---|
| الفرع/المرجع | `main` @ `8c772d1` |
| Flutter / Dart | Flutter **3.47.1** stable / SDK Dart `^3.11.4` (pubspec) |
| إدارة الحالة | `flutter_bloc` 9.x (Cubit) — مستخدم في كل الميزات |
| التنقل | `go_router` 17.2 — ملف وحيد: `lib/core/router/app_router.dart` |
| Shell التبويبات | `lib/core/widgets/app_shell.dart` يستقبل `StatefulNavigationShell` (حفظ حالة التبويبات عند التبديل — UX-4 fix) ⇒ **خطر حلقات إطارات خفية في التبويبات غير النشطة يجب معالجته صراحة** |
| دورة الحياة | مراقب `WidgetsBindingObserver` واحد في `lib/app.dart` (`_TaliaAppState`) |
| شجرة العمل | ⚠️ **~30 ملفًا معدَّلًا غير مُرسل** لميزة Prayer Delivery V2 (إشعارات، صوت أذان أصلي Android/iOS، إعدادات، l10n) + ملفات غير متتبعة + stash قائم |
| worktrees | يوجد worktree جانبي `.worktrees/talia-core-v1` على فرع `codex/talia-companion-v1-core` يحمل عمل Talia سابقًا — **لا يُعتمد عليه في هذا التقرير** بموجب تعليماتك، ومصيره قرار مستخدم (§8) |
| `lib/features/talia_companion/` | ❌ غير موجود على `main` — لا كود للميزة إطلاقًا |
| الميزات الحالية | auth, azkar, certificate, hifz, home, khatmah, memorization_plus, onboarding, prayer_companion, progress, quran, settings, splash, streak, tutorial_guide, xp + `lib/core` |

---

## 3. نتائج التدقيق المبدئي الجديد (بديل مبسّط لمهام 2–5 من خطة Phase 0)

> هذا القسم **يُسرّع** التدقيق الرسمي ولا يلغيه: خطة Phase 0 تفرض خطوات وتوثيقًا إضافيًا (analyze/test baseline كاملين، جداول مفصلة، فحص placeholders).

### 3.1 خريطة الأسطح والمسارات

| السطح | المسار/الرمز | مالك الملف | سياسة Talia |
|---|---|---|---|
| Adult Home | `/` | `lib/features/home/presentation/pages/home_page.dart` | Hero مؤهل |
| Hero الحالي في Home | — | `lib/features/home/presentation/widgets/home_hero_section.dart` + `home_contextual_slot.dart` (HomeContextualSlot + HomeSlotKind) | نقطة الدمج: يستبدل/يحيط بالـ slot القائم |
| القرآن المركّز | `/quran/surah/:surahId` (QuranReaderPage) | `lib/features/quran/presentation/pages/quran_reader_page.dart` | **hidden دائمًا** |
| قراءة يومية | `/quran/daily` (وجهة إعادة توجيه القراءة) | نفس المالك | **hidden** |
| صفحة المصحف | `quran_page.dart` (مستورد بالراوتر) | `lib/features/quran/presentation/pages/quran_page.dart` | **hidden** |
| قرآن الأطفال | `/memorization-plus/kids-quran` (KidsQuranReaderPage) | `lib/features/quran/presentation/pages/kids_quran_reader_page.dart` | **hidden** |
| رحلة الأطفال | `/memorization-plus/kids-journey`, `kids-home`, `kids-stage`, `kids-completion` | `lib/features/memorization_plus/presentation/pages/kids_gamified_*.dart` | guide/companion |
| تمرين بسيط + تسجيل | `kids_gamified_listen_page.dart` (يستخدم `state.isRecording`, `recordingError`) | نفس الميزة | مرشح Voice Pilot بعد Core |
| حصة الحفظ V2 | `/memorization-v2/session` (`v2_session_page.dart`) | memorization_plus | inline محتمل |
| التقدم | `/progress` | `lib/features/progress/presentation/pages/progress_page.dart` | inline محتمل |

### 3.2 ملاك الحالة الموثوقون (قابلون للقراءة عبر Adapters فقط)

| حاجة Talia | المالك الحالي (مُتحقق) | ملاحظة |
|---|---|---|
| بالغ/طفل | `MemorizationProfile` (`isChild => selectedPath == child`) + `MemorizationPathResolver` (`lib/core/memorization/`) + `ProfileCubit` | مصدر الحقيقة وقت التشغيل |
| هوية الطفل | ⚠️ لا يوجد `profileId` ثابت في `MemorizationProfile` (الموجود: `linkedChildId`, `guardianId`, `childAge`) | **فجوة**: ترحيل هوية مستقرة شرط مسبق للموافقة لكل طفل |
| صوت القرآن | `QuranAudioPlayerCubit` + `quran_continuous_player_service` + `audio_lifecycle_manager` + `quran_background_audio_handler` (audio_service) | إشارة كبت جاهزة |
| التسجيل/التقييم | `memorization_session_cubit` + `kids_mode_cubit` (`isRecording`, `recordingError`) + `recitation_evaluator` | إشارة كبت + خط تدقيق تقني |
| تعرّف صوتي على الجهاز | `speech_to_text` 7.4 مستخدم فعلًا في `kids_mode_cubit` و `memorization_session_cubit` | قابل لإعادة الاستخدام كمحوّل recognizer |
| مراجعة مستحقة/خطة يومية | `daily_plan.dart`, `ayah_review_record.dart` + `smart_coach_engine.dart` و `smart_coach_recommendation.dart` (`lib/core/memorization/`) | **SmartCoach موجود فعلاً** — Talia يحكم بين مرشحيه ولا يعيد حسابه |
| استئناف/متابعة | `home_continue_card.dart` + `learning_launch_context.dart` + جلسات الختمة | مرشح Hero |
| الصلاة | ميزة `prayer_companion` + `NotificationScheduler` (`scheduleDailyReviewReminder`…) | سياق + إشعارات |
| الورد اليومي | `get_daily_wird_usecase.dart` + `home_ayah_of_day.dart` + `assets/data/daily_ayahs.json` | يقابل "Daily Question" في التصميم |
| Share Good | `lib/core/widgets/social_share/` | يُحترم تسلسله الاحتفالي |
| أعلام الميزات | نمط أصناف static: `JourneyFeatureFlags`, `CloudSyncFeatureFlags`, `KidsHifzFeatureFlags` | علمتا Talia يتبعان نفس النمط (لا remote config بالمستودع) |
| الإشعارات | `NotificationScheduler` + `NotificationService` (flutter_local_notifications 22 + timezone) | نقطة امتداد النسخ الواعية بـ Talia |
| l10n | `lib/core/l10n/app_ar.arb` + `app_en.arb` + توليد `flutter: generate: true` | كتالوج الرسائل هنا |
| حوكمة دينية | `test/core/content/no_ungoverned_religious_output_test.dart` + `approved_azkar_content_test.dart` | كتالوج Talia يُسجَّل هنا ويُختبر |
| تصفير الحساب | `lib/core/identity/account_data_reset.dart` | يجب تسجيل مفاتيح Talia عند التصفير |

### 3.3 الأصول (اكتشاف مهم)

`assets/images/character/` يحتوي فعلًا: `Talia_Master_Character.png`, `talia_hero.png`, و**9 وضعيات أحادية**: `talia_idle, talia_happy, talia_encourage, talia_reading_quran, talia_speaking, talia_thinking, talia_listening, talia_wave, talia_celebrate, talia_point_right`.

**الفجوة مقابل §11 من المواصفة:**
- وضعيات ناقصة: `guide`, `resting`, `attention`, `retry`, `success`.
- تسلسلات PNG متعددة الإطارات (wave/listening/celebrate) **غير موجودة** — الموجود إطارات أحادية.
- مجلد `assets/talia/` غير موجود على `main`، وملفات الردود الصوتية `assets/talia/voice/ar/` غير موجودة.

⇒ **قرار إنتاج أصول خارجي** (§8) قبل مهام المُصيِّر المتقدمة، أو إطلاق Core بالوضعيات الموجودة + micro-motion فقط (خيار يعرضه التقرير).

### 3.4 فجوات بنية تحتية مؤكدة (غياب صريح لا تخمين)

1. **لا بنية موافقات إطلاقًا** (`grep consent` = صفر نتائج في `lib`) ⇒ مستودع موافقة جديدة تحت `talia_companion`.
2. **لا بنية تحليلات/قياس عامة** (`logEvent/analytics/telemetry` = لا شيء حقيقي) ⇒ الـ Telemetry الآمن (§23) يحتاج sink جديدًا صغيرًا بقائمة أحداث مسموحة.
3. **لا مزود تعرّف صوتي سحابي** ⇒ صف الـ fallback السحابي **BLOCKED**؛ وV1 قابل للإطلاق كليًا على الجهاز (المواصفة تسمح بذلك).
4. `permission_handler` 12 موجود — تدفق إذن المايك Just-in-Time يُبنى فوقه.

---

## 4. الفجوة الكلية: التصميم مقابل الواقع

| مجال التصميم | الحالة | التفسير |
|---|---|---|
| النماذج + السياسات + Coordinator | ❌ غير موجود | بناء جديد بالكامل داخل `lib/features/talia_companion/` |
| Adapters للملاك | ⚠️ الملاك موجودون، الـ Adapters لا | طبقة قراءة ضيقة جديدة فقط — لا ازدواجية منطق |
| مُصيِّر الشخصية + الحركة | ⚠️ أصول جزئية (9 وضعيات أحادية)، لا مُصيِّر | micro-motion ممكن فورًا؛ التسلسلات تحتاج أصولًا |
| Home Hero / Strip / Kids Guide | ❌ نقاط الدمج موجودة فقط | تعديلات موضعية على 6–8 ملفات موجودة |
| الحضور التكيفي + الثبات | ❌ | جديد، owner-scoped عبر `AccountDataReset` |
| كتالوج الرسائل + الحوكمة | ⚠️ ل10n جاهز، الكتالوج لا | مفاتيح ARB جديدة + دمج اختبار الحوكمة |
| الإشعارات الواعية | ⚠️ | امتداد `NotificationScheduler` مع الميزانيات والساعات الهادئة |
| Voice Pilot | ⚠️ حزمة speech_to_text جاهزة؛ الباقي جديد | ترحيل `profileId` أولاً، ثم موافقة، ثم Push-to-Talk |
| Telemetry آمن | ❌ | sink جديد بقائمة مسموحة؛ ممنوع rawAudio/transcript/اسم الطفل |

---

## 5. خطة التنفيذ التفصيلية

### المرحلة 0 — حسم القرارات وإتمام التدقيق (بدون كود ميزة)

1. **تنفيذ خطة Phase 0 حرفيًا** (المهام 1–6): تثبيت `flutter analyze` / `flutter test` baseline، إكمال ما بدأه هذا التقرير (فحص reduced-motion، أوامر التوليد، جداول المهام 6)، وإنتاج `docs/superpowers/audits/2026-09-19-talia-companion-v1-phase0-audit.md` خاليًا من أي placeholder.
2. تُسجَّل نتائج هذا التقرير كمدخل جاهز للمهام 2–5، وتُكتشف أي فروقات أثناء التوثيق الرسمي.

### القرار 0 — بوابة قرارات المستخدم (تفصيلها في §8)

فصل عمل Prayer Delivery غير المُرسل، مصير worktree `talia-core-v1`، الأصول، المزود السحابي، سياسة الالتزامات.

### المرحلة 1 — خطتا TDD (بدون كود)

كتابة `docs/superpowers/plans/2026-09-19-talia-companion-v1-core.md` ثم `...-kids-voice-pilot-v1.md`، كل مسار فيهما مستمد من تقرير التدقيق المكتمل لا من هذا التقرير.

### المرحلة 2 — تنفيذ Core (الصوت مُعطَّل)

| # | الحزمة | معيار القبول |
|---|---|---|
| 1 | نماذج دلالية (`CompanionDecision`, Surface, Presence, Pose, InteractionMode) + علمتا static بأسلوب الميزات القائمة | اختبارات وحدة: القرار المخفي بلا محتوى/CTA، الصوت مُعطَّل افتراضيًا |
| 2 | سياسات نقية: كبت P0–P3 + أولوية P4–P10 | فوز تركيز القرآن دائمًا؛ الكبت يسبق التفاعل |
| 3 | Context snapshot + Adapters ضيقة (ملف شخصية، صوت، تسجيل، مراجعة/SmartCoach، ورد، صلاة) | قراءة فقط؛ صفر منطق محسوب جديد |
| 4 | Coordinator (Cubit) + إسقاط الرؤية (دورة حياة + تبويب غير نشط) | إلغاء العمل المتقادم؛ **صفر tickers في فروع IndexedStack غير النشطة** |
| 5 | مُصيِّر الشخصية: micro-motion لكل وضعية + بديل reduced-motion + توقف فوري عند الكبت | كل حالة = وضعية + حركة + fallback |
| 6 | Adult Home Hero: رسالة واحدة + CTA واحد | widget test إلزامي |
| 7 | Compact Assist Strip في `/memorization` و `/progress` | مضغوط، ليس Hero ثانيًا |
| 8 | Kids Journey Guide في الخريطة/البداية/التعليمات | hidden في كل مسارات القرآن |
| 9 | الثبات + الحضور التكيفي + تسجيل مفاتيح Talia في `AccountDataReset` | ترقية deterministic؛ اليدوي يغلب؛ عزل المالكين |
| 10 | كتالوج ARB + دمج `no_ungoverned_religious_output_test` + cooldowns/تدوير | اجتياز الحوكمة |
| 11 | إشعارات عبر `NotificationScheduler` + علم قتل `TALIA_COMPANION_ENABLED` | تعطيل نظيف كامل |

### المرحلة 3 — تنفيذ Voice Pilot (فوق Core العامل)

| # | الحزمة | ملاحظة |
|---|---|---|
| 1 | **ترحيل `profileId` مستقر في `MemorizationProfile`** + اختبارات عزل/تصفير | شرط مسبق صارم |
| 2 | موافقة مُرقَّمة لكل طفل (owner + child + consentVersion + acceptedAt) | الطفل A ≠ الطفل B |
| 3 | موافقة قبل إذن المايك (Just-in-Time) فوق `permission_handler` | لا إذن في الـ onboarding |
| 4 | متحكم Push-to-Talk + محوّل `speech_to_text` + مُصنِّف عربي مغلق (6 نوايا، `unknown` لا تخمين) | MSA + مصري بسيط، بنية قابلة لإضافة لغة |
| 5 | حارس نتائج متقادمة (requestId/child/surface/stage) + إلغاء شامل | لا `next/back` على شاشة تغيرت |
| 6 | تحكيم صوتي: قرآن/تسجيل > إدخال صوتي > رد Talia | إلغاء فوري للأدنى أولوية |
| 7 | رد ×1 ثم أزرار مرئية؛ الفشل التقني = حالة محايدة | مصفوفة §25 |
| 8 | telemetry مسموحة فقط + علم `TALIA_KIDS_VOICE_PILOT_ENABLED` مستقل | ممنوع rawAudio/fullTranscript/childName |
| 9 | fallback سحابي | **BLOCKED** حتى قرار المزود (اختياري تمامًا لـ V1) |

### المرحلة 4 — QA تشغيلي (§27) وأداء

- أجهزة/محاكيات Android فعلية: انتقالات، IndexedStack/offstage، كبت الصوت/التسجيل، تبديل الملفات، الخلفية/الاستئناف، إذن المايك رفض/قبول، offline.
- قياس: jank أثناء الحركة، نمو الذاكرة، فك ترميز الصور قرب حجم العرض، أداء تمرير Home، فئات زمن الاستجابة الصوتية.
- لا إقرار أداء بفحص الكود — قياس فعلي فقط.

### استراتيجية الاختبارات (مربوطة بالقائم)

- **وحدة:** السياسات النقية، التدوير/cooldowns، المُصنِّف، حارس التقادم، عزل الموافقات.
- **Widget:** رسالة/CTA واحد، غياب Talia في القارئ، غياب المايك خارج الأسطح المدعومة، reduced-motion، الأزرار بعد فشلين.
- **دمج مع القائم:** `test/core/content/no_ungoverned_religious_output_test.dart` يوسَّع ليشمل كتالوج Talia.

---

## 6. المخاطر الرئيسية

| الخطر | المعالجة |
|---|---|
| شجرة عمل Prayer Delivery غير مُرسلة تلوث الـ baseline والـ commits | القرار 0: فصلها أولًا (موصى به) |
| worktree `codex/talia-companion-v1-core` يحمل عملًا سابقًا | قرار صريح: اعتماد كمرجع/دمج أو تجاهل كلي — لا خلط |
| فروع IndexedStack تبقي التبويبات حية | إسقاط رؤية يوقف tickers/تسلسلات في الفروع غير النشطة (اختبار إلزامي) |
| تسلسلات PNG غير موجودة | إما إنتاج أصول (قرار) أو Core micro-motion فقط بالأصول القائمة |
| ازدواجية منطق SmartCoach/المراجعة | قاعدة صارمة: Talia يحكم بين مرشحين جاهزين ولا يحسب |
| غياب التحليلات | sink telemetry مخصص مصغّر بقائمة مسموحة — لا توسيع لاحقًا دون مراجعة |
| سرية الأطفال | `profileId` قبل أي موافقة؛ عزل وتصفير مُختبران |

---

## 7. خريطة البنود غير القابلة للتفاوض (§31) إلى أصحاب الضمان

| البند | الضامن |
|---|---|
| 1–3 ميزة/قرار مركزي/لا overlay | معمارية Core + اختبارات Coordinator/widget |
| 4 تركيز القرآن | جدول §3.1 + اختبار widget للقارئ |
| 5–7 حالات الشخصية والحركة | مُصيِّر §5-المرحلة2/5 + fallback |
| 8–9 نبرة البالغين/الأطفال | كتالوج ARB بنبرتين |
| 10–16 V2 مؤجلة/نوايا مغلقة/جهاز أولاً/لا TTS/لا تخزين/موافقة/لا تخمين | المرحلة 3 كاملة |
| 17–18 فشل تقني محايد/قناة احتفال واحدة | مصفوفة §25 + arbiter احتفالي |
| 19–20 حوكمة دينية/اليدوي يغلب | اختبار الحوكمة الموسع + سياسة الحضور |
| 21 توقف offstage | إسقاط الرؤية + اختبار تشغيلي |
| 22–23 لا ازدواجية/تدقيق إلزامي | Adapters فقط + المرحلة 0 |

---

## 8. قرارات مطلوبة من المستخدم (بوابة القرار 0)

1. **شجرة العمل غير المُرسلة (Prayer Delivery V2):** فصلها في commits/فرع أولًا (موصى به) أم اعتمادها baseline مشوشًا موثقًا؟
2. **مصير worktree `talia-core-v1` / فرع `codex/talia-companion-v1-core`:** يُبنى من جديد نظيفًا على `main` (موصى به انطلاقًا من تعليماتك)، أم يُدقق العمل السابق ويُعتمد ما يصمد؟
3. **الأصول:** إنتاج 5 وضعيات ناقصة + تسلسلات wave/listening/celebrate + مقاطع صوتية عربية معتمدة — أم إطلاق Core بالوضعيات التسع القائمة + micro-motion فقط؟
4. **المزود السحابي للتعرّف:** تأجيل الـ fallback كليًا لـ V1 (موصى به — أقل مخاطرة خصوصية) أم اختيار مزود مع التحقق الفعلي من سياسة الاحتفاظ؟
5. **عتبات الحضور التكيفي:** تثبيت قيم §9 (3 تفاعلات/جلستين) أم ضبط لاحق؟
6. **سياسة commits للتوثيق المرحلي** أثناء Phase 0.

---

## 9. الخلاصة

التصميم ناضج وشامل، وخطة التدقيق جاهزة، والمستودع يحمل **أكثر مما يُفترض عادة**: ملاك حالة كاملون (SmartCoach موجود)، 9 وضعيات شخصية جاهزة، حزمة تعرّف صوتي مستخدمة فعلًا، واختبار حوكمة دينية قائم. الفجوة الحقيقية في أربعة مواضع فقط: **كود talia_companion ذاته، هوية الطفل المستقرة والموافقات، بنية القياس الآمن، والأصول المتحركة**. أقصر طريق آمن: حسم القرارات الستة، ثم إتمام Phase 0 رسميًا، ثم خطتا TDD، ثم Core بلا صوت، ثم Voice Pilot — بلا أي قفز فوق بوابة.
