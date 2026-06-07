# Talia Quran Development Rules

## Project Overview

Talia is a Quran memorization and Islamic companion application.

Core Features:

- Quran Reading
- Quran Memorization
- Smart Hifz System
- Children Learning Path
- Azkar
- Progress Tracking
- Achievements
- Certificates
- Audio Playback
- Offline First Experience

---

## Architecture

Required:

- Clean Architecture
- Cubit only
- Repository Pattern
- UseCases
- Dependency Injection
- Feature First Structure

Forbidden:

- Business Logic inside UI
- Direct Database Access from Presentation Layer
- Global Mutable State
- God Widgets
- God Services

---

## UI Standards

- Material 3
- Responsive Design
- Arabic First
- Dark & Light Mode
- Accessibility Support

---

## Code Standards

Maximum widget size:
300 lines

Maximum method size:
50 lines

Maximum file size:
500 lines

Extract reusable widgets whenever possible.

---

## Localization

All user-facing text must use localization keys.

No hardcoded strings allowed.

---

## Performance

Avoid unnecessary rebuilds.

Prefer const constructors.

Avoid nested BlocBuilders.

Avoid excessive widget tree depth.

---

## Security

Never expose Supabase keys.

Validate all RPC calls.

Review RLS impact before schema changes.

---

## Testing

Every new feature requires:

- Unit Tests
- Widget Tests

Critical flows require:

- Integration Tests

---

## Review Priority

1. Crashes
2. Data Loss
3. Security
4. UX Problems
5. Performance
6. Code Quality