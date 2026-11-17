# Asset provenance and licensing

Recorded 2026-11-16 from the owner's confirmation. This is a record of origin, not legal advice;
get legal review before launch.

## Artwork drawn with Claude Design (Anthropic)

The owner confirmed that the GeoMaster SVG artwork was drawn with Claude Design: characters, trophies,
the Pip mascot, UI icons, the emblem, flags, map shapes and the question visuals in the 520-question package.

* Anthropic's terms assign the user "all of our right, title, and interest — if any — in Outputs".
  Commercial use is therefore permitted, but copyright protection of AI-generated output is uncertain,
  so others may be able to copy it. Have an illustrator redraw or finish any art you need to protect
  (for example the production 3D characters).
* In the database this is recorded as `license_status = 'ai_generated_assigned'` with a `provenance`
  note on `question_assets` (27 question SVGs) and is available for `character_art_assets`.
* None of the drawings copy an existing character or artwork (owner's statement).

## Per asset type

| Asset | Status | Action before launch |
|---|---|---|
| 27 question SVGs (`content/assets/questions/`) | In repo, sanitised, `ai_generated_assigned` | River cards are schematic diagrams, labelled "not a geographic map". |
| Art pack in `assets/art/` (124 SVGs): 16 character busts incl. Ibn Battuta's guide outfit, locked silhouette, 15 trophy designs × 3 tiers, Pip ×4, brand marks, 47 icons | In repo, all pass the SVG safety allow-list, checksums in `assets/art/SHA256SUMS`, recorded as `ai_generated_assigned` | Interim flat art; final 3D art should keep the same file names. Cultural-accuracy edits applied to Ibn Battuta, Zheng He, Al-Biruni and Hypatia per the owner's brief (`docs/CULTURAL_ACCURACY.md`); expert review still pending. A preview sheet is in `docs/art-preview-sheet.png`. |
| Historical figures | No likeness rights (all died centuries ago) | Trademark search before using a name (e.g. "Leonardo da Vinci") in the app name, logo or store listing. |
| National flags, all 195 (`assets/flags/`) | From Wikimedia Commons at their published proportions, sanitised; per-file title, URL, licence, author and restriction tags in `assets/flags/MANIFEST.json` and `country_flag_assets`. 194 public domain, Oman under OGL-om 1.0. Contact sheet: `docs/flags-contact-sheet.png`. | Most files carry the Commons `insignia` tag (national symbol), and some carry `communist`. These are not copyright limits, but some countries restrict commercial use of state symbols, so `national_symbol_review` stays `pending` for legal review. Afghanistan uses the 2013–2021 tricolour flown at the UN (owner's decision). Refresh with `tool/fetch_flags.py`. |
| 7 mockup flags in the art pack (`assets/art/flags/`) | Design mockups only, not used by the app | Kept for reference. |
| Map and country shapes | **Not included** (the design-canvas shapes were placeholders) | Replace with licensed boundary data such as Natural Earth (public domain). `country_catalog.map_shape_status` stays `missing`/`placeholder` until then. |
| Fonts: Source Sans 3, Fredoka, Nunito | SIL OFL 1.1, licence texts in `assets/fonts/licenses/` | Bundle the font files in Phase B and register the licences in the app. |
| Portraits or photos from the web | **Not used** | Never ship without a licence. |
