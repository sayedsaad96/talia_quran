# خارطة التميّز، الدفعة C (الطفل وولي الأمر): خطة التنفيذ

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: superpowers:subagent-driven-development. الخطوات بصيغة `- [ ]`.

**الهدف:** ستة بنود من المرحلة 1 في مسار الطفل وولي الأمر:

| البند | الاسم |
|---|---|
| 23 | شهادات الطفل عند ولي الأمر |
| 24 | استماع ما قبل النوم |
| 21 | وعد ولي الأمر |
| 20 | التسميع على ولي الأمر |
| 25 | «ما الجديد» عند ولي الأمر |
| 27 | التقرير الشهري |

**البنية:**
- كل بند خلف قيمة **جديدة تُضاف في آخر** `KidsEnrichmentFeature`، مطفأة افتراضياً. صفحة «المختبر» تعرضها تلقائياً.
- يُعاد استعمال الموجود قدر الإمكان: صفحة الشهادة وطباعتها، ونظام الهدايا `ParentReward`، والتقييم اليدوي في `KidsModeCubit`، ومؤقت النوم في `QuranContinuousPlayerService`، وحسابات الملخص الأسبوعي.

**المواصفة:** `docs/superpowers/specs/2026-10-13-talia-differentiation-roadmap.md` (الجزء الثاني، القسمان ب وج).

## Global Constraints

**المحتوى والبيانات:**
- لا نص ديني جديد. آية الشهادة الموجودة (`certificate_verse.dart`) لا تُمس.
- لا تغيير في Supabase، ولا في مخطط Isar، ولا في `V2SessionEngine`، ولا في جدولة الإشعارات أو الخلفية.
- **الفصل:** تقدّم الطفل منفصل عن تقدّم البالغ. طفل واحد لكل جهاز.

**الأعلام:**
- **القيم الجديدة في آخر `KidsEnrichmentFeature` بهذا الترتيب:** `guardianCertificates`، `bedtimeListening`، `guardianPromise`، `guardianRecitation`، `guardianMilestones`، `monthlyReport`.
- **ممنوع إعادة تسمية أو حذف أي قيمة.**

**القرارات المحسومة:**
- **البند 25 (ما الجديد):** داخل التطبيق فقط في v1، ويظهر عند فتح لوحة الأسرة أو تحديثها. **لا سحب في الخلفية ولا إشعار نظام.** السحب في الخلفية قرار معماري مؤجَّل.
- **البند 21 (الوعد):** للهدايا المحلية فقط في v1. الطفل على نفس الجهاز، والشرط حقل محلي لا يُرسَل للسحابة، والـ mapper السحابي يتجاهله.

**قواعد التنفيذ:**
- قبل `flutter test`، في نفس أمر PowerShell:

```powershell
$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP;
```

