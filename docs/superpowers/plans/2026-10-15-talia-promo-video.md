# Talia Promo Video («يوم مع تالية») Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Also load the `remotion-best-practices` skill (and the `remotion-markup` reference it routes to) before writing any `.tsx`.

**Goal:** Build an 88-second, 1920×1080 Arabic (RTL) Remotion video that follows Talia through one day and showcases every major app feature.

**Architecture:** A standalone Remotion project in `marketing/promo_video/`. Pure TypeScript modules (`timeline.ts`, `sky.ts`, `layout.ts`, `screens.ts`, `text/*`) hold all data and math and are unit-tested with Vitest. Three global layers span the whole video (sky, Talia, speech bubble) and read the active scene from the global frame. A `<Series>` of nine scene components renders the per-scene content (phone frames, drawn elements).

**Naming note:** The spec's single data source `scenes.ts` is named `src/timeline.ts` here, so it doesn't clash with the `src/scenes/` component folder. Phone placement lives in `src/scenes/sceneLayout.ts`. Text and timing stay only in `timeline.ts`. With a plain `<Series>`, scene durations come from `timeline.ts` rather than inline literals, so Studio's drag-to-retime write-back is intentionally not used.

**Tech Stack:** Remotion 4 (`create-video@latest --blank --no-tailwind`), React, TypeScript, `@remotion/fonts`, `@remotion/media`, Vitest, Node 24.

**Spec:** `docs/superpowers/specs/2026-10-15-talia-promo-video-design.md`

## Global Constraints

- Composition `TaliaPromo`: `width=1920`, `height=1080`, `fps=30`, `durationInFrames=2640`.
- Scene frame ranges, poses, and bubble copy are copied **verbatim** from spec §4. No other Arabic copy is invented except UI labels in drawn elements (prayer names, «يوم», «نقطة», «بلا اتصال», «مزامنة», «اقرأ · احفظ · راجع · انمُ»).
- No Quran text, ayah, azkar, dua, or hadith in any file under `src/`. They appear only inside real screenshots S2 and S8.
- No element (Talia, bubble, badge, drawn card) may overlap the phone frame while S2 or S8 is on screen.
- Talia images are the 10 files in `assets/talia/`, copied unmodified. No new or generated poses.
- Fonts come from `assets/fonts/`: `Reem_Kufi/ReemKufi-Variable.ttf` for headings and `Noto_Naskh_Arabic/NotoNaskhArabic-{Regular,Bold}.ttf` for bubbles.
- Digits in drawn elements are Eastern Arabic (٠١٢٣٤٥٦٧٨٩). Prayer times are illustrative.
- Brand colors: `primary #0D5C53`, `primaryLight #148275`, `primaryDark #042F2E`, `gold #F59E0B`, `goldLight #FBBF24`, `goldDark #D97706`.
- All text containers use `dir="rtl"`. Talia sits in the right corner.
- Safe area: key text at least 140px from the sides and 100px from the top and bottom. Bubble text is at least 48px.
- Drive animation only with `useCurrentFrame()` + `interpolate()`/`spring()`. No CSS transitions or animations.
- Do not render an MP4 unless the owner explicitly asks. Previews go through Studio and `remotion still`.
- Commits: the owner's working tree has unrelated uncommitted work. Commit only with the owner's go-ahead, and `git add` only `marketing/promo_video/...` paths (never `-A`).
- Never touch `lib/`, `assets/`, `pubspec.yaml`, or any Flutter file.

## Review Focus

1. **Arabic text with stacked diacritics during the typewriter reveal** (e.g. «سمِّع» has shadda + kasra on one letter): a partial reveal must never show a bare mark or split a letter from its marks. Pinned by `revealGraphemes` tests in Task 3.
2. **Longest bubble line overflowing the bubble** («وسأذكّرك بالمراجعة قبل أن تنسى» line, and «يعمل بلا إنترنت… وتقدّمك محفوظ إن شئت المزامنة»): the text must wrap inside the bubble at full reveal. Pinned by the end-of-typing stills in Task 5.
3. **A screenshot not yet supplied**: the video must still render, showing a labelled placeholder rather than crashing on a missing file. Pinned by the `screens.ts` manifest test and the placeholder still in Task 6.
4. **Fonts not yet loaded when a frame is captured**: the first rendered frame must use Noto Naskh / Reem Kufi, not a fallback font. Pinned by the frame-0 still in Task 1.
5. **Talia or a bubble drifting over a Quran or azkar screenshot** when timings are edited later: pinned by the `layout.ts` non-overlap test in Task 8, which reads the real scene→screen mapping.

