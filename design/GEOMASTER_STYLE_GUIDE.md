# GeoMaster — Visual Style Guide for AI Coding Agents (v1.0)

> Hand this file to the coding agent together with `design_tokens.json` and `geomaster_theme.dart`.
> It describes the approved look of GeoMaster as designed on the Design canvas
> ("v2 · Game show" + "Hall of Legends" are the primary direction; "v1 · Playful" is the light theme).
> Treat every hex value, size and rule here as a spec. Do not invent new colours, fonts or icon styles.

---

## 0. Rules the agent must follow

1. **Use tokens, never raw values.** All colours, radii, spacing, shadows and text styles come from
   `GeoColors`, `GeoRadii`, `GeoSpace`, `GeoText` in `geomaster_theme.dart` (generated from `design_tokens.json`).
2. **Two themes:** `GeoTheme.dark()` = **Game show** (default, primary). `GeoTheme.light()` = **Playful** (light mode).
   Both share the same brand colours; only surfaces, text and fonts change.
3. **Teal `#19B891` and Gold `#F4C35C` are fills, not text on light backgrounds** (they fail contrast).
   On light surfaces use `tealInk #0B7A5F` for teal text. On dark surfaces teal and gold text are fine.
4. **Never rely on colour alone.** Correct = teal + check icon + the word. Incorrect = orange `#C2410C` + cross icon + the word.
   Mastery statuses always have an icon and a label.
5. **No emoji as UI icons.** Icons are 24×24 rounded-stroke line icons (stroke 2–2.4, round caps/joins). Use one icon set (e.g. Lucide/Phosphor "regular") consistently.
6. **Touch targets ≥ 44×44 dp.** Primary buttons 56–68 dp tall.
7. **Respect "Reduce motion"**: replace bounces, rays rotation and confetti with simple fades.
8. **Skill badges, ranks and legend trophies are never shown with a price.** Only cosmetics carry GeoPoints prices.
9. Text styles scale with the system font size; never fix line heights so tight that 130 % text clips.
10. Placeholder content must be visibly labelled (e.g. `[SOURCED VALUE]`, "Placeholder shape").

---

## 1. Brand

| Item | Value |
|---|---|
| Name | **GeoMaster** (wordmark in caps on the game-show theme: `GEOMASTER`) |
| Tagline | **Master the World — X/195** (X = countries mastered) |
| Emblem | Teal globe (`#19B891`) with navy continents, inside a navy disc with an 8 px gold ring and a dotted outer gold orbit |
| Mascot | **Pip** — a teal map-pin with a white face, big navy eyes, gold cheeks. Used for onboarding, empty states and tips. Never replaced by a third-party character |
| Personality | Game-show energy, warm, encouraging, never mocking. Short, upbeat copy |

---

## 2. Colour

### 2.1 Core brand
| Token | Hex | Use |
|---|---|---|
| `navy` | `#12243B` | World Navy. Primary surface (dark), primary text (light) |
| `navyDeep` | `#0A1626` | Deepest stage, nav bar, inset wells, chips on dark |
| `navyRaised` | `#1D3A5F` | Top of answer-bar / plate gradients |
| `navyLine` | `#2A3F5C` | Hairlines, inactive rings, track backgrounds on dark |
| `stageGlow` | `#23436B` | Centre of the spotlight radial gradient |
| `teal` | `#19B891` | Correct, progress, "practicing", secondary CTA, active tab (light) |
| `tealInk` | `#0B7A5F` | Teal text/border on light surfaces (5.3:1 on white) |
| `tealSoft` | `#E6F7F1` | Teal tint backgrounds (light theme) |
| `gold` | `#F4C35C` | Rewards, primary CTA, frames, "mastered", active nav |
| `goldLight` | `#FFD983` | Top of gold button gradient |
| `goldHighlight` | `#FFE09A` | Gold frame highlights |
| `goldDeep` | `#E2A93A` | Bottom of gold button gradient |
| `goldShadow` | `#A9761F` | 3D drop under gold buttons |
| `offWhite` | `#F7F9FC` | Light surface; primary text on dark |

