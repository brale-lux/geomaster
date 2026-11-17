# GeoMaster — SVG asset pack (v1.0)

124 standalone SVG files exported from the GeoMaster design canvas (Hall of Legends + v1/v2 screens).
All files are valid SVG 1.1, no external references, no embedded raster images, no fonts required
(except `characters/locked-legend-silhouette.svg`, which renders a "?" in the system sans-serif).

| Folder | Contents | Size / viewBox |
|---|---|---|
| `characters/rank-legends/` | 9 rank legends, `rank-<n>-<rank>-<name>.svg` | 400×440, viewBox 0 0 200 220 |
| `characters/category-guides/` | 7 category guides incl. Ibn Battuta "The Pathfinder" (guide outfit) | 400×440 |
| `characters/locked-legend-silhouette.svg` | Locked state | 400×440 |
| `trophies/<trophy-name>/{bronze,silver,gold}.svg` | 15 trophy medals × 3 tiers | 240×240, viewBox 0 0 120 120 |
| `trophies/locked.svg` | Locked medal | 240×240 |
| `mascot/` | Pip: wave, happy, cheer, thinking | 360×440, viewBox 0 0 180 220 |
| `brand/` | Emblem, app-icon base (square, no rounded mask — the OS applies it), small mark | various |
| `icons/line/` | 36 UI icons, 24×24, `stroke="currentColor"` (recolour freely) | 24×24 |
| `icons/color/` | 11 fixed-colour icons: GeoPoints coin, streak flame, mastery statuses, answer states, stars, sparkle | 48×48, viewBox 0 0 24 24 |
| `flags/` | 7 flags used in the mockups (ISO 3166-1 alpha-2 prefix) | 3:2 (Poland 8:5) |

`trophies/golden-world-atlas--golden-atlas/` is shared by Mercator's **Golden World Atlas** and Strabo's **Golden Atlas** (same icon).

## Usage notes for the coding agent
- Flutter: use `flutter_svg` (`SvgPicture.asset`). Line icons inherit colour via `colorFilter` / `currentColor`.
- Characters and trophies have `role="img"` + `aria-label`; still provide a `semanticsLabel` in Flutter.
- Characters sit on a transparent background with a soft ground shadow; place them on the gold pedestal from the style guide.
- These are flat vector placeholders in a "friendly 3D" style. When final 3D art is commissioned, keep the same file names so assets can be swapped 1:1.

## Accuracy & rights notes
- **Original artwork:** characters, Pip, emblem, trophies and icons were drawn for GeoMaster; they are not copies of existing artworks. Likenesses of ancient and medieval figures are imagined; have Ibn Battuta, Zheng He, Al-Biruni and Hypatia reviewed for cultural accuracy.
- **Flags are simplified mockup versions.** Malta's George Cross is a simple grey square with a white cross (the real emblem is detailed and edged in red); Peru is the civil flag (no coat of arms). Replace all flags in production with an official/public-domain flag set at correct proportions, and check national rules on commercial use of state symbols.
- No map geometry is included: the canvas map shapes were placeholders. Use licensed geometry (e.g. Natural Earth, public domain).
