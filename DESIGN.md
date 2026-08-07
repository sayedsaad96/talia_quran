---
name: Talia Quran
description: Arabic-first, offline-first Quran memorization companion
colors:
  royal-teal: "#0D5C53"
  royal-teal-light: "#148275"
  royal-teal-deep: "#042F2E"
  warm-gold: "#F59E0B"
  warm-gold-light: "#FBBF24"
  warm-gold-deep: "#D97706"
  warm-paper: "#FDFCF8"
  surface: "#FFFFFF"
  surface-muted: "#F4F2EC"
  ink: "#1A1209"
  ink-muted: "#6B5E4E"
  night: "#021210"
  night-surface: "#041D1A"
  night-muted: "#0A2925"
  moon-ink: "#F0EDE6"
  divider: "#EBE8DF"
  success: "#2E7D5E"
  error: "#C0392B"
typography:
  display:
    fontFamily: "Amiri"
    fontSize: "48px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Noto_Naskh_Arabic"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Noto_Naskh_Arabic"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "-0.1px"
  body:
    fontFamily: "Noto_Naskh_Arabic"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "Noto_Naskh_Arabic"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.1px"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
  full: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  page: "20px"
  lg: "24px"
  section: "32px"
  xl: "32px"
  xxl: "48px"
  xxxl: "64px"
components:
  button-primary:
    backgroundColor: "{colors.royal-teal}"
    textColor: "{colors.surface}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "16px 32px"
    height: "56px"
  button-secondary:
    backgroundColor: "rgba(13, 92, 83, 0.08)"
    textColor: "{colors.royal-teal}"
    typography: "{typography.title}"
    rounded: "{rounded.md}"
    padding: "16px 32px"
    height: "56px"
  card-default:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "20px"
  field-default:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px"
    height: "56px"
  nav-item-active:
    backgroundColor: "rgba(13, 92, 83, 0.12)"
    textColor: "{colors.royal-teal}"
    rounded: "{rounded.full}"
---

# Design System: Talia Quran

## Overview

**Creative North Star: "The Guided Sanctuary"**

Talia is a calm, structured, confidence-building mobile experience that gently guides learners through a memorization practice while keeping the Quran at the center of attention. Its visual language combines Royal Teal, Warm Gold, warm paper surfaces, and Arabic-first typography to feel trustworthy, reverent, and enduring rather than trend-driven.

The system is deliberately low-noise: clear hierarchy, generous reading space, and tactile controls support daily use without competing for attention. Soft ambient lift improves wayfinding and reinforces important actions, while the foundation stays calm and readable across light and dark themes. Kids Mode is a brighter, warmer expression of this same system—not a separate identity.

**Key Characteristics:**

- Arabic-first readability, with Quranic and UI typography treated as functional hierarchy.
- Teal-led guidance; gold-led meaning and achievement.
- Softly lifted, rounded surfaces that feel supportive rather than ornamental.
- Focused interaction and restrained motion for sustainable daily practice.

## Colors

Royal Teal & Warm Gold pairs a steady, reverent base with a deliberately rare reward signal; warm paper and deep night neutrals protect reading comfort in both appearances.

### Primary

- **Royal Teal:** the primary guidance color for main actions, selected states, and focus treatment.
- **Royal Teal Light:** the dark-theme interactive counterpart and lighter gradient end.
- **Royal Teal Deep:** the grounding end of primary gradients and deep teal treatments.

### Secondary

- **Warm Gold:** a semantic accent for meaningful progress, achievements, spiritual emphasis, milestones, and premium highlights.
- **Warm Gold Light / Deep:** gradient and tonal variants for those same semantic moments.

### Tertiary

- **Success Green:** completion and successful progress only.
- **Error Red:** error, destructive, and correction states only.

### Neutral

- **Warm Paper, Surface, and Surface Muted:** light-mode reading and layered surfaces.
- **Ink and Ink Muted:** high-priority and supporting light-mode copy.
- **Night, Night Surface, Night Muted, and Moon Ink:** dark-mode background, layers, and reading text.
- **Divider:** quiet boundaries between related content.

**The Meaningful Gold Rule.** Gold is never the routine action, navigation, or default interactive color. Reserve it for progress, achievement, spiritual emphasis, milestones, and premium highlights.

## Typography

**Display Font:** Amiri

**Body Font:** Noto Naskh Arabic

**Character:** Amiri gives Quranic and display moments dignity and presence; Noto Naskh Arabic keeps interface content comfortable and unhurried for sustained Arabic reading.

### Hierarchy

