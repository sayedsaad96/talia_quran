<div align="center">
  <img src="assets/images/logo.png" alt="Talia Logo" width="120">

  # تالية — Talia Quran

  **A Premium, Intelligent, Offline-First Quran Memorization & Recitation Application**

  [![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
  [![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-success?style=flat-square)](#-project-architecture)
  [![BLoC](https://img.shields.io/badge/State_Management-BLoC-blue?style=flat-square)](#-tech-stack--libraries)
  [![Isar DB](https://img.shields.io/badge/Database-Isar_NoSQL-orange?style=flat-square)](#-tech-stack--libraries)
  [![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](#-tech-stack--libraries)

  [English](#english) • [العربية](#العربية)
</div>

---

<h2 id="english">📖 Overview & Philosophy</h2>

**Talia (تالية)** is a state-of-the-art, beautifully crafted Flutter application dedicated to the Holy Quran. Built with an uncompromising focus on visual excellence, cognitive science, and robust software architecture, Talia transforms how Muslims engage with, memorize, and recite the Quran.

At its core, Talia bridges traditional Islamic learning with cutting-edge technology. It combines an immersive reading experience, advanced **Spaced Repetition System (SRS)** algorithms for Hifz, **AI-powered speech recognition** for recitation testing, gamified habit-building, and dedicated tracking modes for both children and adults.

Designed using strict **Clean Architecture** and **Domain-Driven Design (DDD)** principles, Talia offers a highly performant, maintainable, and offline-first codebase ready for production scale.

---

## ✨ Comprehensive Features

### 📖 1. Advanced Quran Reader (المصحف الشريف المطور)
- **Complete 114 Surahs:** Fully verified Ottoman script texts complete with Ayah counts, Juz divisions, Hizb quarters, and Makki/Madani revelation classifications.
- **Mushaf-Like Visual Excellence:** Offers an authentic reading experience featuring premium `Amiri` typography, adjustable font sizes (16–36px), and a distraction-free Focus Mode.
- **QCF Visual Rendering Layer:** Integrates `qcf_quran_plus` for flawless, crystal-clear Mushaf page rendering on memorization screens, while maintaining robust local JSON/Isar stores as the logical source of truth.
- **High-Quality Audio Recitation:** Ayah-by-Ayah audio playback powered by `just_audio` with seamless offline caching via `flutter_cache_manager`.
- **Intelligent Navigation:** Fast grid-based Juz selection, Surah list browsing, direct page jumping, and lightning-fast full-text Arabic search.
- **Bookmarks & Clipboard Support:** Persistent Ayah bookmarking and quick copy/share functionalities.

### 🧠 2. Intelligent Hifz & Spaced Repetition (التحفيظ الذكي والتكرار المتباعد)
- **Spaced Repetition System (SRS):** Employs smart, scientifically optimized review intervals (`[1, 3, 7, 14, 30, 90]` days) to transition memorized Ayahs from short-term to permanent long-term memory.
- **AI Voice Recognition Testing:** Integrates `speech_to_text` and `string_similarity` to actively listen to your recitation, analyze your pronunciation, and automatically verify correctness against the Mushaf text.
- **Self-Testing & Masking Mode:** Traditional Hifz practice tools that allow users to reveal or hide Ayahs, test their recall, and toggle locked/memorized states.
- **Structured Sessions & Checkpoints:** Guided memorization sessions with mandatory checkpoint reviews to guarantee mastery before progressing to new Ayahs.

### 🌱 3. Memorization Plus & Dual Identity Tracks (مسارات مخصصة للأطفال والكبار)
- **Child vs. Adult Tracks:** A specialized onboarding flow that adapts the app's interface, tone, and pacing based on whether the user is a child or an adult.
- **Smart Daily Plan (Adults):** Automated, adaptive daily memorization targets and review schedules tailored to adult learning paces.
- **Kids Journey Mode:** A highly engaging, gamified step-by-step memorization map designed specifically to keep children motivated.
- **Guardian Linking & Parent Dashboard:** Secure QR-code / Supabase pairing that allows parents and guardians to remotely monitor their child's Hifz progress, daily streaks, and quiz results in real time.
- **Custom Plan Setup:** Allows users to design fully customized memorization goals and target completion dates.
- **Interactive Quizzes:** Built-in testing screens and checkpoint quizzes to reinforce retention.

### 🌿 4. Interactive Azkar & Supplications (أذكار المسلم التفاعلية)
- **Comprehensive Daily Dhikr:** Categorized supplications including Morning, Evening, Post-Prayer, and General Azkar.
- **Haptic-Feedback Counters:** Engaging, tactile counter buttons utilizing `HapticFeedback` paired with smooth animated progress rings (`percent_indicator`).
- **Smart Daily Tracking:** Automatically tracks and remembers your Dhikr progress throughout the day.

### 📊 5. Gamification, Progress & Habit Building (التحفيز ونظام المكافآت)
- **Visual Statistics & Heatmaps:** Beautiful circular progress indicators and detailed Surah/Juz completion heatmaps.
- **Daily Streaks (`StreakService`):** Auto-calculated daily engagement streaks to encourage consistent reading and memorization habits.
- **XP Points System (`XpService`):** Users earn XP points for completing Hifz sessions, daily plans, and quizzes, turning daily worship into an engaging journey.
- **Badges & Certificates (`AchievementService`):** Unlockable milestone badges and personalized, shareable/printable Certificates of Completion (`CertificatePage`) to celebrate major memorization achievements.

### ⚙️ 6. Personalization, Localization & Accessibility (التخصيص وسهولة الوصول)
- **Premium Curated Themes:** Light Mode (warm parchment `#F7F4EF`), Dark Mode (sleek `#0D1117`), and System-matched themes accented with Deep Teal-Green (`#1A6B5A`) and Warm Gold (`#D4A843`).
- **Instant Bilingual Localization:** Flawless RTL/LTR switching between Arabic and English instantly without requiring an app restart.
- **Local Notifications & Reminders:** Configurable daily push reminders via `flutter_local_notifications` to maintain Hifz and Azkar routines.
- **Offline-First Architecture:** Designed to work seamlessly without an internet connection. Core features, Isar database storage, and cached audio degrade gracefully and function flawlessly offline.

---

## 🛠 Tech Stack & Libraries

Talia leverages a highly curated selection of modern Flutter packages to deliver a premium, rock-solid experience:

| Category | Technology / Package | Purpose / Details |
|----------|----------------------|-------------------|
| **Core Framework** | Flutter (`>=3.22`), Dart (`>=3.4`) | High-performance cross-platform UI framework |
| **State Management** | `flutter_bloc` | Predictable, event-driven state management using Cubits |
| **Architecture & DI** | Clean Architecture, `get_it`, `dartz` | Strict decoupling, dependency injection, and functional error handling |
| **Routing** | `go_router` | Declarative routing with `ShellRoute` for advanced navigation & deep linking |
| **Local Database** | `isar`, `shared_preferences` | Blazing-fast NoSQL database for structured data and fast key-value storage |
| **Backend & Sync** | `supabase_flutter` | Cloud authentication, remote backup, and guardian-child pairing |
| **Audio & Media** | `just_audio`, `flutter_cache_manager` | Advanced audio playback and offline file caching |
| **Speech & AI** | `speech_to_text`, `string_similarity` | Real-time speech recognition and recitation accuracy verification |
| **UI & Animations** | `qcf_quran_plus`, `flutter_animate`, `shimmer`, `percent_indicator`, `google_fonts` | Mushaf rendering, smooth micro-animations, loading skeletons, and custom typography |
| **Utilities** | `timezone`, `path_provider`, `permission_handler`, `share_plus`, `flutter_local_notifications` | Local notifications, file system access, permissions, and sharing capabilities |

---

## 📁 Project Architecture

Talia strictly adheres to **Clean Architecture** and **Domain-Driven Design (DDD)** principles. The codebase is organized by feature modules, ensuring clear separation of concerns, high testability, and easy scalability.

```text
lib/
├── main.dart                    # Application Entry Point & Bootstrap
├── app.dart                     # Root Widget (Theme + Locale + Router Setup)
├── core/                        # Shared Utilities, Constants, & Base Infrastructure
│   ├── constants/               # App spacing, colors, and global constants
│   ├── di/                      # Dependency Injection setup (`injection.dart`)
│   ├── error/                   # Failures, Exceptions, and Error handling models
│   ├── l10n/                    # Localization files (.arb for EN & AR)
│   ├── router/                  # App Router configuration (`app_router.dart`)
│   ├── services/                # Core DI Services (Streak, XP, Achievements, Audio)
│   ├── theme/                   # App Theme definitions and Typography
│   └── widgets/                 # Global Reusable Widgets (e.g., `QcfHifzVerseView`)
└── features/                    # Independent Feature Modules
    ├── auth/                    # Authentication & Supabase Session Management
    ├── azkar/                   # Supplications & Interactive Counters
    ├── hifz/                    # Memorization Sessions & Speech Testing
    ├── home/                    # Main Dashboard & Quick Action Shortcuts
    ├── memorization_plus/       # Dual Track (Kids/Adults), Daily Plans, Guardian Linking
    ├── onboarding/              # First-Launch Welcome & Setup Flow
    ├── progress/                # Statistics, Heatmaps, Streaks, XP & Certificates
    ├── quran/                   # Mushaf Reader, Audio Player & Search
    ├── settings/                # App Configuration, Theme/Locale Toggles, Profile
    └── splash/                  # Initial Routing & Session Restoration
```

### Layered Architecture Inside Each Feature
Each feature inside `lib/features/` is strictly decoupled into three layers:

```text
feature_name/
├── data/                        # API calls, Local DB (Isar), Data Models, Repositories Impl
├── domain/                      # Entities, Business Logic (UseCases), Abstract Repositories
└── presentation/                # Pages, Reusable UI Widgets, State Management (BLoC/Cubits)
```

---

## 🚀 Quick Start & Installation

### Prerequisites
- Flutter SDK `^3.11.4` (or newer)
- Dart SDK `^3.0.0` (or newer)

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

3. **Generate Code** (Required for Isar database schemas and GetIt Service Locator)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```

*(Note: Ensure all required fonts are present in `assets/fonts/` as defined in `pubspec.yaml`)*

---

## 🎨 Design System & Aesthetics

Talia's user interface is designed to be visually stunning, premium, and spiritually calming.

- **Primary Color:** `#1A6B5A` (Deep Teal-Green — represents tranquility and growth)
- **Accent Color:** `#D4A843` (Warm Gold — represents premium quality and illumination)
- **Backgrounds:** `#0D1117` (Rich Dark Mode) / `#F7F4EF` (Warm Parchment for Light Mode)
- **Typography:** `Amiri` (Elegant Quranic Script), `Cormorant Garamond` (Display Headings), `DM Sans` (Clean Modern Body Text)

---

<h2 id="العربية" align="right">العربية (Arabic)</h2>

<div align="right" dir="rtl">

# تالية — Talia Quran

**تطبيق قرآني احترافي متكامل، يعمل بدون إنترنت، ويدمج بين أصالة التلاوة وذكاء التقنية لتحفيظ ومراجعة القرآن الكريم.**

---

### 📖 نبذة عن التطبيق وفلسفته
**تالية (Talia)** هو تطبيق قرآني متطور ومصمم بأعلى معايير الجودة والجماليات باستخدام إطار عمل Flutter. يهدف التطبيق إلى إحداث نقلة نوعية في طريقة تفاعل المسلم مع القرآن الكريم قراءةً وحفظاً ومراجعةً، من خلال الجمع بين العلوم المعرفية والتقنيات الحديثة.

يعتمد التطبيق على خوارزميات **التكرار المتباعد (Spaced Repetition System)** لتثبيت الحفظ ونقله من الذاكرة قصيرة المدى إلى الذاكرة طويلة المدى، بالإضافة إلى ميزة **اختبار التلاوة الصوتي الذكي** باستخدام تقنيات التعرف على الصوت المدمجة، ونظام تحفيز متكامل (نقاط وسلاسل يومية)، ومسارات مخصصة تناسب كلاً من الأطفال والكبار.

تم بناء المشروع بالاعتماد الكامل على **البنية النظيفة (Clean Architecture)** ومبادئ **Domain-Driven Design (DDD)**، مما يضمن كوداً عالي الأداء، سهل الصيانة، وقابلاً للتطوير والتوسع بكل سلاسة.

---

## ✨ المميزات الشاملة بالتفصيل

### 📖 1. المصحف الشريف المطور (Quran Reader)
- **مصحف متكامل (114 سورة):** نصوص قرآنية بالرسم العثماني مدققة بالكامل، مع عرض أرقام الآيات، الأجزاء، الأرباع، وتصنيف السور (مكية/مدنية).
- **تجربة بصرية مريحة واحترافية:** خطوط عربية أصيلة (`Amiri`)، إمكانية تعديل حجم الخط (من 16 إلى 36 بكسل)، ووضع التركيز (Focus Mode) لقراءة خالية من المشتتات.
- **طبقة العرض البصري QCF:** دمج حزمة `qcf_quran_plus` لتقديم عرض فائق الدقة والوضوح لصفحات المصحف في شاشات التحفيظ، مع الحفاظ على قواعد البيانات المحلية (JSON/Isar) كمصدر أساسي وموثوق للبيانات.
- **تلاوات صوتية عالية الجودة:** تشغيل صوتي للآيات عبر `just_audio` مع ميزة التحميل المسبق والتخزين المؤقت (Caching) للاستماع بدون إنترنت.
- **تنقل سريع وبحث فوري:** شبكة تفاعلية لاختيار الأجزاء والسور، الانتقال المباشر للصفحات، وبحث نصي فوري وشامل في كامل المصحف.
- **العلامات المرجعية والنسخ:** حفظ تلقائي للعلامات المرجعية للآيات، ودعم النسخ والمشاركة المباشرة.

### 🧠 2. التحفيظ الذكي والتكرار المتباعد (Intelligent Hifz & SRS)
- **نظام التكرار المتباعد (SRS):** جدولة ذكية للمراجعات بفترات مدروسة علمياً (`[1, 3, 7, 14, 30, 90]` أيام) لضمان ترسيخ الآيات المحفوظة وعدم نسيانها.
- **اختبار التلاوة الصوتي الذكي:** استخدام تقنيات `speech_to_text` و `string_similarity` للاستماع إلى تلاوة المستخدم ومطابقتها تلقائياً مع النص القرآني وتحديد الأخطاء بدقة.
- **وضع التسميع الذاتي (إخفاء/إظهار):** أدوات تسميع تقليدية تتيح للمستخدم إخفاء الآيات وإظهارها لاختبار حفظه، مع التحكم في قفل أو تحديد الآيات المحفوظة.
- **جلسات ونقاط فحص مبرمجة:** جلسات حفظ منظمة تتضمن اختبارات مرحلية (Checkpoints) للتأكد من إتقان الورد الحالي قبل الانتقال للورد التالي.

### 🌱 3. مسارات التحفيظ المخصصة للأطفال والكبار (Memorization Plus)
- **مسار الأطفال ومسار الكبار (Dual Tracks):** نظام تهيئة وتوجيه (Onboarding) يقوم بتخصيص واجهة التطبيق، أسلوب العرض، ونمط التحفيز بناءً على الفئة العمرية للمستخدم.
- **الخطة اليومية الذكية للكبار (Smart Daily Plan):** أهداف حفظ ومراجعة يومية يتم توليدها وتكييفها تلقائياً لتناسب جدول المستخدم البالغ.
- **رحلة الأطفال التفاعلية (Kids Journey):** خريطة حفظ تفاعلية وممتعة مصممة خصيصاً لجذب الأطفال وتشجيعهم على الاستمرار في الحفظ.
- **ربط الوالدين ولوحة المتابعة (Parent Dashboard):** نظام ربط آمن عبر مسح رمز الاستجابة السريعة (QR Code) و Supabase، يتيح للوالدين متابعة تقدم أطفالهم، سلاسلهم اليومية، ونتائج اختباراتهم عن بُعد في الوقت الفعلي.
- **خطط حفظ مخصصة (Custom Plans):** إمكانية إنشاء خطة حفظ خاصة بجدول زمني وتاريخ انتهاء محددين.
- **اختبارات تفاعلية (Quizzes):** شاشات اختبار وتحديات لتقييم الحفظ وتثبيت المراجعة.

### 🌿 4. أذكار المسلم التفاعلية (Interactive Azkar)
- **أذكار شاملة:** تصنيفات يومية تشمل أذكار الصباح، المساء، أدعية الصلاة، والأذكار العامة.
- **عدادات تفاعلية ذكية:** أزرار تسبيح تدعم الاهتزاز التفاعلي (`HapticFeedback`) مع حلقات تقدم دائرية متحركة (`percent_indicator`).
- **تتبع ذكي للأذكار:** حفظ وتتبع تقدم المستخدم في الأذكار على مدار اليوم.

### 📊 5. التحفيز، الإحصائيات ونظام المكافآت (Gamification & Progress)
- **إحصائيات وخرائط حرارية (Heatmaps):** مؤشرات تقدم دائرية جذابة ورسوم بيانية توضح نسب إنجاز السور والأجزاء المحفوظة.
- **السلاسل اليومية (`StreakService`):** حساب تلقائي لأيام المداومة المستمرة على التطبيق لتشجيع المستخدم على بناء عادة يومية لا تنقطع.
- **نظام النقاط (`XpService`):** يكتسب المستخدم نقاط خبرة (XP) عند إتمام جلسات الحفظ، الخطط اليومية، والاختبارات، مما يضفي طابعاً تفاعلياً ومحفزاً.
- **الأوسمة والشهادات التقديرية (`AchievementService`):** شارات إنجاز تفتح عند الوصول لمراحل متقدمة، بالإضافة إلى **شهادات تقديرية مخصصة** (`CertificatePage`) يمكن مشاركتها أو طباعتها احتفاءً بإتمام حفظ الأجزاء والسور.

### ⚙️ 6. التخصيص، سهولة الوصول والإشعارات (Personalization & Accessibility)
- **مظهر احترافي مريح للعين:** دعم كامل للوضع النهاري (لون الورق الدافئ `#F7F4EF`)، الوضع الليلي العميق (`#0D1117`)، ووضع النظام، مع لمسات فنية باللونين الأخضر المزرق (`#1A6B5A`) والذهبي الدافئ (`#D4A843`).
- **دعم ثنائي اللغة فوري:** التبديل الفوري والسلس بين اللغتين العربية والإنجليزية (RTL/LTR) بضغطة زر وبدون الحاجة لإعادة تشغيل التطبيق.
- **إشعارات وتذكيرات محلية:** تنبيهات يومية مخصصة عبر `flutter_local_notifications` للتذكير بورد القرآن وأذكار الصباح والمساء.
- **معمارية العمل بدون إنترنت (Offline-First):** صُمم التطبيق ليعمل بكفاءة تامة دون الحاجة لاتصال بالإنترنت، حيث يتم تخزين البيانات محلياً في قاعدة بيانات Isar مع التخزين المؤقت للملفات الصوتية.

---

## 🛠 التقنيات والحزم المستخدمة في المشروع

يعتمد تطبيق **تالية** على أحدث التقنيات والحزم المعتمدة في بيئة Flutter لضمان أداء مستقر واحترافي:

| التصنيف | التقنية / الحزمة | الغرض والتفاصيل |
|---------|------------------|-----------------|
| **إطار العمل الأساسي** | Flutter (`>=3.22`), Dart (`>=3.4`) | إطار عمل لبناء واجهات مستخدم سريعة وعابرة للمنصات |
| **إدارة الحالة (State Management)** | `flutter_bloc` | إدارة حالة التطبيق بطريقة منظمة وقابلة للتوقع باستخدام Cubits |
| **المعمارية وحقن التبعيات** | Clean Architecture, `get_it`, `dartz` | فصل الاهتمامات، حقن التبعيات (DI)، ومعالجة الأخطاء وظيفياً |
| **التوجيه (Routing)** | `go_router` | توجيه متقدم يدعم ShellRoute والروابط العميقة (Deep Linking) |
| **قواعد البيانات المحلية** | `isar`, `shared_preferences` | قاعدة بيانات NoSQL فائقة السرعة للبيانات المعقدة والتخزين المحلي السريع |
| **الخوادم والمزامنة** | `supabase_flutter` | المصادقة السحابية، النسخ الاحتياطي، وربط حسابات الوالدين بالأطفال |
| **الصوتيات والوسائط** | `just_audio`, `flutter_cache_manager` | تشغيل التلاوات بجودة عالية مع التخزين المؤقت للملفات الصوتية |
| **الذكاء الاصطناعي والتعرف على الصوت** | `speech_to_text`, `string_similarity` | التعرف الفوري على الصوت ومطابقة التلاوة مع النص القرآني |
| **الرسوميات والواجهات** | `qcf_quran_plus`, `flutter_animate`, `shimmer`, `percent_indicator`, `google_fonts` | عرض صفحات المصحف، حركات تفاعلية، شاشات التحميل المسبق، وخطوط مخصصة |
| **أدوات مساعدة** | `timezone`, `path_provider`, `permission_handler`, `share_plus`, `flutter_local_notifications` | إدارة الإشعارات المحلية، الصلاحيات، والوصول لملفات النظام والمشاركة |

---

## 📁 بنية المشروع والمعمارية (Project Architecture)

يلتزم المشروع تطبيقاً صارماً بمبادئ **البنية النظيفة (Clean Architecture)**، حيث يتم تقسيم التطبيق إلى وحدات وميزات مستقلة (Feature Modules) لضمان سهولة الصيانة وقابلية التوسع واختبار الأكواد.

```text
lib/
├── main.dart                    # نقطة الدخول وبدء تشغيل التطبيق
├── app.dart                     # الودجت الأساسي (إعداد الثيم، اللغة، والراوتر)
├── core/                        # الأدوات المشتركة، الثوابت، والبنية التحتية
│   ├── constants/               # ثوابت التطبيق، الألوان، والمسافات
│   ├── di/                      # إعداد حقن التبعيات (GetIt)
│   ├── error/                   # معالجة الأخطاء والاستثناءات
│   ├── l10n/                    # ملفات الترجمة والتوطين (.arb)
│   ├── router/                  # إعدادات التوجيه والمسارات
│   ├── services/                # الخدمات الأساسية (النقاط، السلاسل، الأوسمة، الصوت)
│   ├── theme/                   # إعدادات المظهر والخطوط
│   └── widgets/                 # ودجتس عامة قابلة لإعادة الاستخدام (مثل QcfHifzVerseView)
└── features/                    # وحدات الميزات المستقلة
    ├── auth/                    # المصادقة وإدارة الجلسات
    ├── azkar/                   # الأذكار والعدادات التفاعلية
    ├── hifz/                    # جلسات التحفيظ واختبار التلاوة
    ├── home/                    # الشاشة الرئيسية والاختصارات السريعة
    ├── memorization_plus/       # مسارات الأطفال/الكبار، الخطط اليومية، وربط الوالدين
    ├── onboarding/              # شاشات الترحيب والتهيئة الأولى
    ├── progress/                # الإحصائيات، الخرائط الحرارية، النقاط والشهادات
    ├── quran/                   # تصفح المصحف، المشغل الصوتي، والبحث
    ├── settings/                # إعدادات التطبيق، الثيم، والملف الشخصي
    └── splash/                  # شاشة البداية واستعادة الجلسة السابقة
```

### التقسيم الداخلي لكل ميزة (Inside Each Feature)
تتكون كل ميزة داخل مجلد `features` من ثلاث طبقات رئيسية معزولة تماماً:

```text
feature_name/
├── data/                        # التعامل مع قواعد البيانات (Isar) والـ APIs والنماذج (Models)
├── domain/                      # الكيانات (Entities) وقواعد العمل (UseCases)
└── presentation/                # واجهة المستخدم (Pages/Widgets) وإدارة الحالة (BLoC/Cubits)
```

---

## 🚀 دليل التشغيل السريع (Quick Start)

### المتطلبات الأساسية
- حزمة Flutter SDK الإصدار `^3.11.4` (أو أحدث)
- حزمة Dart SDK الإصدار `^3.0.0` (أو أحدث)

### خطوات التثبيت والتشغيل

1. **نسخ المشروع (Clone)**
   ```bash
   git clone https://github.com/yourusername/talia_quran.git
   cd talia_quran
   ```

2. **تثبيت الحزم والتبعيات**
   ```bash
   flutter pub get
   ```

3. **توليد الأكواد (Code Generation)** (ضروري لقواعد بيانات Isar وحقن التبعيات GetIt)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **تشغيل التطبيق**
   ```bash
   flutter run
   ```

*(ملاحظة: تأكد من وجود ملفات الخطوط المطلوبة داخل مجلد `assets/fonts/` كما هو محدد في ملف `pubspec.yaml`)*

---

<div align="center">
  <i>تم التطوير بكل ❤️ باستخدام Flutter لخدمة كتاب الله الكريم</i>
</div>

</div>