- لا يعمل أمرا `flutter test` في الوقت نفسه.
- `dart format` للملفات الجديدة فقط.
- `flutter analyze` على المشروع كله يجب أن يطبع "No issues found!".
- ARB في الملفين، والأعداد بـ ICU plural، ثم `flutter gen-l10n`، ثم `test/core/l10n`.
- لا أيقونات Material، ولا أرقام في `BorderRadius.circular`.
- **كل اختبار جديد يجب أن يُرى فاشلاً مرة** (RED).
- Commit بمسارات صريحة. الرسالة تنتهي بسطر فارغ ثم `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **طفل مرتبط بولي أمر عن بُعد:** الوعد المحلي لا يُرسَل للسحابة، والهدايا البعيدة تعمل كما كانت. *(Task 4)*
2. **التسميع على ولي الأمر دون رمز PIN صحيح:** لا يُسجَّل شيء. وتقييم واحد يُسجَّل مرة واحدة فقط، ولا يدخل في تقدّم البالغ. *(Task 5)*
3. **قائمة ما قبل النوم مع مؤقت ثم فتح قارئ البالغ:** لا تنتقل إعدادات القارئ ولا المؤقت. *(Task 3)*
4. **ما الجديد لطفلين مرتبطين وتبديل حساب ولي الأمر:** «آخر ما رُئي» محصور بالمالك وبالطفل. *(Task 6)*
5. **التقرير الشهري لشهر بلا جلسات:** يعرض «لا جلسات» ولا يتعطل. *(Task 7)*

---

### Task 1: أعلام الدفعة C

**Files:**
- Modify: `lib/core/memorization/kids_enrichment_feature_flags.dart`
- Test: `test/core/memorization/kids_enrichment_feature_flags_test.dart` (إضافة أو إنشاء)

- [ ] تُضاف القيم الست في آخر الـ enum مع تعليق لكل قيمة: «البند N من خارطة التميّز».
- [ ] **اختبار:** المفاتيح الجديدة `kids_enrichment_<name>` مطفأة افتراضياً، وترتيب القيم القديمة لم يتغير. يُثبَّت بقائمة الأسماء الكاملة.
- [ ] `flutter analyze`، ثم اختبار Labs (`test/features/settings/presentation/pages/labs_flags_page_test.dart`)، ثم Commit.

```bash
git commit -m "feat(kids): batch C rollout flags"
```

---

### Task 2: شهادات الطفل عند ولي الأمر (البند 23)

**Files:**
- Create: `lib/features/memorization_plus/presentation/widgets/child_certificates_section.dart`
- Modify: `lib/features/memorization_plus/presentation/pages/child_detail_page.dart` (القسم خلف `guardianCertificates`)
- Modify: ARB
- Test: `test/features/memorization_plus/presentation/widgets/child_certificates_section_test.dart`

**المصدر:**
- **الطفل المحلي:** `AchievementService.getEarnedCertificates(isKids: true)`.
- **الطفل البعيد:** `RemoteChildSummary.activity` أو `production` → `RemoteCertificateAward` (`remote_child_summary.dart:111`)، ويُحوَّل إلى `CertificateAward` للعرض.

**الواجهة:**
- قائمة الشهادات، ولكل شهادة الاسم والتاريخ.
- الضغط يفتح `CertificatePage(award:, userName: <اسم الطفل>)` الموجودة، وفيها المشاركة وPDF والطباعة جاهزة.
- **الشهادة لا تُصدر إلا لإنجاز مسجّل فعلاً.** لا يوجد زر «أصدر شهادة».

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `childCertificatesTitle` | «شهادات طفلك» | "Your child's certificates" |
| `childCertificatesEmpty` | «لا شهادات بعد. تُمنح الشهادة عند إتمام سورة أو جزء.» | "No certificates yet. A certificate is earned by completing a surah or juz." |

- [ ] **الاختبارات الفاشلة:**
  - الطفل المحلي تُعرض شهاداته.
  - الطفل البعيد تُحوَّل `RemoteCertificateAward` وتُعرض.
  - الحالة الفارغة.
  - الضغط يدفع مسار الشهادة بالشهادة الصحيحة.
  - العلم مطفأ: لا قسم.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/features/memorization_plus/presentation`، ثم Commit.

```bash
git commit -m "feat(guardian): child certificates with print/share"
```

---

### Task 3: استماع ما قبل النوم (البند 24)

**Files:**
- Modify: `lib/core/services/quran_continuous_player_service.dart`
- Create: `lib/features/memorization_plus/presentation/pages/kids_bedtime_listen_page.dart` و`.../cubits/kids_bedtime_cubit.dart`
- Modify: `app_router.dart` (المسار `memorizationPlusKidsBedtime = '/memorization-plus/kids-bedtime'` مع `kidsOnlyRedirect` وإعادة توجيه عند إطفاء العلم)، ونقطة دخول في رئيسية الطفل (بطاقة صغيرة تظهر في طور الليل من `kidsWorldPhaseAt`، وزر دائم في قائمة الطفل)
- Modify: ARB
- Test: `test/core/services/quran_continuous_player_bedtime_test.dart`، و`test/features/memorization_plus/presentation/kids_bedtime_test.dart`

**Interfaces:**

```dart
// QuranContinuousPlayerService
/// Plays [surahIds] in order (each whole surah), resetting reader repeat/speed,
/// then applies [sleep] (off/min15/min30/min60/endOfSurah = end of the LAST surah).
Future<void> playSurahQueue(List<int> surahIds, {SleepTimerChoice sleep = SleepTimerChoice.off});
```

- **التنفيذ داخل الخدمة:** بناء `_baseQueue` من آيات كل السور بالترتيب، **دون تكرار ودون تغيير السرعة**. «حتى نهاية السورة» هنا تعني نهاية القائمة، أي نهاية آخر سورة.
- **الصفحة:**
  - قائمة السور المحفوظة من `kidsMemorizedSurahIds` بترتيب مسار الطفل الحالي (`getKidsJourneyPath`)، مع مربع اختيار لكل سورة. الافتراضي: كل السور.
  - مؤقت: 15 أو 30 دقيقة أو إيقاف. الافتراضي 15.
  - زر تشغيل وإيقاف.
  - **لا نقاط ولا مكافآت ولا سجلات.**
  - خلفية ليلية هادئة من لوحة ألوان عالم الطفل.
