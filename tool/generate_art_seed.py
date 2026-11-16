#!/usr/bin/env python3
"""Validate the GeoMaster SVG art pack and generate its seed migration + checksum manifest.

    python3 -I tool/generate_art_seed.py

Reads   assets/art/**.svg   (drawn with Claude Design; see docs/ASSET_PROVENANCE.md)
Writes  assets/art/SHA256SUMS
        supabase/migrations/20261116000760_seed_art_assets.sql
Every SVG must pass the same safety allow-list as question visuals (tool/import_questions.py).
"""
import hashlib
import importlib.util
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets/art"
OUT = ROOT / "supabase/migrations/20261116000760_seed_art_assets.sql"

spec = importlib.util.spec_from_file_location("iq", ROOT / "tool/import_questions.py")
iq = importlib.util.module_from_spec(spec)
spec.loader.exec_module(iq)

PROVENANCE = ("ai_generated:claude_design; interim flat vector art from the GeoMaster design canvas; "
              "owner confirmed 2026-11-16; final 3D art to keep the same file names")
LICENSE_NOTE = iq.ASSET_LICENSE

# Character file -> (role_type, role key). Role keys follow the v1.3 slugs.
CHARACTERS = {
    "rank-legends/rank-1-tourist-marco-polo.svg": ("rank_legend", "tourist"),
    "rank-legends/rank-2-traveler-ibn-battuta.svg": ("rank_legend", "traveler"),
    "rank-legends/rank-3-explorer-zheng-he.svg": ("rank_legend", "explorer"),
    "rank-legends/rank-4-navigator-ferdinand-magellan.svg": ("rank_legend", "navigator"),
    "rank-legends/rank-5-cartographer-gerardus-mercator.svg": ("rank_legend", "cartographer"),
    "rank-legends/rank-6-geographer-alexander-von-humboldt.svg": ("rank_legend", "geographer"),
    "rank-legends/rank-7-world-expert-al-biruni.svg": ("rank_legend", "world_expert"),
    "rank-legends/rank-8-master-geographer-eratosthenes.svg": ("rank_legend", "master_geographer"),
    "rank-legends/rank-9-world-master-leonardo-da-vinci.svg": ("rank_legend", "world_master"),
    "category-guides/guide-geography-nature-strabo.svg": ("category_guide", "geography_nature"),
    "category-guides/guide-history-civilizations-herodotus.svg": ("category_guide", "history_civilizations"),
    "category-guides/guide-economics-trade-adam-smith.svg": ("category_guide", "economics_trade"),
    "category-guides/guide-politics-world-affairs-aristotle.svg": ("category_guide", "politics_world_affairs"),
    "category-guides/guide-space-astronomy-galileo-galilei.svg": ("category_guide", "space_astronomy"),
    "category-guides/guide-connected-world-hypatia.svg": ("category_guide", "connected_world"),
    # The art pack names this file after the style guide's "Travel & Cultures"; per the owner's decision
    # the role stays on the Explorers category (spec v1.3).
    "category-guides/guide-travel-cultures-ibn-battuta-pathfinder.svg": ("category_guide", "explorers_pioneers_discoverers"),
}
# Style guide: depictions of these four need a cultural-accuracy review.
CULTURAL_REVIEW = {"ibn_battuta", "zheng_he", "al_biruni", "hypatia_of_alexandria"}

# Trophy slug (DB) -> art folder. 'golden-world-atlas--golden-atlas' is shared by design.
TROPHIES = {
    "travelers_compass": "travelers-compass", "golden_travel_journal": "golden-travel-journal",
    "treasure_fleet_ship": "treasure-fleet-ship", "ocean_astrolabe": "ocean-astrolabe",
    "golden_world_atlas": "golden-world-atlas--golden-atlas", "earths_ecosystem_globe": "earths-ecosystem-globe",
    "celestial_globe": "celestial-globe", "golden_earth_sphere": "golden-earth-sphere",
    "crown_of_knowledge": "crown-of-knowledge", "golden_atlas": "golden-world-atlas--golden-atlas",
    "scroll_of_ages": "scroll-of-ages", "golden_balance": "golden-balance", "pillars_of_wisdom": "pillars-of-wisdom",
    "celestial_telescope": "celestial-telescope", "orb_of_knowledge": "orb-of-knowledge",
    # "Explorer's Journal" (v1.3 name) uses the style guide's route-map medal art.
    "explorers_journal": "golden-route-map",
}