---

### Task 1: Scaffold project, asset sync, fonts, empty composition

**Files:**
- Create (via scaffold): `marketing/promo_video/` (`package.json`, `tsconfig.json`, `remotion.config.ts`, `src/index.ts`, `src/Root.tsx`)
- Create: `marketing/promo_video/.gitignore`, `marketing/promo_video/scripts/sync-assets.mjs`, `marketing/promo_video/src/fonts.ts`, `marketing/promo_video/src/theme.ts`, `marketing/promo_video/src/TaliaPromo.tsx`, `marketing/promo_video/vitest.config.ts`
- Test: `marketing/promo_video/test/sync-assets.test.ts`

**Interfaces:**
- Produces: `theme.ts` exports `COLORS` (the brand colors above plus `ink '#10231F'`, `paper '#FFFDF7'`) and `FONTS = { heading: 'ReemKufi', body: 'NotoNaskhArabic' } as const`.
- Produces: `fonts.ts` exports `ensureFontsLoaded(): Promise<void>` (idempotent, loads 3 files via `@remotion/fonts` `loadFont`).
- Produces: `TaliaPromo: React.FC` registered in `Root.tsx` as composition id `TaliaPromo` with the global constraint values.
- Produces: `npm run sync-assets` copies `../../assets/talia/*.png` → `public/talia/` and the three font files → `public/fonts/`. `predev`, `prestill`, and `prerender` hooks call it.

- [ ] **Step 1:** Confirm `marketing/` is empty except OS metadata, then scaffold in a subfolder: `cd marketing && npx create-video@latest --yes --blank --no-tailwind promo_video && cd promo_video && npm i`. Then `npx remotion add @remotion/fonts @remotion/media` and `npm i -D vitest`.
- [ ] **Step 2:** Write `.gitignore` containing `node_modules/`, `out/`, `public/talia/`, `public/fonts/`.
- [ ] **Step 3: Write the failing test** `test/sync-assets.test.ts`:

```ts
import {execSync} from 'node:child_process';
import {readdirSync} from 'node:fs';
import {test, expect} from 'vitest';

test('sync-assets copies the 10 approved poses and 3 fonts', () => {
  execSync('node scripts/sync-assets.mjs');
  expect(readdirSync('public/talia').sort()).toEqual([
    'talia_celebrate.png','talia_encourage.png','talia_happy.png','talia_idle.png',
    'talia_listening.png','talia_point_right.png','talia_reading_quran.png',
    'talia_speaking.png','talia_thinking.png','talia_wave.png',
  ]);
  expect(readdirSync('public/fonts').sort()).toEqual([
    'NotoNaskhArabic-Bold.ttf','NotoNaskhArabic-Regular.ttf','ReemKufi-Variable.ttf',
  ]);
});
```

- [ ] **Step 4:** Run `npx vitest run test/sync-assets.test.ts`. Expected: FAIL (script missing).
- [ ] **Step 5:** Implement `scripts/sync-assets.mjs` with `fs.cpSync`. It byte-copies (no transforms), paths resolve relative to the script file, and it exits non-zero if any source is missing. Add `"sync-assets"`, `"predev"`, `"prestill"`, `"prerender"`, and `"test": "vitest run"` to `package.json` scripts.
- [ ] **Step 6:** Run `npx vitest run test/sync-assets.test.ts`. Expected: PASS.
- [ ] **Step 7:** Implement `theme.ts` and `fonts.ts`. `TaliaPromo` renders a `primaryDark` full-frame `AbsoluteFill` with the heading «تالية» in `FONTS.heading`, 120px, `dir="rtl"`, centered. `Root.tsx` gates on fonts using `delayRender`/`continueRender` around `ensureFontsLoaded()`.
- [ ] **Step 8:** Run `npx tsc --noEmit && npx remotion still TaliaPromo out/t1-frame0.png --frame=0`. Expected: no TS errors, and the PNG shows «تالية» in Reem Kufi with connected letters, not a system fallback. Inspect the image.
- [ ] **Step 9:** Start Studio in the background with `npx remotion studio --no-open` and open its URL in the built-in browser pane for the owner.
- [ ] **Step 10:** Commit (with go-ahead): `git add marketing/promo_video && git commit -m "feat(promo): scaffold Remotion project for Talia promo video"`.

