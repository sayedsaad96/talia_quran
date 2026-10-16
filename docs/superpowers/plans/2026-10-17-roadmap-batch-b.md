# خارطة التميّز، الدفعة B (المسار البالغ): خطة التنفيذ

> **للوكلاء المنفذين:** مهارة فرعية مطلوبة: superpowers:subagent-driven-development. الخطوات بصيغة `- [ ]`.

**الهدف:** أربعة بنود من المرحلة 1 في المسار البالغ:

| البند | الاسم |
|---|---|
| 9 | وضع الوضوح |
| 14 | أذكار بعد الصلاة في وقتها |
| 3 | وضع رمضان |
| 11 | النسخة الاحتياطية المحلية |

مسار الأطفال وولي الأمر في الدفعة C.

**البنية:**
- كل بند خلف قيمة موجودة في `ExperienceFeature`: `clarityMode` و`afterPrayerAzkar` و`seasonalRamadan` و`localBackup`، مطفأة افتراضياً.
- المنطق في دوال Dart خالصة. الواجهات تُضاف دون مساس بالسلوك عند إطفاء العلم.

**التقنيات:** Flutter، `flutter_bloc`، `get_it`، Isar (`isar_community 3.3.2`)، SharedPreferences، `hijri`، `share_plus` (موجود)، `file_picker` (جديد، **موافَق عليه من المالك في 2026-10-16**).

**المواصفة:** `docs/superpowers/specs/2026-10-13-talia-differentiation-roadmap.md` (البند 9 في الجزء الأول، والبند 3، والبندان 11 و14 في الجزء الثاني).

## Global Constraints

**المحتوى والبيانات:**
- لا يُعدَّل أي ملف في `assets/data/`، ولا يُكتب أي نص ديني جديد.
- **أذكار بعد الصلاة:** تُعرض من `azkar_release.json` فقط، بالسجلات التي `subcategory == "أذكار بعد الصلاة"` حرفياً. يوجد اليوم 4 سجلات في قائمة `general`. إن لم يوجد أي سجل **لا تظهر البطاقة**.
- لا محتوى رمضاني ديني جديد: لا أدعية ولا أذكار رمضانية.
- لا تغيير في Supabase، ولا في مخطط Isar، ولا في `V2SessionEngine`، ولا في المزامنة، ولا في جدولة الإشعارات وتوصيل الأذان.

**الأعلام والتخزين:**
- **الأعلام:** `ExperienceFlags.isEnabled(...)` مع `getIt.isRegistered<ExperienceFlags>()`، فعدم التسجيل يعني مطفأ.
- **مفاتيح محلية جديدة على مستوى الجهاز:** `clarity_mode_on`، و`after_prayer_azkar_offset_min` (القيمة الافتراضية 10).
- **مفاتيح للحساب:**
  - تُكتب بلاحقة `|<ownerId>` على نمط `_kidsOwnerKey` في `memorization_kids_storage.dart`.
  - **البادئة الجديدة:** `ramadan_` تُضاف إلى `AccountDataReset.clearedPreferencePrefixes`.

**قواعد التنفيذ:**
- قبل `flutter test`، في نفس أمر PowerShell:

```powershell
$env:TEMP='D:\Flutter\talia_quran\.superpowers\tmp'; $env:TMP=$env:TEMP;
```

