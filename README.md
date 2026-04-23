# تالية — Talia
### A Premium Quran Memorization & Recitation App

---

## 🚀 Quick Start

```bash
# 1. Install Flutter (≥3.22.0 required)
flutter --version

# 2. Install dependencies
flutter pub get

# 3. Add fonts (download from Google Fonts)
# Place in assets/fonts/:
#   - Amiri-Regular.ttf
#   - Amiri-Bold.ttf
#   - NotoNaskhArabic-Regular.ttf
#   - NotoNaskhArabic-Bold.ttf

# 4. Run
flutter run
```

---

## 📁 Architecture

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Root widget (theme + locale + router)
├── core/
│   ├── constants/               # AppSpacing, AppConstants
│   ├── di/injection.dart        # GetIt dependency injection
│   ├── error/app_failure.dart   # Typed failures
│   ├── extensions/              # BuildContext extensions
│   ├── l10n/                    # Arabic + English localization
│   ├── router/app_router.dart   # go_router with ShellRoute
│   ├── theme/                   # Colors, typography, themes
│   └── widgets/                 # Design system components
└── features/
    ├── home/                    # Home dashboard
    ├── quran/                   # Quran reader (114 surahs)
    ├── hifz/                    # Memorization with spaced repetition
    ├── azkar/                   # Morning/Evening/General dhikr
    ├── progress/                # Stats, streaks, achievements
    └── settings/                # Theme, language, about
```

Each feature follows **Clean Architecture**:
```
feature/
├── data/
│   ├── datasources/    # Local storage (SharedPrefs / JSON assets)
│   ├── models/         # Data models extending domain entities
│   └── repositories/   # Repository implementations
├── domain/
│   ├── entities/       # Pure Dart domain objects
│   ├── repositories/   # Abstract repository interfaces
│   └── usecases/       # Single-responsibility use cases
└── presentation/
    ├── cubits/         # BLoC Cubits + States
    ├── pages/          # Screens
    └── widgets/        # Feature-specific widgets
```

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary | `#1A6B5A` (Deep teal-green) |
| Gold accent | `#D4A843` (Warm gold) |
| Dark background | `#0D1117` |
| Light background | `#F7F4EF` (Warm parchment) |
| Arabic font | Amiri (Quranic text) |
| Display font | Cormorant Garamond |
| Body font | DM Sans |
| Spacing grid | 8pt |

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management (Cubits) |
| `go_router` | Declarative routing with ShellRoute |
| `get_it` | Dependency injection |
| `dartz` | Functional Either<Failure, Success> |
| `just_audio` | Quran audio playback |
| `shared_preferences` | Local persistence |
| `flutter_animate` | Page/widget animations |
| `google_fonts` | DM Sans, Cormorant Garamond |
| `percent_indicator` | Progress arcs |
| `shimmer` | Loading skeletons |

---

## ✨ Features

### 📖 Quran Reader
- All 114 Surahs with ayah counts, juz, type (Meccan/Medinan)
- Surah list + Juz grid navigation
- Full-text search
- Immersive reading mode with focus toggle
- Adjustable font size (16–36px)
- Audio playback per ayah (EveryAyah CDN)
- Copy ayah to clipboard
- Persistent bookmarks

### 🧠 Hifz (Memorization)
- Select any Surah and starting Ayah
- Reveal/hide mode for self-testing
- Spaced repetition: `[1, 3, 7, 14, 30, 90]` day intervals
- Progress tracking per Surah
- Completion celebration screen

### 🌿 Azkar
- Morning (7), Evening (5), General (7) categories
- Haptic-feedback counter with animated ring
- Per-category completion screens
- Progress dots navigation

### 📊 Progress
- Overall Quran % with animated circular indicator
- Ayah + Surah memorization counts
- Streak system (persisted, auto-calculated daily)
- 6 unlockable achievements

### ⚙️ Settings
- Light / Dark / System theme
- Arabic / English language switch
- Persistent via SharedPreferences

---

## 🌐 RTL / LTR

- Arabic is the default locale (RTL)
- All layouts are RTL-aware
- go_router locale switching without restart
- Amiri font for authentic Quranic rendering

---

## 📱 Android Setup

`AndroidManifest.xml` already includes:
- `INTERNET` — audio streaming
- `WAKE_LOCK` — background playback
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — just_audio

---

## 🔧 Extending

### Add a new feature:
```bash
mkdir -p lib/features/my_feature/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{cubits,pages,widgets}}
```

### Add a new l10n string:
1. Add to `lib/core/l10n/app_ar.arb`
2. Add to `lib/core/l10n/app_en.arb`
3. Add abstract getter + both implementations in `app_localizations.dart`

### Add a new route:
1. Add path constant to `AppRoutes` in `app_router.dart`
2. Add `GoRoute` to the appropriate navigator section
3. Link via `context.go()` or `context.push()`