---

### Task 2: Timeline data (`timeline.ts`)

**Files:**
- Create: `marketing/promo_video/src/timeline.ts`
- Test: `marketing/promo_video/test/timeline.test.ts`

**Interfaces:**
- Produces:

```ts
export const FPS = 30;
export type TaliaPose = 'celebrate'|'encourage'|'happy'|'idle'|'listening'|'point_right'|'reading_quran'|'speaking'|'thinking'|'wave';
export type TimeOfDay = 'night'|'fajr'|'morning'|'duha'|'asr'|'maghrib';
export type ScreenId = 'S1'|'S2'|'S3'|'S4'|'S5'|'S6'|'S7'|'S8'|'S9'|'S10';
export type SceneId = 'hook'|'fajr'|'morning'|'hifz'|'kids'|'maghrib'|'night'|'trust'|'cta';
export type Cue<T> = { at: number; value: T };            // `at` = scene-local frame
export type SceneSpec = {
  id: SceneId; name: string; durationInFrames: number;
  sky: [TimeOfDay, TimeOfDay];                               // sky at scene start, at scene end
  poses: Cue<TaliaPose>[];                                   // first cue at 0
  bubbles: Cue<string>[];                                    // first cue at 0
  screens: ScreenId[];
};
export const SCENES: readonly SceneSpec[];
export const TOTAL_FRAMES: number;                           // sum of durations
export function sceneStart(id: SceneId): number;
export function sceneAt(frame: number): { scene: SceneSpec; local: number };  // clamps to [0, TOTAL_FRAMES-1]
export function cueAt<T>(cues: Cue<T>[], local: number): { current: T; previous: T | null; since: number };
```

- [ ] **Step 1: Write the failing tests** in `test/timeline.test.ts`:
  - `durations match spec`: `SCENES.map(s => s.durationInFrames)` equals `[150,270,300,420,420,360,360,180,180]`, and `TOTAL_FRAMES === 2640`.
  - `scene starts match spec`: `sceneStart('fajr')===150`, `'morning'===420`, `'hifz'===720`, `'kids'===1140`, `'maghrib'===1560`, `'night'===1920`, `'trust'===2280`, `'cta'===2460`.
  - `sceneAt boundaries`: `sceneAt(149).scene.id==='hook'`, `sceneAt(150)` gives `{scene.id:'fajr', local:0}`, `sceneAt(2639).scene.id==='cta'`, `sceneAt(5000).scene.id==='cta'`, `sceneAt(-1).scene.id==='hook'`.
  - `poses match spec`: the pose sequence per scene is `hook:[wave]`, `fajr:[point_right]`, `morning:[happy]`, `hifz:[listening,encourage]`, `kids:[celebrate]`, `maghrib:[reading_quran]`, `night:[celebrate,happy]`, `trust:[thinking,speaking]`, `cta:[wave]`.
  - `bubble copy is verbatim from spec`: assert each scene's bubble strings `toEqual` the exact spec §4 strings, including the «…» ellipsis character U+2026, e.g. hifz `['سمِّع لي… أنا أستمع','أحسنت! وسأذكّرك بالمراجعة قبل أن تنسى']`.
  - `screens match spec`: `fajr:['S1']`, `morning:['S2','S3']`, `hifz:['S4','S5']`, `kids:['S6','S7']`, `maghrib:['S8','S9']`, `night:['S10']`, and `[]` for the others.
  - `sky`: `hook:['night','fajr']`, `fajr:['fajr','fajr']`, `morning:['morning','morning']`, `hifz:['duha','duha']`, `kids:['asr','asr']`, `maghrib:['maghrib','maghrib']`, `night`, `trust`, and `cta` all `['night','night']`.
  - `cueAt`: with cues `[{at:0,value:'a'},{at:200,value:'b'}]`, `cueAt(c,199)` gives `{current:'a', previous:null, since:199}`, and `cueAt(c,210)` gives `{current:'b', previous:'a', since:10}`.
