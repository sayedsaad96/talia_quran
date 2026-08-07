# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- **Primary audience:** Quran learners of all ages: children, teenagers, and adults.
- **Secondary audience:** Parents and guardians who support, encourage, and monitor a child's memorization progress.
- **Future audience:** Quran teachers and halaqa supervisors; this is not the current product focus.

## Product Purpose

Talia is an Arabic-first, offline-first Quran memorization companion. It helps learners systematically plan, learn, memorize, recite, review, and retain the Quran through personalized guidance, spaced repetition, and speech-assisted practice. Its success is sustained, confident memorization, retention, and spiritual engagement rather than passive reading alone.

Quran reading and daily adhkar are supporting features, not the product's identity.

## Positioning

Talia is a guided memorization system with intelligent coaching, not a general Quran reader or Islamic utility app. Its complete retention-focused journey combines an offline local source of truth, personalized progression, speech-assisted recitation, spaced repetition, and optional child-account supervision.

## Operating Context

- Users follow a guided memorization journey: plan → learn → memorize → recite → review → retain.
- The app supports adult and dedicated, age-appropriate Kids Mode experiences.
- Parent/guardian features use explicit account linking and consent to support child progress through positive reinforcement rather than pressure.
- The product must remain dependable during poor or absent connectivity.

## Capabilities and Constraints

- Offline-first: the local database is the source of truth; cloud sync enhances the experience but is never required.
- Memorization is the primary workflow, and every feature must support long-term retention rather than reading alone.
- Personalized guidance, spaced repetition, and speech-assisted recitation practice support the core journey.
- AI and automation assist learning without replacing intentional practice or teacher guidance.
- Arabic-first with English localization support.
- Portrait-only native mobile experience for Android and iOS.
- Fast startup and fully functional core use without internet connectivity.
- Scalable, production-ready architecture with predictable behavior during synchronization and connectivity changes.

## Brand Commitments

Talia is educational, encouraging, and respectful. It motivates through positive reinforcement, never judgment, guilt, or pressure. The experience is calm, focused, distraction-free, and respectful of the Quran.

## Evidence on Hand

- [README.md](README.md) documents the existing Flutter app, its offline local storage, optional Supabase sync, Quran reading, memorization, recitation, progress, guardian, and adhkar features.
- [ProductSpec.md](ProductSpec.md) defines the current memorization-session flow and its adult and kids variants.
- The repository contains bundled Arabic fonts and image assets under `assets/`.
- No advertising, external testimonials, customer claims, or performance benchmarks are established in the product evidence; future work must not fabricate them.

## Product Principles

1. Make consistent Quran retention and spiritual engagement easier through a clear, guided practice loop: plan → learn → memorize → recite → review → retain.
2. Keep memorization—not ancillary reading or utility features—at the center of product decisions.
3. Design every feature to improve long-term retention and consistency, never to maximize screen time.
4. Treat offline reliability and predictable synchronization as learner trust requirements; cloud sync enhances the experience but never enables it.
5. Support learners of different ages with one memorization philosophy, age-appropriate experiences, and respectful positive reinforcement.

## Accessibility & Inclusion

- Accessibility is a product-wide requirement and must be considered throughout the UI.
- Accessibility, readability, and Arabic typography take precedence over visual trends.
- The product serves children and adults, including child accounts with heightened privacy protections.
- Data collection must be minimal; the product has no advertising.
- Parent/guardian features require explicit linking and consent.
