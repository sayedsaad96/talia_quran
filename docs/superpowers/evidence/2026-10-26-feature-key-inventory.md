# جرد مفاتيح المستخدم + نصوص الفائدة (T0)

**التاريخ:** 2026-10-26
**يخدم:** `2026-10-26-talia-seasons-and-feature-settings-design.md` (T0 قبل T2/T4)

## 1. الهدف

منع تكرار مفتاح واحد في مكانين قبل إضافة صفحتي «المواسم والمناسبات» و«مزايا التطبيق». القاعدة: المفتاح الموجود يبقى في مكانه، وصفحة المزايا تعرض رابطًا إليه بدل مفتاح ثانٍ.

## 2. المفاتيح الموجودة للمستخدم (جُرِدت من الكود)

| الميزة | المفتاح الموجود | مكانه | القرار |
|---|---|---|---|
| clarityMode | `clarity_mode_on` | المظهر في الإعدادات (`settings_clarity_tile.dart`) | لا تظهر في صفحة المزايا (تصميم §6) |
| strengthOverlay (إظهار سريع) | `reader_strength_overlay_on` | قائمة المصحف (`reader_overflow_sheet.dart`) | المفتاح الموجود هو مفتاح الميزة؛ صفحة المزايا تعرض صفًا بلا مفتاح مع «جرّبها» يفتح المصحف حيث يعيش المفتاح |
| forgettingForecast (تذكير أسبوعي) | `notifications_forgetting_forecast` | إعدادات التنبيهات (`settings_notification_tiles.dart`) | مفتاح التذكير يبقى مكانه؛ صفحة المزايا تضيف مفتاح الميزة نفسها (طبقة مختلفة، وليس مفتاحًا ثانٍ للتذكير) |
| prayerReview (أطوال المراجعة) | `prayer_review_lengths\|owner` | إعدادات الصلاة (`prayer_review_settings_slot.dart`) | ضبط أطوال فقط وليس إطفاء؛ صفحة المزايا تضيف مفتاح الإظهار |
| تذكير العشر الأواخر | `notifications_ramadan_last_ten` | بطاقة رمضان (`last_ten_reminder.dart`) | يبقى في بطاقة رمضان؛ صفحة المواسم تعرض مفتاح «تذكيرات المواسم» العام (طبقة أعلى، لا يمس هذا المفتاح) |
| readerRepeat, ayahNotes, audioDownloads, handsFreeReview, afterPrayerAzkar, groupKhatmah, homeWidget | لا يوجد مفتاح مستخدم | — | مفاتيح جديدة في صفحة المزايا |

مفاتيح الطبقة الأخرى (إتاحة المطوّر `experience_flag_*` وLabs) لم تمس؛ صفحة المستخدم لا تكتب فيها أبدًا.

## 3. مخطط التخزين الجديد (بحسب المالك، مثل `RamadanCardDismissStore`)

| العائلة | الصيغة | الافتراضي |
|---|---|---|
| ميزة | `feature_pref_<ExperienceFeature.name>\|<ownerId>` | مفعّل |
| موسم | `season_pref_<SeasonId.name>\|<ownerId>` | مفعّل، عدا `monThu` مطفأ |
| المفتاح الرئيسي للمواسم | `season_pref_master\|<ownerId>` | مفعّل |
| تذكيرات المواسم | `season_pref_reminders\|<ownerId>` | مطفأ |
| مواسم الطفل | `season_pref_kids\|<ownerId>` | مفعّل |

- تدخل في النسخ الاحتياطي عبر بادئتين جديدتين في `BackupPreferencePolicy.prefixes` مع مواصفة `_bool`.
- تُمسح مع الحساب عبر البادئتين نفسيهما في `AccountDataReset.clearedPreferencePrefixes`.
- الإطفاء لا يحذف بيانات الميزة نفسها أبدًا.

## 4. صفوف صفحة «مزايا التطبيق» ونصوص الفائدة (سطر واحد، AR/EN)

تعرض فقط ما إتاحته مفعّلة في الإصدار (`similarAyahTrainer` و`tabletSpread` مطفأتان فلا تظهران).

| المجموعة | الميزة | مفتاح؟ | «جرّبها» يفتح | الفائدة AR | Benefit EN |
|---|---|---|---|---|---|
| القراءة | readerRepeat | نعم | المصحف | تكرار التلاوة تلقائيًا بعدد تختاره أثناء الحفظ | Repeat recitation automatically a number of times you choose |
| القراءة | ayahNotes | نعم | ملاحظات الآيات | اكتب ملاحظتك على أي آية وارجع إليها وقت المراجعة | Note any ayah and find it again when you review |
| القراءة | audioDownloads | نعم | التنزيلات | نزّل التلاوات مرة واحدة واسمعها من غير إنترنت | Download recitations once and listen without internet |
| الحفظ والمراجعة | strengthOverlay | لا (رابط) | المصحف | تلوين الآيات بحسب قوة حفظك، والتحكم من قائمة المصحف | Ayahs colored by memorization strength; controlled in the reader menu |
| الحفظ والمراجعة | forgettingForecast | نعم | التقدم | توقّع ما يقارب النسيان وراجعه قبل أن يفلت | See what you are close to forgetting and review it in time |
| الحفظ والمراجعة | prayerReview | نعم | — (تظهر بعد الصلاة تلقائيًا) | مراجعة قصيرة تلحق بأوقات الصلاة | A short review attached to prayer times |
| الحفظ والمراجعة | handsFreeReview | نعم | المراجعة الصوتية | راجع بصوتك من غير لمس الشاشة | Review out loud without touching the screen |
| الأذكار والصلاة | afterPrayerAzkar | نعم | الأذكار | أذكار بعد الصلاة تظهر لك في وقتها | After-prayer azkar shown at their time |
| مع الآخرين | groupKhatmah | نعم | الختمة الجماعية | ختمة مع أصحابك وتابعون تقدم بعضكم | A khatmah with friends, following each other's progress |
| الشاشة الرئيسية | homeWidget | نعم | — (تُضاف من الشاشة الرئيسية للهاتف) | ملخص صلاتك وتقدمك على شاشة هاتفك الرئيسية | Your prayers and progress on your phone's home screen |

## 5. صفوف صفحة «المواسم والمناسبات»

| الصف | يتحكم في (SeasonId) | الافتراضي |
|---|---|---|
| شعبان: الاستعداد لرمضان | shabanPrep | مفعّل |
| رمضان والعشر الأواخر | ramadan | مفعّل |
| عيد الفطر وصيام الست من شوال | eidFitr, shawwalSix | مفعّل |
| العشر من ذي الحجة وعرفة والأضحى | dhulHijjahTen, eidAdha | مفعّل |
| رأس السنة الهجرية وحصاد العام | hijriNewYear | مفعّل |
| عاشوراء | ashura | مفعّل |
| الجمعة: سورة الكهف | friday | مفعّل |
| الأيام البيض | whiteDays | مفعّل |
| صيام الاثنين والخميس | monThu | مطفأ |
| تذكيرات المواسم (مشترك) | reminders | مطفأ |

كل الأسماء نصوص واجهة في ARB لا تذكر أجرًا أو فضلًا؛ المحتوى الديني المعروض يبقى من `azkar_release.json` فقط (تصميم §8).