- [ ] **Step 2:** Run `npx vitest run test/timeline.test.ts`. Expected: FAIL (module missing).
- [ ] **Step 3:** Implement `timeline.ts`. Two-cue scenes switch at the scene's midpoint: hifz at 210, night at 180, trust at 90. Pose and bubble switch on the same frame.
- [ ] **Step 4:** Run `npx vitest run test/timeline.test.ts`. Expected: PASS.
- [ ] **Step 5:** Commit (with go-ahead): `feat(promo): add scene timeline data`.

---

### Task 3: Text utilities (graphemes and digits)

**Files:**
- Create: `marketing/promo_video/src/text/graphemes.ts`, `marketing/promo_video/src/text/digits.ts`
- Test: `marketing/promo_video/test/text.test.ts`

**Interfaces:**
- Produces: `revealGraphemes(text: string, progress: number): string`. It returns the first `round(progress * graphemeCount)` grapheme clusters (`Intl.Segmenter('ar', {granularity: 'grapheme'})`), with progress clamped to [0,1].
- Produces: `toArabicDigits(s: string): string`. It maps `0-9` → `٠-٩` and leaves everything else unchanged.

- [ ] **Step 1: Write the failing tests:**
  - `revealGraphemes('سمِّع', 1) === 'سمِّع'` and `revealGraphemes('سمِّع', 0) === ''`.
  - For every `p` in `0, 0.05, …, 1` over `'سمِّع لي… أنا أستمع'`, the result never ends with a combining mark: `!/[ً-ْٰ]$/.test(r)`.
  - For the same loop, the result is always a prefix of the input and its length is non-decreasing in `p`.
  - `revealGraphemes('abc', 1.7) === 'abc'` and `revealGraphemes('abc', -1) === ''`.
  - `toArabicDigits('04:52') === '٠٤:٥٢'` and `toArabicDigits('يوم 7') === 'يوم ٧'`.
- [ ] **Step 2:** Run `npx vitest run test/text.test.ts`. Expected: FAIL.
- [ ] **Step 3:** Implement both functions.
- [ ] **Step 4:** Run `npx vitest run test/text.test.ts`. Expected: PASS.
- [ ] **Step 5:** Commit (with go-ahead): `feat(promo): add RTL-safe text reveal and Arabic digits`.

---

### Task 4: Sky backdrop

**Files:**
- Create: `marketing/promo_video/src/sky.ts`, `marketing/promo_video/src/components/SkyBackdrop.tsx`
- Test: `marketing/promo_video/test/sky.test.ts`

**Interfaces:**
- Consumes: `SCENES`, `sceneAt`, `TimeOfDay` (Task 2).
- Produces: `SKY: Record<TimeOfDay, {top: string; bottom: string}>` with exactly these values:
  - `night {#0A1630, #1B2A4A}`
  - `fajr {#3A4A7A, #F2B880}`
  - `morning {#8EC5E8, #E8F4FA}`
  - `duha {#6FB7E6, #D9F0FB}`
  - `asr {#F2C27B, #F7E3B5}`
  - `maghrib {#C8553D, #2B2D5C}`
- Produces: `skyAt(frame: number): {top: string; bottom: string}`. Within a scene it interpolates `sky[0]`→`sky[1]` over the scene. Across a scene boundary it blends the previous scene's end sky into the next scene's start sky over the first 20 frames of the new scene. It uses `interpolateColors` from `remotion`.
- Produces: `<SkyBackdrop />`, a full-frame linear gradient from `skyAt(useCurrentFrame())`, plus soft stars at opacity ≤0.6 when the time of day is `night` or `fajr`. The stars use deterministic positions from `random('star-i')`.

- [ ] **Step 1: Write the failing tests:**
  - `skyAt(0)` equals `SKY.night` (string compare after normalizing to `rgba(...)` via `interpolateColors(0,[0,1],[c,c])`).
  - `skyAt(149)` is close to `SKY.fajr`.
  - `skyAt(1560+20)` equals the normalized `SKY.maghrib`.
  - `skyAt(1560+10)` is neither `asr` nor `maghrib` (mid-blend).
  - `skyAt(2639)` equals the normalized `SKY.night`.
