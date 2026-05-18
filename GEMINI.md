# Talia Quran Project Context

## Project Overview
**Talia (تالية)** is a Flutter application dedicated to the Holy Quran. It provides an immersive reading experience, advanced memorization (Hifz) tools powered by spaced repetition, and intelligent recitation testing using speech recognition.

The project is built with **Clean Architecture** and **Domain-Driven Design**, ensuring a scalable, maintainable, and highly performant codebase.

## Technology Stack
- **Framework:** Flutter, Dart
- **State Management:** `flutter_bloc` (Cubits for UI state)
- **Architecture/DI:** Clean Architecture, `get_it` (Dependency Injection), `dartz` (Functional Error Handling)
- **Routing:** `go_router`
- **Local Database:** `isar`, `shared_preferences`
- **Backend/Services:** Supabase (`supabase_flutter`)
- **Audio & Media:** `just_audio`, `flutter_cache_manager`
- **Speech & AI:** `speech_to_text`, `string_similarity`
- **UI & Animations:** `flutter_animate`, `shimmer`, `percent_indicator`, `google_fonts`

## Architecture Conventions
The app strictly follows **Clean Architecture** principles. Each feature is located under `lib/features/` and is divided into three layers:
1. **`data/`**: API calls, Local DB (Isar), Repository Implementations.
2. **`domain/`**: Entities, UseCases, Abstract Repositories.
3. **`presentation/`**: Pages, Widgets, BLoC/Cubits.

Shared utilities, constants, dependency injection, and theming are located in `lib/core/`.

## Build and Run Instructions

### Prerequisites
- Flutter SDK `^3.11.4` (or newer)
- Dart SDK `^3.0.0` (or newer)

### Code Generation
The project relies on code generation for the Isar database and Service Locator (`get_it`). When changes are made to models or DI setup, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
flutter run
```

### Testing
Use the standard Flutter testing command:
```bash
flutter test
```