- **لا سور محفوظة:** رسالة «احفظ سورة أولاً لتستمع إليها قبل النوم».

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `kidsBedtimeTitle` | «استماع قبل النوم» | "Bedtime listening" |
| `kidsBedtimeStart` | «ابدأ» | — |
| `kidsBedtimeStop` | «إيقاف» | — |
| `kidsBedtimeTimer` | «يتوقف بعد» | — |
| `kidsBedtimeEmpty` | «احفظ سورة أولاً لتستمع إليها قبل النوم» | — |
| `kidsBedtimeCard` | «حان وقت الهدوء: استمع لسورك قبل النوم» | — |

- [ ] **الاختبارات الفاشلة:**
  - `playSurahQueue([114,113])` يبني القائمة بآيات 114 ثم 113.
  - لا `setSpeed` ولا تكرار.
  - المؤقت يُطبَّق.
  - `endOfSurah` ينتهي بآخر آية من 113.
  - `playSurah` لاحق للقارئ لا يرث المؤقت.
  - الكيوبت يعرض المحفوظ بترتيب المسار.
  - الحالة الفارغة.
  - البطاقة تظهر ليلاً فقط ومع العلم.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/core/services` و`test/features/memorization_plus`، ثم Commit.

```bash
git commit -m "feat(kids): bedtime listening of memorized surahs"
```

---

### Task 4: وعد ولي الأمر: هدية مرتبطة بإتمام سورة (البند 21)

**Files:**
- Modify: `lib/features/memorization_plus/domain/entities/parent_dashboard.dart` (`ParentReward` يحصل على `int? milestoneSurahId`)
- Modify: نموذج JSON المحلي للهدية (البحث عن `ParentRewardModel`)، والحفظ المحلي (`memorization_kids_local_service.dart` حول السطر 704، `saveParentReward`)
- Modify: `family_dashboard_cubit.dart` (`addReward(title, {childId, int? milestoneSurahId})`، والشرط للطفل المحلي فقط)، وواجهة إضافة الهدية في لوحة الأسرة (اختيار سورة اختياري من سور مسار الطفل)
- Modify: `kids_treasures_cubit.dart` (عند التحميل: كل هدية `locked` بشرط سورة محفوظة تُفتح عبر نفس انتقال الفتح الموجود، دون PIN، لأن الشرط تحقق)، و`kids_gift_card.dart` (شريط تقدّم: الآيات المحفوظة من السورة إلى عدد آياتها)
- Modify: ARB
- Test: `test/features/memorization_plus/...` (نموذج، وكيوبت الكنوز، والبطاقة، ولوحة الأسرة)

**القواعد:**
- `milestoneSurahId` يُحفظ محلياً فقط. `memorization_cloud_mappers.dart` (`rewardFromCloud`) ومسار الحفظ البعيد **لا يتغيران**، وتُضاف إليهما اختبارات تثبت ذلك.
- **الفتح التلقائي:** عبر نفس دالة الانتقال المحلية (`unlockParentReward` أو مكافئها المحلي). يبقى «طلب» الطفل و«موافقة» ولي الأمر كما هما.
- **نص الوعد:** يكتبه ولي الأمر، بحد أقصى 80 حرفاً، ويُطبَّق الحد في الواجهة والنموذج.
- **أمثلة مقترحة عامة غير دينية:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `promiseExample1` | «نزهة في الحديقة» | "A trip to the park" |
| `promiseExample2` | «كتاب جديد» | "A new book" |
| `promiseExample3` | «وجبة يختارها» | "A meal of their choice" |

**ARB إضافية:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `promiseLinkSurah` | «عند إتمام سورة» | "When a surah is completed" |
| `promiseNoCondition` | «بدون شرط» | "No condition" |
| `promiseProgress` | «{done} من {total} آية» | — |
| `promiseUnlockedByMilestone` | «تحقق الوعد!» | — |

- [ ] **الاختبارات الفاشلة:**
  - JSON محلي ذهاباً وإياباً مع `milestoneSurahId`، وقيمة غير صالحة تصبح `null`.
  - المسار البعيد لا يرسل الحقل.
  - كيوبت الكنوز يفتح الهدية المقفلة عند حفظ السورة، ولا يفتحها قبل ذلك، ولا يمس الهدايا البعيدة.
  - البطاقة تعرض التقدّم.
  - لوحة الأسرة: الشرط يظهر للطفل المحلي فقط.
  - حد 80 حرفاً.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/features/memorization_plus`، ثم Commit.

```bash
git commit -m "feat(kids): guardian promise unlocked by completing a surah"
```

---