- [ ] **Step 2:** Run `npx vitest run test/sky.test.ts`. Expected: FAIL.
- [ ] **Step 3:** Implement `sky.ts` and `SkyBackdrop.tsx`. Mount `<SkyBackdrop/>` as the first child of `TaliaPromo`, replacing the Task 1 background.
- [ ] **Step 4:** Run `npx vitest run test/sky.test.ts`. Expected: PASS. Then run `npx remotion still TaliaPromo out/t4-%s.png` at frames `75, 1200, 1700, 2500`. Expected: night→fajr glow, warm asr, maghrib red-violet, starry night. Inspect each image.
- [ ] **Step 5:** Commit (with go-ahead): `feat(promo): add time-of-day sky backdrop`.

---

### Task 5: Talia layer and speech bubble

**Files:**
- Create: `marketing/promo_video/src/layout.ts`, `marketing/promo_video/src/components/Talia.tsx`, `marketing/promo_video/src/components/SpeechBubble.tsx`
- Modify: `marketing/promo_video/src/TaliaPromo.tsx` (add both global layers above the scene series)
- Test: `marketing/promo_video/test/layout.test.ts`

**Interfaces:**
- Consumes: `sceneAt`, `cueAt`, `TaliaPose` (Task 2), `revealGraphemes` (Task 3), `COLORS`, `FONTS` (Task 1).
- Produces in `layout.ts`:

```ts
export type Rect = {x: number; y: number; w: number; h: number};
export const TALIA_RECT: Rect = {x: 1440, y: 300, w: 420, h: 760};     // right corner, feet near bottom edge
export const BUBBLE_RECT: Rect = {x: 1000, y: 110, w: 720, h: 240};   // above-left of Talia, inside safe area
export const PHONE_RECT_SINGLE: Rect = {x: 140, y: 90, w: 450, h: 900};
export const PHONE_RECT_PAIR: [Rect, Rect] = [{x: 140, y: 180, w: 400, h: 800}, {x: 580, y: 140, w: 400, h: 800}];
export const DRAWN_RECT: Rect = {x: 660, y: 400, w: 720, h: 600};     // where drawn elements live
export function intersects(a: Rect, b: Rect): boolean;
```

- Produces: `<Talia />` (global, reads the frame). It shows the current pose from `cueAt(scene.poses, local)`:
  - Entry at video frame 0: spring from `translateY 120px, opacity 0` to rest over 20 frames.
  - On a pose change: cross-fade previous→current over 8 frames with a scale overshoot `1→1.04→1` over 12 frames.
  - Idle sway: `rotate = 1.5deg * sin(frame/18)` and `translateY = 6px * sin(frame/14)`.
  - Uses `<Img>` with `staticFile('talia/talia_<pose>.png')`, `objectFit: contain`, and fills `TALIA_RECT`.
- Produces: `<SpeechBubble />` (global) inside `BUBBLE_RECT`:
  - `paper` fill, 2px `gold` border, radius 36, and a tail pointing down-right toward Talia.
  - Text uses `FONTS.body` 52px bold, color `ink`, `dir="rtl"`, `text-align: right`, line-height 1.5, wrapping.
  - On each bubble cue: the bubble pops in (scale 0.85→1 spring, 10 frames), then text reveals with `revealGraphemes(text, (since-6)/typingFrames)`, where `typingFrames = max(24, graphemes*1.6)`.
  - In the last 12 frames of a cue (before the next cue or the scene end) the bubble scales to 0.9 and fades to 0.
  - Bubble height is fixed at `BUBBLE_RECT.h` so wrapped text never pushes layout.

- [ ] **Step 1: Write the failing tests** in `test/layout.test.ts`:
  - `intersects` truth table: overlapping, edge-touching (=false), contained, and disjoint cases.
  - `BUBBLE_RECT` and `DRAWN_RECT` lie inside the safe area: `x ≥ 140`, `y ≥ 100`, `x+w ≤ 1780`, `y+h ≤ 980`. `TALIA_RECT` only has to lie within the 1920×1080 frame, since it is an image, not key text.
  - None of these pairs intersect: `PHONE_RECT_SINGLE`, `PHONE_RECT_PAIR[0]`, and `PHONE_RECT_PAIR[1]` against `BUBBLE_RECT`, `TALIA_RECT`, and `DRAWN_RECT`; `DRAWN_RECT` against `BUBBLE_RECT` and `TALIA_RECT`; `PHONE_RECT_PAIR[0]` against `PHONE_RECT_PAIR[1]`.