- لا يعمل أمرا `flutter test` في الوقت نفسه.
- `dart format` للملفات الجديدة فقط.
- `flutter analyze` على المشروع كله يجب أن يطبع "No issues found!"، فالـ infos تُفشل بوابة الإصدار.
- ARB في الملفين، ثم `flutter gen-l10n`، ثم `test/core/l10n`. **الأعداد العربية بصيغ ICU plural** على نمط `countAyahs`.
- لا أيقونات Material، ولا أرقام في `BorderRadius.circular`.
- Commit بمسارات صريحة. الرسالة تنتهي بسطر فارغ ثم `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **وضع الوضوح مع تكبير النظام الكبير أصلاً (1.5):** المقياس يأخذ الأكبر ولا يصغّر. صفحات المصحف (QCF) لا تتأثر. *(Task 1)*
2. **دخول وقت صلاة جديدة والبطاقة السابقة ما زالت ظاهرة:** تظهر بطاقة الصلاة الحالية فقط، ولا تظهر في الوقت المكروه (أي قبل `offset`). *(Task 2)*
3. **الشهر 29 يوماً:** خطة رمضان تنتهي يوم العيد لا بعده. ويوم بداية الشهر يتبع تعديل `hijri_day_offset`. *(Task 3)*
4. **استيراد نسخة من حساب آخر، أو ملف تالف أو أحدث إصداراً:** يُرفض قبل أي كتابة، وبيانات الحساب الحالي سليمة. *(Tasks 7–8)*
5. **مستخدم مسجّل مع المزامنة:** الاستيراد غير متاح له في v1، حتى لا تتعارض البيانات المستوردة مع السحابة. *(Task 9)*

---

### Task 1: وضع الوضوح (البند 9)

**Files:**
- Create: `lib/core/accessibility/clarity_mode.dart`
- Modify: `lib/app.dart` (داخل `builder` حول السطر 197)
- Modify: `lib/core/theme/app_theme.dart` و`talia_tokens.dart` (نسخة عالية التباين)
- Modify: `lib/features/settings/presentation/widgets/settings_hub_body.dart` (مجموعة المظهر حول السطر 79: بلاطة تشغيل وإيقاف)
- Modify: `lib/features/home/presentation/pages/home_page.dart` (إخفاء عناصر التحفيز)
- Modify: ARB
- Test: `test/core/accessibility/clarity_mode_test.dart`، و`test/features/home/presentation/pages/home_clarity_test.dart`

**Interfaces:**

```dart
class ClarityModeController extends ChangeNotifier { // get_it lazy singleton
  ClarityModeController(SharedPreferences prefs, {required bool Function() flagEnabled});
  bool get isOn; // flag && prefs 'clarity_mode_on'
  Future<void> setOn(bool on);
}
const double kClarityTextScale = 1.3;
TextScaler clarityTextScaler(TextScaler system, {required bool on}); // on → max(system(1)/1, 1.3) linear; off → system
```

**التطبيق:**
1. **المقياس:** `MediaQuery(data: mq.copyWith(textScaler: clarityTextScaler(...)), child: ...)`.
   - يُستثنى المصحف: `AppQuranPageView` وصفحات QCF يُعاد لها مقياس النظام بـ`MediaQuery.withNoTextScaling` أو بالمقياس الأصلي، لأن خطوط المصحف ثابتة لكل صفحة.
2. **التباين العالي:** الرموز `textPrimary`/`onSurface` بأعلى تباين، والحدود والنصوص الثانوية أغمق في الفاتح وأفتح في الداكن. **نسبة 4.5:1 على الأقل للنص الثانوي.**
3. **رئيسية مبسطة:** تُخفى `HomeUnifiedProgress` و`HomeAchievementChip` و`HomeActivityFeed`. يبقى الإجراء الأساسي، والمتابعة، والصلاة.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `clarityModeTitle` | «وضع الوضوح» | "Clarity mode" |
| `clarityModeSubtitle` | «خط أكبر، تباين أعلى، ورئيسية أبسط» | "Larger text, higher contrast and a simpler home" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('clarityTextScaler: off → system; on → 1.3 when system 1.0; on → 1.5 when system 1.5', ...);
test('isOn false when flag off even if pref true', ...);
test('high-contrast tokens: secondary text vs surface contrast >= 4.5 in light and dark', ...); // compute WCAG ratio
testWidgets('home hides progress/achievement/activity when clarity on; unchanged when off', ...);
testWidgets('Mushaf page view keeps system text scale under clarity', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN**، ثم `flutter analyze` والحارسان و`test/features/home`.
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(a11y): clarity mode behind experience flag"
```

---

### Task 2: بطاقة أذكار بعد الصلاة (البند 14)