### 2.2 Text on dark (game show)
`textPrimary #F7F9FC` · `textSecondary #C9D4E3` · `textTertiary #9FB0C6` · `textDisabled #7F90A8`

### 2.3 Text & lines on light (playful)
`textPrimary #12243B` · `textSecondary #3D506A` · `border #DCE3EC` · `divider #EEF2F7` · `track #E2E8F0` · `surface #FFFFFF`

### 2.4 Feedback
| Token | Hex | Use |
|---|---|---|
| `alert` | `#C2410C` | Incorrect answer fill/border, destructive text |
| `alertBright` | `#E2603B` | Incorrect gradient top, streak flame |
| `alertSoft` | `#FDEDE6` | Incorrect tint (light) |
| `alertRing` | `#FFB08F` | Outline of incorrect bar on dark |
| `correctRing` | `#7FF0C9` | Outline of correct bar on dark |
| `correctTop` | `#2FD3A6` | Correct gradient top |

### 2.5 Mastery status (always icon + label)
| Status | Colour | Icon |
|---|---|---|
| mastered | `gold` | crown |
| practicing | `teal` | half-filled circle |
| learning | `navy` (on light) | ring with dot |
| not_started | `#DCE3EC` dashed outline | dashed circle |

### 2.6 Trophy tiers
| Tier | Light | Dark | Icon ink |
|---|---|---|---|
| bronze | `#D49A5C` | `#8E5A2B` | `#E6B07A` |
| silver | `#DDE3EA` | `#8B97A4` | `#DDE3EA` |
| gold | `#FFD983` | `#B9862A` | `#F4C35C` |
| locked | `#2A3F5C` | `#1B2B40` | `#7F90A8` |

### 2.7 Signature gradients
- **Stage background (dark):** `radial-gradient(120% 70% at 50% 30%, #23436B 0%, #12243B 55%, #0A1626 100%)`
- **Spotlight rays overlay:** repeating conic, `rgba(255,255,255,0.035)` 7° on / 7° off, centred at the same point as the stage glow. Static when reduce-motion is on; otherwise may rotate very slowly (≥ 60 s per turn).
- **Gold button:** vertical `#FFD983 → #F4C35C (55%) → #E2A93A`, plus a solid `0 6 0 #A9761F` drop.
- **Gold frame:** 135° `#FFE09A → #F4C35C (40%) → #A9761F`, 2.5–4 px wide.
- **Answer bar fill:** vertical `#1D3A5F → #0F2034`.
- **Correct screen stage:** stage gradient with centre `#1E6B66`; **Incorrect stage:** centre `#6B3324`; **Unlock stage:** centre `#6A5320`.

---

## 3. Typography

| Theme | Display / headings | Body |
|---|---|---|
| Game show (dark, primary) | **Source Sans 3** 900, UPPERCASE, letter-spacing 1–3 px | Source Sans 3 600/700 |
| Playful (light) | **Fredoka** 600/700 | **Nunito** 600/700/800 |

(Source Sans 3 is the free stand-in for Myriad Pro. Bundle fonts locally via `google_fonts` or assets; do not load at runtime in production.)

### Type scale (dp / weight / tracking)
| Style | Size | Weight | Tracking | Case |
|---|---|---|---|---|
| `display` | 40–44 | 900 | 2 | UPPER |
| `title` | 28–34 | 900 | 1–3 | UPPER |
| `section` | 19–22 | 900 | 1–2 | UPPER |
| `question` | 19 | 700 | 0 | Sentence |
| `answer` | 17–19 | 700 | 0 | As written; letter prefix `A:` in 900 gold |
| `body` | 15 | 600 | 0 | Sentence, line-height 1.45 |
| `button` | 15–20 | 900 | 1.5–3 | UPPER |
| `label` | 12–13 | 900 | 1–2 | UPPER |
| `caption` | 12 | 700 | 0 | Sentence |

