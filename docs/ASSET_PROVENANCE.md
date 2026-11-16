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
| Pip, 15 legend characters, trophy medals, icons, emblem | **Not yet in the repository** (not included in the uploaded kit) | Upload the SVG files; they will be added with `ai_generated_assigned`. |
| Historical figures | No likeness rights (all died centuries ago) | Trademark search before using a name (e.g. "Leonardo da Vinci") in the app name, logo or store listing. |
| Flags (Malta, Ireland, Côte d'Ivoire, Italy, Poland, Peru, Greece) | Not yet in the repository | Generally not copyrighted; check national-symbol rules (e.g. Malta's George Cross) in the content-rights step. |
| Map and country shapes | **Placeholders only** | Replace with licensed boundary data such as Natural Earth (public domain). `country_catalog.map_shape_status` stays `missing`/`placeholder` until then. |
| Fonts: Source Sans 3, Fredoka, Nunito | SIL OFL 1.1, licence texts in `assets/fonts/licenses/` | Bundle the font files in Phase B and register the licences in the app. |
| Portraits or photos from the web | **Not used** | Never ship without a licence. |