**Files:**
- Create: `lib/features/azkar/domain/services/after_prayer_azkar_window.dart` (خالص)
- Create: `lib/features/home/presentation/widgets/home_after_prayer_azkar_card.dart`
- Modify: `home_page.dart` (البطاقة بعد `_PrimaryAction`)، و`home_cubit.dart`/`home_state.dart` (حالة النافذة)
- Modify: ARB
- Test: `test/features/azkar/domain/after_prayer_azkar_window_test.dart`، و`test/features/home/presentation/widgets/home_after_prayer_azkar_card_test.dart`

**Interfaces:**

```dart
enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }
final class AfterPrayerWindow extends Equatable { final PrayerSlot prayer; final DateTime from; final DateTime until; }
/// The window right after the most recent prayer: [prayerTime + offset, prayerTime + 60 min],
/// clipped so it never overlaps the next prayer time. Null outside every window.
AfterPrayerWindow? activeAfterPrayerWindow({required Map<PrayerSlot, DateTime> todayTimes,
  required DateTime now, int offsetMinutes = 10, int lengthMinutes = 60});
/// Approved records whose subcategory is exactly «أذكار بعد الصلاة» (from the general list), ids only.
Future<List<String>> loadAfterPrayerAzkarIds(AssetBundle bundle);
```

- **التوقيتات:** من `PrayerTimesSnapshot` الذي يحمله `HomeState.prayerSnapshot` (`home_cubit.dart` حول السطر 628). إن لم تكن المواقيت مفعّلة تُعامل كأنه لا نافذة.
- **عند الضغط على البطاقة:** تُفتح صفحة الأذكار العامة على المجموعة الفرعية «أذكار بعد الصلاة»، **باستخدام المسار والصفحة الموجودين** (`general_azkar_page.dart` أو `azkar_category_page.dart`). إن لم يكن هناك وسيلة لفتح مجموعة فرعية مباشرة، يُضاف وسيط اختياري للمسار يمرّر اسم المجموعة الفرعية، والصفحة تمرّر إليها.
- **عدد السجلات صفر:** لا بطاقة.
- **بعد إكمال أذكار هذه الصلاة:** البطاقة تختفي حتى الصلاة التالية. الحالة في مفتاح `after_prayer_azkar_done_<yyyy-mm-dd>_<slot>`، على مستوى الجهاز، ويُمسح القديم منه.
- **v1 بلا إشعار.**

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `afterPrayerAzkarTitle` | «أذكار بعد الصلاة» | "After-prayer adhkar" |
| `afterPrayerAzkarSubtitle` | «بعد صلاة {prayer}» | "After {prayer} prayer" |
| `afterPrayerAzkarOpen` | «ابدأ» | "Start" |
| `afterPrayerAzkarDone` | «تمّت» | "Done" |