- [ ] **Step 2:** Run `npx vitest run test/layout.test.ts`. Expected: FAIL.
- [ ] **Step 3:** Implement `layout.ts`, then `Talia.tsx` and `SpeechBubble.tsx`, and mount both in `TaliaPromo` above where the scene `<Series>` will go.
- [ ] **Step 4:** Run `npx vitest run test/layout.test.ts`. Expected: PASS.
- [ ] **Step 5:** Render end-of-typing stills for the three longest bubbles: frame `720+200` (hifz cue 2 near its end), `2280+170` (trust cue 2), and `100` (hook). Expected for each:
  - The text is fully inside the bubble with no clipping.
  - Arabic letters are connected and shadda/kasra sit on the right letters.
  - Talia is unclipped in the right corner.

  If a line overflows, reduce the font to 46px. Never shorten the copy.
- [ ] **Step 6:** Commit (with go-ahead): `feat(promo): add Talia layer and RTL speech bubble`.

---

### Task 6: Phone frame and screenshots (with placeholders)

**Files:**
- Create: `marketing/promo_video/src/screens.ts`, `marketing/promo_video/src/components/PhoneFrame.tsx`, `marketing/promo_video/src/components/ScreenImage.tsx`, `marketing/promo_video/public/screens/README.md`
- Test: `marketing/promo_video/test/screens.test.ts`

**Interfaces:**
- Consumes: `ScreenId` (Task 2), `Rect` (Task 5).
- Produces:

```ts
export const SCREENS: Record<ScreenId, {file: string; label: string; available: boolean}>;
// file = `screens/${id}.png`; label = the Arabic screen name from spec §5; available=false until the owner drops the PNG in
```

- `<ScreenImage id={ScreenId} />` renders `<Img src={staticFile(file)}>` with `objectFit: cover` when `available`. Otherwise it renders a `primaryDark` placeholder showing the id and label in `FONTS.body`.
- `<PhoneFrame rect={Rect} enterAt={number} style?>` has a rounded 56px body with 14px dark bezel, a notch, and a soft shadow, and slides in from below over 18 frames with a spring starting at the scene-local `enterAt`. Children are clipped to the screen area.
- `public/screens/README.md` lists the S1–S10 requirements copied from spec §5 and says to flip `available` in `screens.ts` after adding a file.

- [ ] **Step 1: Write the failing tests:**
  - `Object.keys(SCREENS)` equals `['S1',…,'S10']`.
  - Every `file` matches `/^screens\/S\d+\.png$/`.
  - Every screen marked `available: true` exists on disk (`existsSync('public/'+file)`). This guards against a flag flipped without a file.
- [ ] **Step 2:** Run `npx vitest run test/screens.test.ts`. Expected: FAIL.
- [ ] **Step 3:** Implement the three files with all `available: false`.
- [ ] **Step 4:** Run `npx vitest run test/screens.test.ts`. Expected: PASS. Register a temporary `Folder name="Elements"` composition `PhoneFrameDemo` (450×900 phone on `primaryDark`, `ScreenImage id="S8"`), then run `npx remotion still PhoneFrameDemo out/t6.png --frame=30`. Expected: the placeholder shows «S8» and its label, framed correctly.
- [ ] **Step 5:** Commit (with go-ahead): `feat(promo): add phone frame and screenshot placeholders`.

---

### Task 7: Drawn elements

**Files:**
- Create in `marketing/promo_video/src/components/drawn/`: `PrayerTimesCard.tsx`, `TasbeehCounter.tsx`, `MasteryMeter.tsx`, `KhatmahRing.tsx`, `StreakFlame.tsx`, `OfflineSyncBadge.tsx`, `EndCard.tsx`
- Modify: `marketing/promo_video/src/Root.tsx` (register each under `<Folder name="Elements">`)