Numbers in scoreboards/timers use 900 weight (tabular figures if available).

---

## 4. Shape, spacing, elevation

### 4.1 The hex plate (signature shape)
Elongated hexagon with pointed left/right ends — used for titles, the question panel, answer bars, rank-ladder rows, results banners.
```
polygon( p 0,  W-p 0,  W H/2,  W-p H,  p H,  0 H/2 )   // p = point inset
```
| Height | Point inset `p` |
|---|---|
| 36–48 | 12–16 |
| 56–60 | 16–18 |
| 72–96 | 22–24 |
Framed variant = gold outer plate + inner plate inset 2.5–3 px (inner `p` = outer `p` − 1/−2).
A **2 px gold rail** (`gold` at 45–70 % opacity) runs full-width behind question and answer plates, extending past the screen margins (classic quiz-show look).

### 4.2 Radii
`xs 8 · sm 12 · md 16 · lg 20 · xl 24 · xxl 28 · pill 999` (cards 20–24, tiles 18–22, sheets 30–32 top corners)

### 4.3 Spacing
4-pt grid: `4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40`. Screen side margin **18** (game show) / **20** (playful). Default vertical gap between blocks **12–14**.

### 4.4 Elevation (no blur-heavy shadows)
- **3D drop** (buttons/tiles): solid offset `0 4–6 0` in a darker shade (`goldShadow`, `navyDeep`, `tealInk`).
- **Glow** (selected/active): `0 0 18–30 rgba(244,195,92,.35–.6)` for gold, `rgba(25,184,145,.35–.6)` for teal.
- **Ring**: inset 2–3 px stroke (`navyLine` inactive, `gold` active, `teal` online/correct).

---

## 5. Components

### 5.1 Buttons
| Variant | Spec |
|---|---|
| **Primary (gold)** | Pill, h 56–68, gold gradient, navy 900 UPPER text, `0 6 0 goldShadow` drop; pressed: translateY 4, drop 2 |
| **Secondary (navy)** | Pill, h 50–58, `navy` fill, inset 2.5 gold ring, gold text |
| **Teal** | Pill, teal fill, navy text, drop `0 5 0 tealInk` (used for "See result", online states) |
| **Icon button** | 44–48 circle, `navy` fill, inset 2.5 gold ring, gold 20–22 icon |
| **Destructive** | Text/row in `alert` with trash icon; always confirm |

### 5.2 Answer bar (A–D)
- Framed hex plate, h 56 (single column) or 60 (2×2 grid).
- States: **default** gold ring + navy gradient + off-white text; **selected** gold fill + navy text + tag `SELECTED`;
  **correct** `correctRing` ring + teal gradient + navy text + `✓ CORRECT`; **incorrect** `alertRing` ring + orange gradient + white text + `✕ WRONG`;
  **removed (50:50)** 35 % opacity, disabled, label hidden.
- Two-step answer: tap to select → **FINAL ANSWER** (gold) → reveal → **SEE RESULT** (teal). Ranked modes may skip the lock step.

### 5.3 Question panel
Framed hex plate h 56–96, question centred, 19/700. Media above it (flag, silhouette) sits in a gold-gradient frame (r 18, 4 px) with a soft gold glow, or in a 270 px spotlight disc (teal radial, gold inset ring).

### 5.4 Lifelines (practice modes only — never in ranked/daily)
Ovals 64×44, navy fill, inset gold ring, gold icon/label: `50:50`, hint (bulb), skip. Used = 35 % opacity.

### 5.5 Timer ring
68 dp, track `navyLine` 6 px, progress `teal` round cap, number 22/900 centred. Last 5 s: progress switches to `alertBright`.

### 5.6 HUD / top bar
Back or pause icon button (left) · centred two-line title (`label` teal + `section`) · score chip right (`navyDeep`, inset 2 px gold ring, gold 900 text).
Currency chips: GeoPoints = gold coin icon; streak = flame `alertBright` with inset ring of the same colour.