اسم الصلاة يُعاد استعماله من مفاتيح المواقيت الموجودة.

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('window opens at prayer+10, closes at +60, clipped before next prayer', ...);
test('before offset → null; between windows → null; after isha until midnight handled; fajr next day', ...);
test('loadAfterPrayerAzkarIds from the real bundled asset returns the 4 approved ids', ...);
testWidgets('card hidden when flag off, no window, or no records; tapping opens the subcategory', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN**، ثم `flutter analyze` و`test/features/home` و`test/features/azkar`.
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(azkar): after-prayer adhkar card behind experience flag"
```

---

### Task 3: تقويم المواسم (خالص)

**Files:**
- Create: `lib/core/seasons/season_calendar.dart`
- Test: `test/core/seasons/season_calendar_test.dart`

**Interfaces:**

```dart
enum RamadanPhase { none, invite, ramadan, lastTen, afterEid }
final class RamadanInfo extends Equatable {
  final RamadanPhase phase; final int? day; final int monthLength; // 29/30 from HijriCalendar
  final DateTime? firstDay; final DateTime? lastDay; // local civil dates of Ramadan
}
/// invite: 7 days before 1 Ramadan; ramadan: days 1-20; lastTen: 21..end; afterEid: Shawwal 1-7.
/// Uses HijriCalendar.fromDate(now + adjustmentDays) like home_occasion_service.dart.
RamadanInfo ramadanInfoAt(DateTime now, {required int adjustmentDays});
```

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('phases across a full year with adjustment 0 and +1', ...); // pick dates via HijriCalendar to construct expectations
test('monthLength 29 vs 30 taken from the calendar; lastDay = firstDay + length - 1', ...);
test('adjustment shifts the phase boundary by the offset', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(seasons): Ramadan calendar phases"
```

---

### Task 4: قوالب ختمة رمضان

**Files:**
- Create: `lib/features/khatmah/domain/entities/khatmah_plan_template.dart`
- Modify: `lib/features/khatmah/presentation/khatmah_setup_prefill.dart` أو صفحة الإعداد لعرض القوالب، فقط في مرحلة `invite` و`ramadan` ومع العلم
- Modify: ARB
- Test: `test/features/khatmah/domain/khatmah_plan_template_test.dart`

**Interfaces:**

```dart
enum RamadanKhatmahTemplate { oneInMonth, twoInMonth, splitByPrayers }
final class KhatmahTemplateParams extends Equatable {
  final int targetDays; final int pagesPerDay; final KhatmahWirdUnit wirdUnit; final int portionsPerDay; // 1 or 5
}
/// days = remaining Ramadan days (lastDay - today + 1, from RamadanInfo); 604 pages.
/// oneInMonth: juz unit, ceil(604/days); twoInMonth: first khatmah over ceil(days/2) days (the second is
/// started by the user after finishing — no automatic chaining in v1); splitByPrayers: as oneInMonth with portionsPerDay 5.
KhatmahTemplateParams paramsFor(RamadanKhatmahTemplate t, RamadanInfo info, DateTime today);
```

- **الإنشاء:** عبر `KhatmahSetupCubit.createPlan(pagesPerDay:, targetDays:, wirdUnit:)` الموجود، **دون تغيير في المحرك**.
- **`splitByPrayers`:** يعرض في واجهة الإعداد فقط الورد اليومي مقسوماً إلى 5 أجزاء متساوية بأرقام صفحات. لا تخزين إضافي.
- **الفصل:** لا شيء هنا يخص متابعة التراويح (Task 5)، التزاماً بفصل الختمة عن القراءة الحرة.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `ramadanTemplateOne` | «ختمة في رمضان» | "One khatmah in Ramadan" |
| `ramadanTemplateTwo` | «ختمتان في رمضان» | "Two khatmahs in Ramadan" |
| `ramadanTemplateSplit` | «ورد مقسّم على الصلوات» | "Daily wird split over the prayers" |
| `ramadanTemplateDays` | «{countText} يومًا متبقية» (plural) | — |
| `ramadanPortion` | «بعد {prayer}: صفحات {from}–{to}» | — |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('30-day month from day 1: oneInMonth pagesPerDay 21 (ceil 604/30), days 30', ...);
test('29-day month: days 29, ends on the last Ramadan day', ...);
test('starting on day 10 of a 30-day month: days 21', ...);
test('twoInMonth: days ceil(n/2)', ...);
test('splitByPrayers portions cover the daily range exactly with no gaps', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(khatmah): Ramadan khatmah templates"
```

---

### Task 5: متابعة التراويح

**Files:**
- Create: `lib/features/seasons/data/tarawih_log_store.dart`
- Create: `lib/features/seasons/presentation/widgets/tarawih_log_sheet.dart`
- Modify: `lib/core/identity/account_data_reset.dart` (البادئة `ramadan_`)، وARB
- Test: `test/features/seasons/data/tarawih_log_store_test.dart`

**Interfaces:**

```dart
final class TarawihEntry extends Equatable { final String nightKey; /* yyyy-mm-dd */ final int fromPage; final int toPage; }
class TarawihLogStore {
  TarawihLogStore(SharedPreferences prefs, RecordOwnerProvider owner);
  // key 'ramadan_tarawih|<ownerId>' JSON list; 1<=fromPage<=toPage<=604; one entry per night (replace)
  Future<List<TarawihEntry>> entries(); Future<void> upsert(TarawihEntry e); Future<void> remove(String nightKey);
  int totalPagesHeard(List<TarawihEntry> entries); // overlapping ranges counted once
}
```

- **الفصل:** متابعة ذاتية فقط. **لا تُحسب في الختمة.**

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `tarawihTitle` | «ما قرأه الإمام الليلة» | "What the imam recited tonight" |
| `tarawihFromPage` | «من صفحة» | "From page" |
| `tarawihToPage` | «إلى صفحة» | "To page" |
| `tarawihTotal` | «سمعتَ {countText} صفحة هذا الشهر» (plural) | — |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('upsert replaces the same night; invalid ranges rejected', ...);
test('totalPagesHeard counts overlapping pages once', ...);
test('owner isolation: owner B sees none of owner A entries', ...);
test('AccountDataReset clears ramadan_ keys', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(seasons): tarawih self-log"
```

---

### Task 6: بطاقات رمضان في الرئيسية

**Files:**
- Create: `lib/features/seasons/presentation/widgets/home_ramadan_card.dart`
- Modify: `home_page.dart` (البطاقة في `HomeContextualSlot` أو بعد `_PrimaryAction`، إن لم يتعارض ذلك مع `home_occasion_service.dart` الموجود)
- Modify: ARB
- Test: `test/features/seasons/presentation/home_ramadan_card_test.dart`

**البطاقة حسب المرحلة:**

| المرحلة | ما تعرضه |
|---|---|
| `invite` | «استعد لرمضان» مع زر يفتح قوالب الختمة. **لا تفعيل دون ضغط المستخدم** |
| `ramadan` | «اليوم {day} من رمضان» مع زرين: الختمة، و«سجّل التراويح» |
| `lastTen` | نفس بطاقة `ramadan` مع سطر «العشر الأواخر» |
| `afterEid` | ملخص: أيام التراويح المسجّلة، ومجموع الصفحات، وإكمال الختمة إن وُجد في السجل خلال رمضان. يمكن إخفاؤه |
| `none` | لا شيء |

- **الإخفاء:** حالة «أخفِ هذه البطاقة» لكل مرحلة في مفتاح `ramadan_card_dismissed_<phase>_<hijriYear>|<owner>`.
- **مصدر التاريخ:** `HijriDateAdjustment` المسجّل في DI.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `ramadanInviteTitle` | «استعد لرمضان» | "Get ready for Ramadan" |
| `ramadanInviteBody` | «اختر خطة ختمتك قبل أن يبدأ الشهر» | "Pick your khatmah plan before the month starts" |
| `ramadanDayTitle` | «اليوم {day} من رمضان» | "Day {day} of Ramadan" |
| `ramadanLastTen` | «العشر الأواخر» | "The last ten nights" |
| `ramadanSummaryTitle` | «حصاد رمضان» | "Your Ramadan" |
| `ramadanSummaryNights` | «سجّلت التراويح في {countText} ليلة» (plural) | — |
| `ramadanLogTarawih` | «سجّل التراويح» | "Log tarawih" |
| `ramadanDismiss` | «إخفاء» | "Hide" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
testWidgets('each phase renders its card; none renders nothing; flag off renders nothing', ...);
testWidgets('dismiss hides the card for that phase and year only', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN**، ثم `test/features/home`.
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(seasons): Ramadan home cards"
```

---

### Task 7: صيغة ملف النسخة الاحتياطية (خالص)

**Files:**
- Create: `lib/core/backup/backup_file_format.dart`
- Test: `test/core/backup/backup_file_format_test.dart`

**Interfaces:**

```dart
const kBackupFormatId = 'talia-backup';
const kBackupSchemaVersion = 1;
final class BackupPayload extends Equatable {
  final int schemaVersion; final DateTime createdAt; final Map<String, Object?> sections; // JSON-safe values only
}
enum BackupDecodeError { notGzip, notJson, wrongFormat, newerVersion, checksumMismatch, malformedSections }
/// gzip(utf8(json({format, schemaVersion, createdAt, sha256, sections}))) where sha256 = hex(sha256(canonical json of sections)).
List<int> encodeBackup(BackupPayload p);
({BackupPayload? payload, BackupDecodeError? error}) decodeBackup(List<int> bytes);
String backupFileName(DateTime now); // 'talia-backup-YYYYMMDD-HHmm.talia'
```

- **sha256:** يُستخدم إن كان `crypto` تبعية مباشرة، وإلا عبر `pubspec`. إذا كان `crypto` تبعية متعدية فقط، يُضاف كتبعية مباشرة بنفس الإصدار المقفل.
- **الترتيب المعياري:** ترميز JSON بمفاتيح مرتبة تكرارياً.

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('round trip preserves sections and createdAt', ...);
test('each BackupDecodeError case', ...); // flip one byte → checksumMismatch; version 2 → newerVersion; etc.
test('canonical json is key-order independent', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(backup): versioned, checksummed backup file format"
```

---

### Task 8: جمع البيانات واستعادتها

**Files:**
- Create: `lib/core/backup/backup_collector.dart`
- Create: `lib/core/backup/backup_restorer.dart`
- Test: `test/core/backup/backup_roundtrip_test.dart` (Isar حقيقي مؤقت على نمط اختبارات Isar الموجودة، مع SharedPreferences وهمية)

**الأقسام في v1:**

| القسم | المصدر | ملاحظات |
|---|---|---|
| `reviewRecords` | `IsarAyahReviewRecord` | للمالك الحالي فقط |
| `ayahProgress` | `IsarAyahProgress` | |
| `streak` | `StreakIsar` | |
| `xp` | `XpIsar` | |
| `dailyActivity` | `DailyActivityIsar` | |
| `prefs` | SharedPreferences | قائمة سماح صريحة، انظر أدناه |

**قائمة سماح المفاتيح:**
- **مفاتيح ثابتة:** `user_profile`، `read_pages`، `quran_bookmarks`، `khatmah_active_plan`، `khatmah_history`، `earned_certificates_v2`، `earned_certificates_v2_kids`.
- **بادئات:** `mem_plus_`، `hifz_`، `daily_read_pages_`، `daily_wird_target_`، `adult_journey_v1_`، `azkar_counter_`، `azkar_smart_wird_`، `kids_reading_receipts_`، `kids_support_profile_`، `kids_family_practice_`، `ramadan_`، `quran_bookmarks_owner_`.

**المستبعد صراحة:**
- مخرجات `outbox` والأدلة وطابور المزامنة وجلسات V2.
- `ActivityEventIsar` وسجلات رفيق الصلاة.
- أي مفتاح فيه `cloud` أو `cursor` أو `dirty` أو `revision` أو `conflict` أو `pin`.
- الأسرار في `secure storage`.
- إعدادات الجهاز: المظهر، واللغة، والإشعارات، والصلاة، والأعلام.

**ربط المالك (owner rebinding):**
- **عند الجمع:** في المفاتيح التي تحتوي `|<ownerId>` أو `_owner_<ownerId>` يُستبدل المعرّف بالرمز `{owner}`، ويُستبعد أي مفتاح يخص مالكاً آخر. حقول المالك في Isar تُكتب `{owner}`.
- **عند الاستعادة:** يُستبدل `{owner}` بالمالك الحالي.

**Interfaces:**

```dart
class BackupCollector { BackupCollector(Isar isar, SharedPreferences prefs, RecordOwnerProvider owner);
  Future<BackupPayload> collect(DateTime now); }
class BackupRestorer { BackupRestorer(Isar isar, SharedPreferences prefs, RecordOwnerProvider owner, AccountDataReset reset);
  /// Validates every section first (types, ranges, surah 1..114, ayah >= 1) and writes nothing on failure.
  /// Then: reset.clearAccountOwnedData() → write Isar in one writeTxn → write prefs.
  Future<BackupRestoreResult> restore(BackupPayload p); }
enum BackupRestoreResult { restored, invalidSections, writeFailed }
```

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
test('collect → encode → decode → restore under ANOTHER owner reproduces records with the new owner', ...);
test('collect excludes other owners keys/records, cloud/cursor/dirty keys and device settings', ...);
test('invalid section (surah 115) → invalidSections and existing data untouched', ...);
test('restore replaces: data present before restore that is not in the backup is gone', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ. Step 4: GREEN.**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(backup): owner-rebinding collect and restore"
```

---

### Task 9: واجهة النسخ الاحتياطي

**Files:**
- Modify: `pubspec.yaml` و`pubspec.lock` (`file_picker` بآخر إصدار مستقر متوافق)
- Create: `lib/features/settings/presentation/pages/backup_page.dart`
- Modify: `app_router.dart` (المسار `backup = '/settings/backup'` مع إعادة توجيه عند إطفاء العلم)، و`about_settings_page.dart` أو مجموعة البيانات في الإعدادات (بلاطة)
- Modify: ARB
- Test: `test/features/settings/presentation/pages/backup_page_test.dart`

**الصفحة:**

1. **«تصدير نسخة احتياطية»:** `collect`، ثم `encode`، ثم كتابة الملف في مجلد مؤقت (`path_provider`)، ثم `Share.shareXFiles`.
2. **«استعادة من ملف»:**
   - **متاح فقط إذا لم يكن المستخدم مسجّلاً بحساب سحابي.** يُستخدم مصدر حالة الدخول الموجود.
   - الخطوات: `FilePicker` (أي نوع، ثم تحقّق بالصيغة)، ثم `decode`. الخطأ يظهر برسالة واضحة لكل `BackupDecodeError`.
   - **حوار تأكيد** يذكر أن البيانات الحالية ستُستبدل.
   - ثم `restore`. **عند النجاح:** `context.go(AppRoutes.splash)` لإعادة تحميل كل شيء.
3. **نص توضيحي:** ما يشمله الملف وما لا يشمله.

**ARB:**

| المفتاح | العربية | الإنجليزية |
|---|---|---|
| `backupTitle` | «النسخة الاحتياطية» | "Backup" |
| `backupExport` | «تصدير نسخة احتياطية» | "Export a backup" |
| `backupImport` | «استعادة من ملف» | "Restore from a file" |
| `backupImportSignedIn` | «الاستعادة متاحة فقط دون حساب. بياناتك محفوظة في حسابك.» | "Restore is only available without an account. Your data is saved in your account." |
| `backupIncludes` | «يشمل: الحفظ والمراجعة، الختمة، القراءة، العلامات، السلاسل، وتقدّم الطفل» | "Includes: memorization and review, khatmah, reading, bookmarks, streaks and the child's progress" |
| `backupExcludes` | «لا يشمل: إعدادات الجهاز والإشعارات وكلمة سر ولي الأمر» | "Excludes: device settings, notifications and the guardian PIN" |
| `backupConfirmTitle` | «استبدال البيانات الحالية؟» | "Replace current data?" |
| `backupConfirmBody` | «ستُحذف بياناتك الحالية على هذا الجهاز وتحل محلها بيانات الملف.» | "Your current data on this device will be replaced by the file's data." |
| `backupConfirm` | «استبدال» | "Replace" |
| `backupErrorInvalid` | «هذا الملف ليس نسخة احتياطية صالحة من تالية.» | "This file is not a valid Talia backup." |
| `backupErrorNewer` | «هذه النسخة من إصدار أحدث من التطبيق. حدّث التطبيق أولاً.» | "This backup is from a newer app version. Update the app first." |
| `backupErrorCorrupt` | «الملف تالف ولا يمكن استعادته.» | "The file is damaged and cannot be restored." |
| `backupDone` | «تمت الاستعادة» | "Restore complete" |

- [ ] **Step 1: الاختبارات الفاشلة**

```dart
testWidgets('signed-in user sees the restore button disabled with the explanation', ...);
testWidgets('decode error maps to its message; nothing restored', ...);
testWidgets('confirm → restore called → navigates to splash', ...);
testWidgets('tile and route hidden when flag off', ...);
```

- [ ] **Step 2: RED. Step 3: التنفيذ.**
- [ ] **Step 4: GREEN.** ثم `flutter pub get` و`flutter analyze`.
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(backup): export and restore screen behind experience flag"
```

---

### Task 10: التحقق الكامل للدفعة

- [ ] `flutter analyze`، ثم `flutter test` كاملاً. **المطلوب: 0 فشل.**
- [ ] تحديث `docs/release/flag-device-test-matrix.md`:
  - صفوف `clarityMode` و`afterPrayerAzkar` و`seasonalRamadan` و`localBackup`.
  - تصحيح صف `trustCenter` والملاحظة على `readerRepeat` (من مراجعة الدفعة A).
- [ ] Commit.