**Interfaces:**
- Consumes: `toArabicDigits` (Task 3), `COLORS`, `FONTS` (Task 1).
- Produces: each component takes `{progress: number}` (0..1, the caller computes it) plus `style?`, and contains no Quran or azkar text:
  - `PrayerTimesCard`: five rows, «الفجر ٤:٥٢», «الظهر ١١:٥٨», «العصر ٣:١٥», «المغرب ٥:٤١», «العشاء ٦:٥٨». The Fajr row is highlighted in gold, and a bell icon wiggles while `progress` ∈ [0.4, 0.7]. Rows stagger in. Times are illustrative.
  - `TasbeehCounter`: a circular bead counter that counts `0→33` as `progress` goes 0→1, with Eastern digits and a gold ring fill. No dhikr wording, only the number.
  - `MasteryMeter`: a horizontal bar `0→87%` labelled «نسبة الإتقان» plus three small «مراجعة» calendar dots lighting up in sequence.
  - `KhatmahRing`: a ring `0→65%` labelled «خطة الختمة» with «٦٥٪» in the center.
  - `StreakFlame`: a flame that scales with `progress`, the count «٣٠ يوم», and an XP chip counting `0→1250` as «١٬٢٥٠ نقطة».
  - `OfflineSyncBadge`: a crossed-wifi icon «بلا اتصال» (progress 0–0.5) that morphs into a cloud-check icon «مزامنة» (0.5–1).
  - `EndCard`: the logo text «تالية» (Reem Kufi, 160px, gold), the tagline «رفيقك في رحاب القرآن», the line «اقرأ · احفظ · راجع · انمُ», and a drawn «Google Play» pill. Use a neutral "Get it on Google Play"-style pill, not the trademarked badge artwork, unless the owner supplies the official badge file.
- Each element is registered as a 600×600 composition (EndCard is 1920×1080) with `durationInFrames=60` and maps `progress = frame/59`.

- [ ] **Step 1:** Implement the seven components and their element compositions.
- [ ] **Step 2:** Run `npx tsc --noEmit`. Expected: no errors.
- [ ] **Step 3:** Run `npx remotion still <Id> out/t7-<Id>.png --frame=59` for each of the seven. Expected: final states show Eastern digits, connected Arabic, nothing clipped, and only the copy listed above. Inspect each image.
- [ ] **Step 4:** Commit (with go-ahead): `feat(promo): add drawn feature elements`.

---

### Task 8: Scenes and full assembly

**Files:**
- Create in `marketing/promo_video/src/scenes/`: `Scene0Hook.tsx`, `Scene1Fajr.tsx`, `Scene2Morning.tsx`, `Scene3Hifz.tsx`, `Scene4Kids.tsx`, `Scene5Maghrib.tsx`, `Scene6Night.tsx`, `Scene7Trust.tsx`, `Scene8Cta.tsx`, and `sceneLayout.ts`
- Modify: `marketing/promo_video/src/TaliaPromo.tsx`, `marketing/promo_video/src/Root.tsx`
- Test: `marketing/promo_video/test/scene-layout.test.ts`

**Interfaces:**
- Consumes: everything above.
- Produces: `sceneLayout.ts` exports `SCENE_PHONES: Record<SceneId, {screen: ScreenId; rect: Rect; enterAt: number}[]>`. This is the single source each scene component reads for phone placement:
  - `fajr`: S1 single at 90.
  - `morning`: S2 single at 0, then S3 replacing it at 150.
  - `hifz`: S4 single at 0 (with an audio-wave overlay *beside* the phone, not on it), then S5 at 210.
  - `kids`: S6 and S7 as a pair at 0 and 30.
  - `maghrib`: S8 single at 0, then S9 at 180.
  - `night`: S10 single at 180.
- Produces: each scene component renders only its own content, using `SCENE_PHONES` plus the drawn elements per spec §4:
  - hook: the gold logo forms from 0–120.
  - fajr: `PrayerTimesCard` 0–90, then a notification slides in at 60.
  - morning: `TasbeehCounter` beside the phone.
  - hifz: `MasteryMeter` after 210.
  - kids: a dashed gold connector line between the two phones.
  - maghrib: `KhatmahRing` after 180.
  - night: `StreakFlame` 0–180.
  - trust: `OfflineSyncBadge`.
  - cta: `EndCard`.

  Drawn elements (including the hifz audio wave and the fajr notification) are placed inside `DRAWN_RECT`. The hook logo and `EndCard` are exempt because no phone is on screen in those scenes.
- `TaliaPromo` renders `<SkyBackdrop/>`, then `<Series>` with nine `<Series.Sequence name=… durationInFrames={SCENES[i].durationInFrames} premountFor={fps}>`, then `<Talia/>` and `<SpeechBubble/>`.
- `Root.tsx` registers each scene as a connected composition under `<Folder name="Scenes">` with its own duration.