- **Display:** Amiri, 700; used for high-importance display moments.
- **Headline:** Noto Naskh Arabic, 700; screen and section hierarchy.
- **Title:** Noto Naskh Arabic, 700/600; compact card and control hierarchy.
- **Body:** Noto Naskh Arabic, 400; explanatory interface copy and long-form supportive content.
- **Label:** Noto Naskh Arabic, 600; buttons, navigation, chips, and metadata.
- **Quran text:** Amiri at dedicated reading sizes with generous line-height; never compress Quranic text to fit a decorative composition.

**The Readability Before Fashion Rule.** Accessibility, Arabic typography, and legibility take precedence over visual trends, density, or novelty.

## Layout

The system follows an 8-point rhythm: compact gaps begin at 4px and scale through 8px, 16px, 24px, 32px, 48px, and 64px. Phone screens use 20px page padding, 32px section gaps, 20px card padding, and 12px item gaps. Primary controls and fields are 56px high to retain comfortable touch targets and a reassuring density.

The primary app shell uses five destinations. Compact screens use a floating, safe-area-aware bottom navigation; screens at 600px and above switch to a navigation rail. Content remains portrait-first, RTL-aware, and safely inset from system UI.

## Elevation & Depth

Talia uses soft ambient lift for cards and important actions, with tonal separation doing most of the organizational work. Default cards remain quiet; elevated cards use a diffuse teal or black shadow, and floating navigation carries a stronger translucent surface treatment. Dark mode uses the same restrained hierarchy rather than an inverted light design.

### Shadow Vocabulary

- **Elevated card:** diffuse 16px blur with a 6px downward offset; use for a card that must separate from its surroundings.
- **Primary action:** 12px blur with a 4px downward offset; use for the main action only.
- **Floating navigation:** 24px blur with an 8px downward offset; use for the persistent floating shell.

**The Quiet Depth Rule.** Elevation clarifies hierarchy; it must not become decoration, spectacle, or a substitute for layout.

## Shapes

Forms are gently rounded and tactile: 12px for fields and buttons, 16px for standard cards, 24px for special spiritual or achievement cards, and full pills for chips and navigation indicators. Borders are thin and quiet; cards use subtle dividers or translucent glass edges rather than heavy outlines. Gold-rimmed surfaces are reserved for achievement and premium emphasis.

## Components

### Buttons

Tactile and encouraging, with a brief press scale to 0.96 and a 56px default height.

- **Primary:** Royal Teal gradient, white label, 12px radius, soft teal ambient lift.
- **Secondary:** low-opacity teal fill with a translucent teal border and teal label.
- **Ghost:** no filled surface; uses muted text for low-emphasis actions.
- **Gold primary:** restricted to the Meaningful Gold Rule.

### Chips

- **Style:** muted surface at rest, full-pill form, and a low-opacity teal selected state.
- **State:** selected chips carry the active color without becoming a dominant filled control.

### Cards / Containers

- **Corner Style:** 16px default; 24px for spiritual and achievement variants.
- **Background:** warm surface in light mode; deep night surface in dark mode.
- **Shadow Strategy:** flat at rest, with soft ambient lift only when hierarchy warrants it.
- **Border:** a thin, low-contrast divider or translucent glass edge.
- **Internal Padding:** 20px by default.

### Inputs / Fields

- **Style:** filled muted surface, 12px radius, and 16px internal padding.
- **Focus:** 1.5px Royal Teal outline in light mode and Royal Teal Light in dark mode.
- **Error / Disabled:** error uses the semantic error color; disabled controls reduce opacity rather than abandoning hierarchy.

### Navigation

- **Style:** five top-level destinations, labelled icons, full-pill active indicator, and a small active dot.
- **Compact:** floating glass bottom navigation with system-safe spacing.
- **Expanded:** navigation rail; selected state remains semantically distinct without changing the information architecture.

### Kids Mode

Kids Mode keeps the shared typography, spacing, component system, teal-and-gold foundation, and interaction principles. It may introduce warmer illustrations, softer motion, and playful night-sky details, but never prioritizes novelty over clarity, focus, or memorization.

## Do's and Don'ts

### Do:

- **Do** make the memorization journey and Quran reading comfortable for extended daily use.
- **Do** use Royal Teal for ordinary guidance and Warm Gold only for meaningful progress and emphasis.
- **Do** preserve generous Arabic line-height and clear RTL reading structure.
- **Do** use soft ambient depth sparingly to clarify important surfaces and actions.
- **Do** extend Kids Mode from the shared system, with warmer and more playful details only where they aid comprehension.

### Don't:

- **Don't** use gold for routine actions, persistent navigation, or default interactive surfaces.
- **Don't** compress Arabic or Quranic text to make room for decorative treatment.
- **Don't** turn reflection, progress, or study into screen-time-maximizing spectacle.
- **Don't** create a separate visual identity or component language for Kids Mode.
- **Don't** let animation, glow, or glass treatment compete with focus, readability, and sustainable memorization practice.