### Task 5: التسميع على ولي الأمر (البند 20)

**Files:**
- Modify: `kids_gamified_listen_page.dart` (زر «التسميع على ولي الأمر» خلف `guardianRecitation`)، و`kids_mode_cubit.dart` (وضع `guardianAssessed`: يطفئ الميكروفون، وثلاثة أزرار تقييم، ثم الحفظ عبر نفس المسار القائم بـ `manuallyAssessed: true`)
- Modify: ARB
- Test: `test/features/memorization_plus/presentation/cubits/kids_mode_cubit_guardian_test.dart`، واختبار واجهة للصفحة

**التدفق:**
1. الضغط يفتح `ensureGuardianPin(context, allowCreate: <true فقط إذا لم يكن الطفل مرتبطاً بولي أمر بعيد>)`. الفشل أو الإلغاء يعني لا شيء.
2. يدخل الكيوبت وضع `guardianAssessed` للآية الحالية: يستمع الطفل، ثم يتلو أمام ولي الأمر، ثم يضغط ولي الأمر أحد الأزرار التالية:

| الزر | المعنى | الأثر |
|---|---|---|
| «متقن» | `excellent` | يُحفظ |
| «تحتاج مراجعة» | `average` | يُحفظ |
| «لنعد» | لا تقييم | يعيد المحاولة دون حفظ |

3. **الحفظ:** عبر المسار الذي يستدعي `committer.commitPass(..., manuallyAssessed: true)` (`kids_mode_cubit.dart` حول الأسطر 915–940). **دون منطق جديد في المحرك.**
4. **منع التكرار:** الحفظ مرة واحدة لكل آية في الجلسة، بنفس قيود الجلسة الحالية.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `guardianRecitationTitle` | «التسميع على ولي الأمر» | "Recite to your guardian" |
| `guardianRecitationExcellent` | «متقن» | — |
| `guardianRecitationReview` | «تحتاج مراجعة» | — |
| `guardianRecitationRetry` | «لنعد» | — |
| `guardianRecitationHint` | «اطلب من ولي أمرك أن يستمع ويقيّم» | — |

- [ ] **الاختبارات الفاشلة:**
  - PIN خاطئ أو ملغى: لا وضع ولا حفظ.
  - «متقن» يحفظ مرة واحدة بـ `manuallyAssessed: true` و`excellent`.
  - «لنعد» لا يحفظ.
  - الضغط مرتين لا يحفظ مرتين.
  - الميكروفون لا يبدأ في هذا الوضع.
  - السجل سجل طفل وليس بالغاً.
  - العلم مطفأ: لا زر.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/features/memorization_plus`. **يُراجعه Opus.** ثم Commit.

```bash
git commit -m "feat(kids): guardian-assessed recitation"
```

---

### Task 6: «ما الجديد» في لوحة الأسرة (البند 25، v1 داخل التطبيق)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/guardian_milestone_detector.dart` (خالص)
- Create: `lib/features/memorization_plus/data/datasources/guardian_milestone_seen_store.dart`
- Modify: `family_dashboard_cubit.dart` (بعد `refresh`: كشف الجديد لكل طفل)، وواجهة لوحة الأسرة (قسم «ما الجديد» مع زر «تم»)
- Modify: ARB، و`AccountDataReset` (بادئة `guardian_milestones_seen`)
- Test: الكاشف، والمخزن، والكيوبت

**Interfaces:**

```dart
sealed class GuardianMilestone extends Equatable { String get id; } // stable id for dedupe
final class SurahCompletedMilestone ...  // surahId
final class CertificateEarnedMilestone ... // certificate id + title
final class WeekCompletedMilestone ...   // the child met the weekly goal in the last full week
List<GuardianMilestone> detectGuardianMilestones({required List<KidsSessionLog> logs,
  required Map<int,int> ayahCountBySurah, required List<CertificateAward> certificates,
  required int weeklyGoalSessions, required DateTime now});
class GuardianMilestoneSeenStore { // key 'guardian_milestones_seen|<ownerId>|<childKey>' JSON set of ids; owner captured once per write
  Future<Set<String>> seen(String childKey); Future<void> markSeen(String childKey, Iterable<String> ids); }
```

- **العرض:** الجديد = المكتشف ناقص المرئي. أول تحميل لطفل لا مخزن له: يُعلَّم كل الموجود مرئياً **دون عرضه**، حتى لا تظهر فيضانات قديمة.
- **أزرار:** زر «تم» يعلّم مرئياً، والضغط على عنصر يفتح تفاصيل الطفل.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `guardianNewsTitle` | «ما الجديد» | "What's new" |
| `guardianNewsSurah` | «{child} أتمّ سورة {surah}» | — |
| `guardianNewsCertificate` | «{child} حصل على شهادة: {title}» | — |
| `guardianNewsWeek` | «{child} أكمل هدف الأسبوع» | — |
| `guardianNewsDismiss` | «تم» | — |