def q(s):
    return "null" if s is None else "'" + s.replace("'", "''") + "'"


def aria_label(data: bytes) -> str | None:
    return ET.fromstring(data.decode("utf-8")).get("aria-label")


def main():
    svgs = sorted(ART.rglob("*.svg"))
    problems = []
    sums = []
    for p in svgs:
        data = p.read_bytes()
        bad, _ = iq.check_svg(p.name, data)
        if bad:
            problems.append(f"{p.relative_to(ROOT)}: {bad}")
        if not re.fullmatch(r"[a-z0-9/_-]+\.svg", str(p.relative_to(ART))):
            problems.append(f"{p.relative_to(ROOT)}: file name must be lower-case kebab")
        sums.append(f"{hashlib.sha256(data).hexdigest()}  {p.relative_to(ART)}")
    for rel in CHARACTERS:
        if not (ART / "characters" / rel).is_file():
            problems.append(f"missing character art {rel}")
    for folder in set(TROPHIES.values()):
        for tier in ("bronze", "silver", "gold"):
            if not (ART / "trophies" / folder / f"{tier}.svg").is_file():
                problems.append(f"missing trophy art {folder}/{tier}.svg")
    if problems:
        sys.exit("Art pack invalid:\n  " + "\n  ".join(problems))
    (ART / "SHA256SUMS").write_text("\n".join(sums) + "\n", encoding="utf-8")

    char_rows = []
    for rel, (role_type, key) in CHARACTERS.items():
        path = ART / "characters" / rel
        data = path.read_bytes()
        char_rows.append(f"  ({q(role_type)}, {q(key)}, {q('assets/art/characters/' + rel)}, "
                         f"{q(hashlib.sha256(data).hexdigest())}, {q(aria_label(data))})")
    trophy_rows = ",\n".join(f"  ({q(s)}, {q('assets/art/trophies/' + f)})" for s, f in TROPHIES.items())
    flag_rows = []
    for p in sorted((ART / "flags").glob("*.svg")):
        iso2 = p.name[:2].upper()
        flag_rows.append(f"  ({q(iso2)}, {q('assets/art/flags/' + p.name)})")

    sql = f"""-- GeoMaster 0760: Hall of Legends, trophy and flag art (GENERATED by tool/generate_art_seed.py; do not edit).
-- Art drawn with Claude Design (Anthropic) for GeoMaster; see docs/ASSET_PROVENANCE.md and assets/art/SHA256SUMS.

update public.character_art_assets a set
  bundle_path = v.bundle_path, sha256 = v.sha256, alt_text = v.alt_text,
  is_placeholder = true,  -- interim flat art until final 3D art is commissioned
  license_status = 'ai_generated_assigned',
  attribution = {q(iq.ASSET_ATTRIBUTION)},
  provenance = {q(PROVENANCE)},
  cultural_review_status = case when p.slug in ({', '.join(q(s) for s in sorted(CULTURAL_REVIEW))})
                                then 'pending' else 'not_required' end
from (values
{(',' + chr(10)).join(char_rows)}
) as v(role_type, role_key, bundle_path, sha256, alt_text),
public.character_roles c, public.historical_people p
where c.role_type = v.role_type and c.role_key = v.role_key and p.id = c.person_id
  and a.character_role_id = c.id and a.variant = 'bust';

-- characters/locked-legend-silhouette.svg and trophies/locked.svg are generic UI art (bundled, not per person).

update public.trophy_definitions t set art_bundle_dir = v.dir
from (values
{trophy_rows}
) as v(slug, dir)
where t.slug = v.slug;

-- Flags are simplified design mockups (e.g. Malta's George Cross, Peru civil flag); replace before release.
update public.country_catalog c set flag_asset_path = v.path, flag_asset_status = 'mockup'
from (values
{(',' + chr(10)).join(flag_rows)}
) as v(iso2, path)
where c.iso2 = v.iso2;
"""
    OUT.write_text(sql, encoding="utf-8")
    print(f"Validated {len(svgs)} SVGs; wrote {OUT.relative_to(ROOT)} and assets/art/SHA256SUMS")


if __name__ == "__main__":
    main()