- [ ] **Step 1: Write the failing tests** in `test/scene-layout.test.ts`:
  - For every scene, the screens in `SCENE_PHONES` equal `SCENES` screens (same ids, same order).
  - **Content guard:** for every phone entry with `screen ∈ {'S2','S8'}`, `intersects(rect, TALIA_RECT) === false` and `intersects(rect, BUBBLE_RECT) === false`.
  - Every phone rect lies within the 1920×1080 frame.
  - **Source guard:** no file under `src/` contains a character in U+06D6–U+06ED (Quranic annotation marks) or the strings `بسم الله` / `ﷺ`. Read the files with `fs.readdirSync(…, {recursive: true})`.
- [ ] **Step 2:** Run `npx vitest run test/scene-layout.test.ts`. Expected: FAIL.
- [ ] **Step 3:** Implement `sceneLayout.ts`, the nine scenes, and the assembly.
- [ ] **Step 4:** Run `npm test` (all suites). Expected: PASS.
- [ ] **Step 5:** Run `npx remotion still TaliaPromo out/t8-<frame>.png` at the midpoint of every scene: `75, 285, 570, 930, 1350, 1740, 2100, 2370, 2550`. Expected in each:
  - The visuals match spec §4.
  - No element overlaps a phone showing S2 or S8.
  - Nothing important falls outside the safe area.

  Inspect each image, then show the owner the Studio preview.
- [ ] **Step 6:** Commit (with go-ahead): `feat(promo): assemble nine scenes into TaliaPromo`.

---

### Task 9: Sound effects with provenance

**Files:**
- Create: `marketing/promo_video/public/sfx/*.wav`, `marketing/promo_video/public/sfx/CREDITS.md`, `marketing/promo_video/src/components/SfxTrack.tsx`
- Modify: `marketing/promo_video/src/TaliaPromo.tsx`
- Test: `marketing/promo_video/test/sfx.test.ts`

**Interfaces:**
- Produces: `SfxTrack` holds a list of `<Audio>` elements (`@remotion/media`), each with an inline `from` and `volume` ≤0.35:
  - soft whoosh at each scene start except hook;
  - soft pop on each bubble cue;
  - gentle chime at fajr 60 (notification) and at night 180 (certificate);
  - soft page-turn at maghrib 0.

  No music and no adhan or recitation audio.
- `CREDITS.md` has one row per file: file name, source URL, author, license (must be CC0 or a license allowing commercial use without attribution conflicts), and date fetched.

- [ ] **Step 1: Write the failing test:** every `.wav` in `public/sfx/` has a row in `CREDITS.md` whose license cell is non-empty, and every row's file exists.
- [ ] **Step 2:** Run `npx vitest run test/sfx.test.ts`. Expected: FAIL (CREDITS missing).
- [ ] **Step 3:** Ask the owner before downloading anything, stating file names, source, and size. Download only files whose license can be verified on the source page, and fill in `CREDITS.md`. If none can be verified, ship `SfxTrack` empty and say so.
- [ ] **Step 4:** Implement `SfxTrack` and mount it in `TaliaPromo`.
- [ ] **Step 5:** Run `npm test`. Expected: PASS. Scrub the timeline in Studio with sound on. Expected: effects land on the cues and nothing is louder than the pop.
- [ ] **Step 6:** Commit (with go-ahead): `feat(promo): add licensed sound effects`.

---

### Task 10: Final verification and handoff

- [ ] **Step 1:** Run `npx tsc --noEmit && npm test`. Expected: 0 errors and all suites PASS. Record the counts.
- [ ] **Step 2:** Re-run the Task 8 midpoint stills and the Task 5 bubble stills. Verify the Review Focus items 1–5 by eye and note any deviation.
- [ ] **Step 3:** Confirm the Composition `TaliaPromo` reports 2640 frames at 30fps in Studio.
- [ ] **Step 4:** Report to the owner:
  - which screenshots are still placeholders;
  - the Studio URL;
  - the render command for when they want the MP4: `npx remotion render TaliaPromo out/talia-promo.mp4 --codec=h264`;
  - the thumbnail command: `npx remotion still TaliaPromo out/thumbnail.png --frame=2600`.

  Do not render the MP4 unless asked.