- [ ] **الاختبارات الفاشلة:**
  - الكاشف: ثلاثة أنواع، معرّفات ثابتة، لا شيء دون بيانات.
  - المخزن: عزل المالك والطفل، والمفتاح يُلتقط مرة واحدة.
  - الكيوبت: أول تحميل يعلّم دون عرض، والجديد بعد ذلك يظهر، و«تم» يخفيه.
  - `AccountDataReset` يمسح البادئة.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/features/memorization_plus` و`test/core/identity`، ثم Commit.

```bash
git commit -m "feat(guardian): what's-new milestones on the family dashboard"
```

---

### Task 7: التقرير الشهري (البند 27)

**Files:**
- Create: `lib/features/memorization_plus/domain/services/kids_monthly_report.dart` (خالص)
- Create: `lib/features/memorization_plus/presentation/widgets/kids_monthly_report_view.dart`
- Create: `.../pages/kids_monthly_report_page.dart`
- Modify: `child_detail_page.dart` (زر «التقرير الشهري» خلف `monthlyReport`)، و`app_router.dart`، وARB
- Test: المجمّع، والصفحة

**Interfaces:**

```dart
final class KidsMonthlyReport extends Equatable {
  final DateTime periodStart, periodEnd; // last 30 local days
  final int sessions, activeDays, newAyahs, reviews, sessionsWithHints;
  final List<int> completedSurahIds; // within the period
  final List<({int surahId, int ayahNumber})> needsSupport; // ayahs with >=2 failures/weak ratings, max 10
  bool get isEmpty;
}
KidsMonthlyReport buildKidsMonthlyReport({required List<KidsSessionLog> logs,
  required Map<int,int> ayahCountBySurah, required DateTime now});
```

- **إعادة الاستعمال:** نفس تعريفات الحقول في `kids_weekly_coaching.dart` (الجلسة، والمراجعة، والتلميح)، دون نسخ المنطق.
- **الصفحة:**
  - عرض التقرير.
  - **ملاحظة ولي الأمر:** نص حر بحد أقصى 200 حرف، **لا يُحفظ**، يُدرج في الصورة فقط.
  - **«حفظ PDF»:** على نمط `CertificatePage._saveAsPdf`: لقطة `Screenshot` للعرض، ثم `pw.Document` بصفحة A4 عمودية، ثم `Printing.layoutPdf`.
  - **«مشاركة صورة»:** على نمط `SharePlus` الموجود.
  - **أسماء السور:** من البيانات الموجودة (`Surah.nameAr`).

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `monthlyReportTitle` | «تقرير الشهر» | "Monthly report" |
| `monthlyReportPeriod` | «من {from} إلى {to}» | — |
| `monthlyReportSessions` | (plural) | — |
| `monthlyReportActiveDays` | (plural) | — |
| `monthlyReportNewAyahs` | (plural) | — |
| `monthlyReportReviews` | (plural) | — |
| `monthlyReportCompleted` | «سور أتمّها» | — |
| `monthlyReportNeedsSupport` | «آيات تحتاج دعماً» | — |
| `monthlyReportNote` | «ملاحظة ولي الأمر» | — |
| `monthlyReportEmpty` | «لا جلسات في هذا الشهر» | — |
| `monthlyReportSavePdf` | «حفظ PDF» | — |
| `monthlyReportShare` | «مشاركة» | — |

- [ ] **الاختبارات الفاشلة:**
  - المجمّع: حدود 30 يوماً، وسور أُتمّت داخل الفترة فقط، و`needsSupport` محدودة بعشرة ومرتبة، والفارغ.
  - الصفحة: الفارغ، والعرض، وحد الملاحظة.
  - المشاركة وPDF عبر دوال قابلة للحقن تُستدعى.
- [ ] RED، ثم التنفيذ، ثم GREEN، ثم `flutter analyze` و`test/features/memorization_plus`، ثم Commit.

```bash
git commit -m "feat(guardian): monthly report with PDF and share"
```

---

### Task 8: التحقق الكامل للدفعة

- [ ] `flutter analyze`، ثم `flutter test` كاملاً. **المطلوب: 0 فشل.**
- [ ] تحديث `docs/release/flag-device-test-matrix.md` بصفوف الأعلام الستة.
- [ ] Commit.
