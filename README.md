<div align="center">
  <img src="assets/images/logo.png" alt="Talia Logo" width="120">

  # تالية — Talia Quran

  **A Premium, Intelligent Quran Memorization & Recitation App**

  [![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
  [![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-success?style=flat-square)](#-architecture)
  [![BLoC](https://img.shields.io/badge/State_Management-BLoC-blue?style=flat-square)](#-tech-stack)

  [English](#english) • [العربية](#العربية)
</div>

---

<h2 id="english">📖 Overview</h2>

**Talia (تالية)** is a feature-rich, beautifully designed Flutter application dedicated to the Holy Quran. It provides an immersive reading experience, advanced memorization (Hifz) tools powered by spaced repetition, and intelligent recitation testing using speech recognition.

Built with **Clean Architecture** and **Domain-Driven Design**, Talia ensures a scalable, maintainable, and highly performant codebase.

---

## ✨ Features

### 📖 Quran Reader
- **Complete 114 Surahs:** Accurate texts with Ayah counts, Juz, and revelation type.
- **Immersive Experience:** Focus mode, adjustable font sizes (16–36px), and authentic `Amiri` typography.
- **Audio Recitation:** High-quality Ayah-by-Ayah audio playback via `just_audio`.
- **Quick Navigation:** Grid-based Juz selection, Surah list, and full-text search.
- **Bookmarks & Copy:** Persistent bookmarks and clipboard support.

### 🧠 Intelligent Hifz (Memorization)
- **Spaced Repetition System (SRS):** Smart intervals `[1, 3, 7, 14, 30, 90]` days for effective retention.
- **Voice Recognition Testing:** Utilizes `speech_to_text` and `string_similarity` to listen to your recitation and automatically verify correctness.
- **Self-Testing Mode:** Reveal/hide Ayahs for traditional memorization practice.
- **Progress Tracking:** Detailed statistics per Surah.

### 🌿 Azkar (Supplications)
- **Daily Categories:** Morning, Evening, and General Dhikr.
- **Interactive Counters:** Haptic-feedback counters with animated progress rings.
- **Smart Tracking:** Remembers your progress throughout the day.

### 📊 Progress & Gamification
- **Visual Statistics:** Animated circular indicators (`percent_indicator`) showing overall Quran progress.
- **Streaks & Habits:** Auto-calculated daily streaks to build a consistent habit.
- **Achievements:** 6 unlockable badges for reaching milestones.

### ⚙️ Personalization & Accessibility
- **Themes:** Light, Dark, and System modes with a premium color palette (Deep Teal-Green & Warm Gold).
- **Localization:** Seamless RTL/LTR support (Arabic & English) without app restarts.
- **Notifications:** Local reminders using `flutter_local_notifications`.

---

## 🛠 Tech Stack & Libraries

Talia leverages modern Flutter packages to deliver a robust experience:

| Category | Technology / Package |
|----------|----------------------|
| **Core Framework** | Flutter, Dart |
| **State Management** | `flutter_bloc` (Cubits for UI state) |
| **Architecture** | Clean Architecture, `get_it` (Dependency Injection), `dartz` (Functional Error Handling) |
| **Routing** | `go_router` (Declarative routing with ShellRoute) |
| **Local Database** | `isar` (High-performance NoSQL DB), `shared_preferences` |
| **Audio & Media** | `just_audio`, `flutter_cache_manager` |
| **Speech & AI** | `speech_to_text`, `string_similarity` (Recitation verification) |
| **UI & Animations** | `flutter_animate`, `shimmer`, `percent_indicator`, `google_fonts`, `cupertino_icons` |
| **Utilities** | `timezone`, `path_provider`, `permission_handler`, `share_plus` |

---

## 📁 Project Architecture

The app strictly follows **Clean Architecture** principles, dividing responsibilities into distinct layers for each feature:

```text
lib/
├── main.dart                    # Application Entry Point
├── app.dart                     # Root Widget (Theme + Locale + Router)
├── core/                        # Shared Utilities, Constants, & Base Classes
│   ├── constants/               # App spacing, colors, and constants
│   ├── di/                      # Dependency Injection setup (GetIt)
│   ├── error/                   # Failures and Exceptions handling
│   ├── l10n/                    # Localization files (.arb)
│   ├── router/                  # App Router configuration
│   └── theme/                   # App Theme and Typography
└── features/                    # Feature Modules
    ├── quran/                   # Quran Reading Feature
    ├── hifz/                    # Memorization & Speech Testing
    ├── azkar/                   # Supplications Feature
    ├── progress/                # Statistics & Achievements
    └── settings/                # App Configuration
```

**Inside each feature:**
```text
feature_name/
├── data/                        # API calls, Local DB (Isar), Repositories Impl
├── domain/                      # Entities, UseCases, Abstract Repositories
└── presentation/                # Pages, Widgets, BLoC/Cubits
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK `^3.11.4` (or newer)
- Dart SDK `^3.0.0`

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/talia_quran.git
   cd talia_quran
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code** (For Isar database and Service Locator)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

*(Note: Ensure you have the required fonts in `assets/fonts/` as defined in `pubspec.yaml`)*

---

## 🎨 Design System

Our UI is designed to be visually stunning yet calm, reflecting the nature of the application.

- **Primary Color:** `#1A6B5A` (Deep teal-green)
- **Accent Color:** `#D4A843` (Warm gold)
- **Backgrounds:** `#0D1117` (Dark Mode) / `#F7F4EF` (Warm parchment for Light Mode)
- **Typography:** `Amiri` (Quranic Text), `Cormorant Garamond` (Display), `DM Sans` (Body)

---

<h2 id="العربية" align="right">العربية (Arabic)</h2>

<div align="right" dir="rtl">

**تالية (Talia)** هو تطبيق قرآني متكامل ومصمم باحترافية عالية باستخدام إطار عمل Flutter. يهدف التطبيق إلى توفير تجربة قراءة مريحة للعين، وأدوات متقدمة لتحفيظ القرآن الكريم تعتمد على التكرار المتباعد (Spaced Repetition)، بالإضافة إلى ميزة **اختبار التلاوة الذكي** باستخدام تقنيات التعرف على الصوت المدمجة.

تم بناء المشروع بالاعتماد على **البنية النظيفة (Clean Architecture)** لضمان جودة الكود وقابلية التوسع والصيانة.

### ✨ أبرز المميزات
- **مصحف متكامل:** 114 سورة مع دعم كامل للبحث، العلامات المرجعية، وضبط أحجام الخطوط.
- **تحفيظ ذكي:** نظام التكرار المتباعد للمراجعة، واختبار التلاوة الصوتي (Voice Recognition) للتأكد من صحة الحفظ بشكل تلقائي.
- **أذكار المسلم:** أذكار الصباح والمساء وغيرها مع عداد تفاعلي (Haptic Feedback).
- **تتبع الإنجاز:** إحصائيات دقيقة، نظام السلاسل اليومية (Streaks)، وإنجازات تفاعلية لتشجيع المستخدم.
- **تصميم احترافي وجذاب:** دعم كامل للوضع الليلي والنهاري، مع ألوان مريحة للعين وخطوط عربية أصيلة (Amiri).

### 🛠 التقنيات المستخدمة في المشروع
- **إدارة الحالة:** `flutter_bloc`
- **التوجيه (Routing):** `go_router`
- **قواعد البيانات المحلية:** `isar` (قاعدة بيانات سريعة وعالية الأداء) و `shared_preferences`.
- **الصوتيات:** `just_audio` لتشغيل التلاوات الصوتية بجودة عالية.
- **الذكاء الاصطناعي والتعرف على الصوت:** `speech_to_text` و `string_similarity` لاختبار ومطابقة التلاوة.
- **الرسوميات والواجهة:** `flutter_animate` لإضافة حيوية وحركة للتطبيق، و `percent_indicator` لعرض نسب الإنجاز.
- **التنبيهات:** `flutter_local_notifications` للإشعارات والتذكيرات المحلية.

### 📁 بنية المشروع
يعتمد التطبيق على **Clean Architecture** حيث يتم تقسيم كل ميزة (Feature) إلى ثلاث طبقات أساسية:
1. **Data Layer:** للتعامل مع قاعدة البيانات المحلية Isar والـ APIs.
2. **Domain Layer:** تحتوي على الكيانات (Entities) وقواعد العمل (Use Cases).
3. **Presentation Layer:** واجهة المستخدم وإدارة الحالة باستخدام BLoC/Cubit.

</div>

---
<div align="center">
  <i>Built with ❤️ using Flutter</i>
</div>
