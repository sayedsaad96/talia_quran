# Talia Product Context

This file captures durable product intent. The repository remains the technical source of truth.

## Product

**Talia Quran — تالية القرآن** is a mobile Quran companion that helps people build a lasting relationship with the Quran through reading, listening, learning, memorization, revision, daily practice, progress, encouragement, and guided growth.

Talia serves **adults and children**. The core product must never feel children-only; playful presentation belongs in suitable kids contexts while adult surfaces remain calm and mature.

## Integrated Journey

**Discover → Read → Understand/Learn → Listen → Repeat → Memorize → Recite/Test → Detect Weakness → Review → Maintain Mastery → Return**

This journey is a product direction, not permission to rebuild working flows. Map what exists first, then improve the missing links between existing capabilities.

## Product Principles

- Extend existing Talia systems before creating parallel subsystems.
- Prefer useful continuity between reading, audio, memorization, revision, learning, progress, and return behavior over feature count.
- Keep focused Quran reading calm; companion, rewards, and gamification remain secondary to worship and learning.
- Use progressive complexity: simple first, advanced controls when users need them.
- Evaluate ideas with `BUILD`, `EXTEND`, `DEFER`, or `REJECT` rather than treating every idea as implementation-ready.
- Do not copy competitors blindly. Understand the user problem and solve it in Talia's own journey.

## Durable Experience Constraints

- Arabic and English are first-class; RTL/LTR quality matters.
- Quran/Mushaf rendering, identifiers, reading position, recitation synchronization, memorization state, and review state are correctness-sensitive.
- Mobile is the product scope. Do not invent web/desktop requirements unless scope explicitly changes.
- Offline and poor-network behavior matter wherever current repository behavior depends on them.

## Companion Rules

The Talia companion may guide, encourage, celebrate, or offer contextual hints, but it must not obstruct Mushaf reading, repeat interruptions excessively, or turn serious worship flows into a game.