### 5.7 Bottom navigation (4 tabs: Home / Learn / Compete / Profile)
Bar h 92 (incl. safe area), `navyDeep`, 2 px gold top border. Inactive: icon 24 + `label` in `textSecondary`.
Active: 56 dp gold circle raised 24 dp above the bar, navy icon, 4 px `navyDeep` separation ring + gold glow; label gold.

### 5.8 Tiles & cards
- **Mode tile:** r 22, `navy` fill, inset 2 px `navyLine` ring, `0 5 0 navyDeep` drop; centred 58 dp emblem circle (`navyDeep`, inset 3 px gold ring, gold icon) + UPPER label. Selected: gold ring + glow.
- **Category tile:** hexagon emblem 54 dp + name + 3 stars (gold fill / gold outline).
- **Framed panel:** gold-gradient border 2.5–3 px, inner r = outer − 3, inner fill stage gradient.
- **Shop item:** gold-frame card; owned = teal frame; ribbon `NEW` teal, rotated −40°.

### 5.9 Progress
- Segmented mastery bar (8 segments, teal filled / navyLine empty).
- Question dots row: 26×8 pills — teal correct, `alertBright` wrong, gold current with glow, navyLine upcoming.
- Rank ladder: 9 hex-plate rows (36 dp), top = World Master; current row gold fill + navy text; earned rows off-white text + teal "Earned"; locked rows grey + "Locked"; next row note in gold.

### 5.10 Leaderboard podium
Three trapezoid columns (2 · 1 · 3), heights 80 / 104 / 62: silver gradient, gold gradient, bronze gradient; avatars 52–66 with double rings; crown above #1; spotlight cones behind. List rows are hex plates; the player's row is gold and pinned.

### 5.11 Results screens
Big medallion (150–160 dp, gold radial disc + inner teal ✓ or orange ✕), hex banner `CORRECT!` / `NOT QUITE`, explanation card (`navyDeep` 75 %, inset ring), reward tiles (+XP, +GeoPoints, streak). Incorrect screen shows **your pick vs. answer** side by side. Confetti = small rotated rectangles in gold/teal + 4-point sparkles.

### 5.12 Avatars
Circle with initials (900), gold fill / navy text, double ring `0 0 0 3 navy, 0 0 0 5 gold`. Cosmetic frames (conic gold/teal, ocean, savanna) sit outside the ring.

---

## 6. Hall of Legends — character style

- **Look:** friendly, chibi-proportioned "3D game" busts — big round head (≈ 45 % of height), small rounded torso, large dark oval eyes with a white sparkle, soft blush cheeks, open smile, highlight top-left, soft shadow right, ground shadow ellipse. Era-appropriate hat/hair/beard/collar identify each figure.
- **Never** use real portraits, paintings or photos as the art; never caricature ethnicity. Have depictions of Ibn Battuta, Zheng He, Al-Biruni and Hypatia reviewed for cultural accuracy.
- **Locked state:** `navyDeep` silhouette with `navyLine` outline and a large `?`.
- **Pedestal:** gold radial ellipse with `0 8 0 #7A561A` drop.
- **Trophy medal:** hexagon in tier colours, navy centre disc, tier-coloured line icon, top-left gloss.

| # | Player rank | Legend | Trophy | Key visual cues |
|---|---|---|---|---|
| 1 | Tourist | Marco Polo | Traveler's Compass | Red soft cap, short brown beard, red robe |
| 2 | Traveler | Ibn Battuta | Golden Travel Journal | White turban, full dark beard, green robe |
| 3 | Explorer | Zheng He | Treasure Fleet Ship | Black Ming official's hat with side wings, red robe |
| 4 | Navigator | Ferdinand Magellan | Ocean Astrolabe | Steel morion helmet, full beard, navy doublet, ruff |
| 5 | Cartographer | Gerardus Mercator | Golden World Atlas | Black scholar's cap, long grey beard, black robe |
| 6 | Geographer | Alexander von Humboldt | Earth's Ecosystem Globe | Swept brown hair, blue coat, white cravat |
| 7 | World Expert | Al-Biruni | Celestial Globe | Blue turban, full beard, purple robe |
| 8 | Master Geographer | Eratosthenes | Golden Earth Sphere | Gold laurel, grey hair and beard, toga with green sash |
| 9 | World Master | Leonardo da Vinci | Crown of Knowledge | Purple cap, long white hair and beard, purple robe |

