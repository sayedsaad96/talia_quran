# Quran Khatmah Plan, Reader Context Isolation, and Khatm Du'a Design

Date: 2026-09-02  
Status: Approved Design (Awaiting Implementation Plan)  

---

## 1. Context & Problem Statement

Talia is an offline-first Quran companion. While memorization (`features/memorization_plus`) has structured learning paths, users who select **Quran Reading** (`OnboardingGoal.reading`) currently lack a dedicated, structured completion journey:
1. **No Khatmah Journey:** Daily reading was previously simulated by selecting a pseudo-random page daily, rather than supporting a structured, sequential Khatmah (1 to 604 pages).
2. **Lack of Session Isolation:** Previously, reading any Surah (e.g. Surah Al-Kahf on Friday) would record pages into general storage (`read_pages`), risking unintended shifts in the user's reading position.
3. **No Dedication Support:** Users often intend their Quran completion as a dedicated gift/supplication for parents, loved ones, deceased relatives, or sick family members.
4. **No Completion Milestone & Du'a:** There is no authentic, verified Du'a Khatm al-Quran presented upon finishing page 604, nor an archived history of past Khatmahs.

---

## 2. Core Architectural Principle: Complete Context Isolation

A core requirement is the **absolute separation of concerns** between three distinct reading behaviors:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Talia Reading Contexts                          │
├──────────────────────┬────────────────────────┬────────────────────────┤
│ 1. Free Quran Reading│ 2. General Daily Wird  │ 3. Khatmah Track       │
│    (القراءة الحرة)    │    (الورد اليومي العام) │    (مسار الختمة)       │
├──────────────────────┼────────────────────────┼────────────────────────┤
│ • Browsing any Surah │ • Independent daily    │ • Dedicated plan (1..  │
│ • Surah Al-Kahf, etc.│   habit                │   604 pages)           │
│ • Updates last       │ • Does not disrupt or  │ • Explicit session mode│
│   general location   │   advance Khatmah      │ • Only Khatmah mode    │
│ • NEVER affects      │ • Independent tracking │   advances progress    │
│   Khatmah progress   │                        │ • Isolated persistence │
└──────────────────────┴────────────────────────┴────────────────────────┘
```

---

## 3. Data Models & Entities (`features/khatmah/domain/entities`)

### 3.1 `KhatmahDedication`
Captures the intention and dedication of the Khatmah:
- `isDedicated` (`bool`): Whether the Khatmah is dedicated to someone else.
- `recipientName` (`String?`): Name of the individual (e.g., "الوالد الحبيب أحمد").
- `relationship` (`String?`): Relationship (والد، والدة، صديق، أخت، زوجة، إلخ).
- `condition` (`DedicationCondition`): `alive` (حي), `deceased` (متوفى/رحمه الله), `sick` (مريض/طلب الشفاء).
- `customNote` (`String?`): Optional personal intention note.

### 3.2 `KhatmahPlan`
Represents the active Khatmah state and schedule:
- `id` (`String`): Unique identifier (UUID).
- `title` (`String`): Descriptive name (e.g., "ختمة القرآن الكريم", "ختمة الوالدة").
- `startPage` (`int`): Default 1.
- `currentPage` (`int`): Last completed page in this Khatmah (1..604).
- `targetPagesPerDay` (`int`): Daily page quota (e.g., 2, 4, 10, 20).
- `targetDays` (`int`): Target duration in days.
- `startDate` (`DateTime`): Timestamp when plan was created/started.
- `expectedEndDate` (`DateTime`): Target completion date.
- `status` (`KhatmahStatus`): `active`, `paused`, `completed`.
- `dedication` (`KhatmahDedication`): Dedication details.
- `lastReadDate` (`DateTime?`): Date of the most recent reading session.
- `completedPagesCount` (`int`): Total pages finished in this Khatmah.

### 3.3 `KhatmahHistoryEntry`
Archival entry for completed Khatmahs:
- `id` (`String`): Entry ID.
- `khatmahNumber` (`int`): Ordinal Khatmah number (الختمة الأولى، الختمة الثانية...).
- `title` (`String`): Title of the completed Khatmah.
- `startDate` (`DateTime`): Start date.
- `completedDate` (`DateTime`): Finish date.
- `totalDays` (`int`): Days taken.
- `dedication` (`KhatmahDedication?`): Dedication metadata.
- `certificateId` (`String?`): Generated milestone certificate ID.

---

## 4. Calculation & Adaptive Scheduling Engine

### 4.1 Dual-Directional Plan Setup
1. **By Pages Per Day:**
   - Quick presets: 2 pages (~302 days), 4 pages (~151 days), 10 pages (~60 days), 20 pages / 1 Juz (~30 days), or custom input.
   - Days Remaining = ceil((604 - currentPage + 1) / pagesPerDay).
   - Expected End Date = today + Days Remaining.
2. **By Target Duration or Date:**
   - Presets: 30 days, 60 days, 90 days, 180 days, 365 days, or specific calendar date.
   - Daily Pages = ceil((604 - currentPage + 1) / targetDays).

### 4.2 Today's Wird Computation
- wirdStartPage = currentPage + 1.
- wirdEndPage = min(wirdStartPage + targetPagesPerDay - 1, 604).
- Range displayed: "ورد الختمة اليوم: من صـ {wirdStartPage} إلى صـ {wirdEndPage}".

### 4.3 Gentle Adaptive Catch-Up (Non-Judgmental)
When days are missed, no red alerts or negative feedback are presented. The UI provides two one-tap remedies:
1. **تمديد هادئ (Calm Adjustment):** Keep the same comfortable daily pages, smoothly extending the expected completion date.
2. **تعويض مرن (Mild Compensation):** Add 1 or 2 extra pages per day until back on original schedule.

### 4.4 Physical Mushaf Manual Logging
A simple interface in the Khatmah dashboard allowing users who read from a physical paper Mushaf to log the page reached in one tap.

---

## 5. Reader Mode & Context Isolation

### 5.1 Route Parameterization
- **Free Reading Route:** `/quran/page/:id` (opens in default free mode, `mode=free`).
- **Khatmah Reading Route:** `/quran/reader?page=X&mode=khatmah&khatmahId=Y`.

### 5.2 Visual Reader Experience (`mode=khatmah`)
- A non-intrusive, serene header pill:
  - "جلسة الختمة [مهداة لـ: ...] — صفحة {current} ({index} من {dailyTarget} من ورد اليوم)"
- Quick action: "حفظ والإنهاء لاحقاً" (Save and exit session).

### 5.3 Confirmation & Progress Hook
- Pages confirmed via `QuranReadConfirmationGate` in `mode=khatmah` advance `currentPage` of the active `KhatmahPlan`.
- Free reading confirmations do NOT modify `KhatmahPlan`.
- Upon reaching `wirdEndPage`, an encouraging toast/dialog appears: "تقبل الله! أتممت ورد الختمة لليوم".

---

## 6. Completion Flow & Du'a Khatm al-Quran

### 6.1 Reaching Page 604
Confirming page 604 in Khatmah mode triggers the celebratory completion sequence:
1. **Celebratory Screen (`KhatmahCompletionPage`):**
   - Islamic geometry decoration, warm gold accents, Amiri calligraphy.
   - "مبارك إتمام ختم كتاب الله تعالى".
   - Summary: start date, completion date, days taken.
   - Prominent dedication section: "إهداء ثواب الختمة المباركة إلى: [الاسم] ([صلة القرابة])".
2. **Authentic Du'a Khatm al-Quran:**
   - Verbatim text from the King Fahd Complex Mushaf edition ("اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ وَاجْعَلْهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً...").
   - Dynamic dedication supplication paragraph inserted smoothly based on condition (deceased: رحمة ومغفرة; sick: شفاء وعافية; alive: بر وطول عمر وصلاح).
   - Typography controls: font size scaler, full diacritics, copy/share passages.
3. **Archiving & Next Steps:**
   - Archiving entry into `KhatmahHistory`.
   - Milestone certificate / share card generation via `SocialShareSheet`.
   - CTA: "ابدأ ختمة جديدة بحول الله".

### 6.2 Permanent Access to Du'a
- A permanent route `/quran/khatm-dua` accessible from the Quran index and drawer so users can recite Du'a Khatm al-Quran at any time.

---

## 7. Directory Structure & Architecture

```
lib/features/khatmah/
├── data/
│   ├── datasources/
│   │   ├── khatmah_local_datasource.dart
│   │   └── khatm_dua_datasource.dart
│   ├── models/
│   │   ├── khatmah_plan_model.dart
│   │   ├── khatmah_dedication_model.dart
│   │   └── khatmah_history_model.dart
│   └── repositories/
│       └── khatmah_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── khatmah_plan.dart
│   │   ├── khatmah_dedication.dart
│   │   └── khatmah_history_entry.dart
│   ├── repositories/
│   │   └── khatmah_repository.dart
│   └── usecases/
│       ├── get_active_khatmah_usecase.dart
│       ├── create_khatmah_usecase.dart
│       ├── update_khatmah_progress_usecase.dart
│       ├── complete_khatmah_usecase.dart
│       └── get_khatm_dua_usecase.dart
└── presentation/
    ├── cubits/
    │   ├── khatmah_cubit.dart
    │   ├── khatmah_setup_cubit.dart
    │   └── khatm_dua_cubit.dart
    ├── pages/
    │   ├── khatmah_setup_page.dart
    │   ├── khatmah_dashboard_page.dart
    │   ├── khatmah_completion_page.dart
    │   └── khatm_dua_page.dart
    └── widgets/
        ├── khatmah_hero_card.dart
        ├── khatmah_progress_gauge.dart
        ├── khatmah_dedication_form.dart
        └── khatmah_reader_session_bar.dart
```

---

## 8. Verification Strategy

1. **Unit Tests:**
   - Calculation engine tests (page counts, remaining days, date projections, leap years).
   - Entity serialization and storage isolation tests.
   - Dedication supplication formatter tests.
2. **Widget Tests:**
   - Setup wizard interaction (pages/day selection, dedication toggle).
   - Khatmah session header rendering and page advancement.
   - Du'a screen rendering, font scale changes, and copy actions.
3. **Integration & Hot Reload Verification:**
   - Connect via `dtd` tool to verify live app state.
   - Execute `hot_reload` after edits as per repository instructions.