| Category | Guide | Nickname | Trophy | Key visual cues |
|---|---|---|---|---|
| Geography & Nature | Strabo | The Atlas Keeper | Golden Atlas | Short beard, toga with teal sash |
| History & Civilizations | Herodotus | The Timekeeper | Scroll of Ages | Curly hair, green laurel, full beard, blue sash |
| Economics & Trade | Adam Smith | The Market Sage | Golden Balance | White powdered wig, brown coat, cravat |
| Politics & World Affairs | Aristotle | The Statesman | Pillars of Wisdom | Grey hair and full beard, purple sash |
| Space & Astronomy | Galileo Galilei | The Stargazer | Celestial Telescope | Long hair, pointed beard, black robe, ruff |
| Connected World | Hypatia of Alexandria | The Knowledge Weaver | Orb of Knowledge | Hair in a bun, gold headband, teal robe |

Rules: rank legends unlock automatically at each overall rank; category guides award bronze/silver/gold for category challenges; one legend can be set as the active **mentor** (reacts to correct answers and milestones). Guide speech bubble: off-white, r `20 20 20 4`, 14/700 navy text, speaker label 12/900 `tealInk` UPPER.

---

## 7. Motion

| Moment | Animation | Duration / curve |
|---|---|---|
| Button press | translateY 4, drop shrinks | 80 ms ease-out |
| Answer select | gold fill wipe | 150 ms |
| Answer reveal | ring flash + fill crossfade, correct bar pulses once | 350 ms |
| Correct/incorrect medallion | scale 0.6 → 1.05 → 1 | 450 ms easeOutBack |
| Rays | slow rotation | ≥ 60 s/turn, off with reduce-motion |
| Legend unlock | silhouette → character crossfade + rise 16 dp + confetti | 900 ms |
| Mentor reaction | 2-frame bounce / wave | ≤ 600 ms |
Reduce motion: all of the above become 150 ms opacity fades; no confetti, no rotation.

---

## 8. Copy voice
- Labels, buttons, banners: UPPERCASE, 1–3 words (`PLAY`, `FINAL ANSWER`, `NEXT QUESTION`).
- Explanations: one or two plain sentences, friendly, factual, sourced.
- Wrong answers: never shaming — `NOT QUITE`, then a teaching tip.
- Times: always state UTC for daily resets ("resets 00:00 UTC").

---

## 9. Accessibility checklist
- Contrast ≥ 4.5:1 for text (≥ 3:1 for 24 dp+). Off-white on navy = 14:1; gold on navy ≈ 9:1; teal on navy ≈ 6:1.
- Every icon-only button has a semantic label. Flags/silhouettes have neutral descriptions that do not reveal the answer.
- Map questions provide a list-mode alternative for screen readers.
- Feedback never relies on colour only; hex-plate shapes keep a visible focus ring (draw focus outside the clip path).
- Support dynamic type to 200 % (wrap, don't truncate answer text).

---

## 10. Files in this package
| File | Purpose |
|---|---|
| `GEOMASTER_STYLE_GUIDE.md` | This specification |
| `design_tokens.json` | Machine-readable tokens (colours, type, radii, spacing, gradients, tiers, legends) |
| `geomaster_theme.dart` | Flutter starter: `GeoColors` ThemeExtension, dark/light `ThemeData`, `HexPlateClipper`, `GoldButton`, `AnswerBar` |
