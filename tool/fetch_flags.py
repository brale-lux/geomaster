#!/usr/bin/env python3
"""Fetch the 195 national flags from Wikimedia Commons with per-file licence metadata.

    python3 -I tool/fetch_flags.py            # fetch missing flags, then write the manifest
    python3 -I tool/fetch_flags.py --offline  # rebuild the manifest from files already fetched

Writes  assets/flags/<iso2>.svg          sanitised SVG (true proportions, as published on Commons)
        assets/flags/MANIFEST.json       source title/URL, licence, author, restrictions, sha256, size
Follows the Wikimedia API etiquette: one request at a time, batches of 50 titles, honours Retry-After.
A flag is never invented: a country whose file cannot be resolved is reported, not filled in.
"""
import argparse
import hashlib
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "assets/data/GeoMaster_Country_Catalog_195_v1.3.json"
OUT = ROOT / "assets/flags"
API = "https://commons.wikimedia.org/w/api.php"
UA = "GeoMasterAssetFetch/0.1 (educational quiz app; one-off flag import)"
MAX_BYTES = 1_500_000

# Commons file names that differ from the catalog's display names.
COMMONS_NAME = {
    "BN": "Brunei", "CV": "Cape Verde", "CZ": "the Czech Republic", "CI": "Côte d'Ivoire",
    "KP": "North Korea", "CD": "the Democratic Republic of the Congo", "DO": "the Dominican Republic",
    "FM": "the Federated States of Micronesia", "GM": "The Gambia", "VA": "the Vatican City",
    "IR": "Iran", "LA": "Laos", "MD": "Moldova", "CG": "the Republic of the Congo", "RU": "Russia",
    "KR": "South Korea", "ST": "São Tomé and Príncipe", "PS": "Palestine", "SY": "Syria",
    "TL": "East Timor", "TR": "Turkey", "TZ": "Tanzania", "GB": "the United Kingdom",
    "US": "the United States", "VE": "Venezuela", "VN": "Vietnam", "BS": "the Bahamas",
    "NL": "the Netherlands", "PH": "the Philippines", "AE": "the United Arab Emirates",
    "KM": "the Comoros", "CF": "the Central African Republic", "MH": "the Marshall Islands",
    "SB": "the Solomon Islands", "BO": "Bolivia",
}

# Exact Commons files chosen by the owner where the default file is not the one the app uses.
# AF: the Islamic Republic tricolour still flown at the UN (Commons' default now redirects to the Taliban flag).
FILE_OVERRIDE = {"AF": "File:Flag of Afghanistan (2013–2021).svg"}

SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
ALLOWED = {"svg", "g", "rect", "circle", "ellipse", "line", "polyline", "polygon", "path", "text", "tspan",
           "title", "desc", "defs", "linearGradient", "radialGradient", "stop", "clipPath", "use", "symbol",
           "mask", "pattern", "style"}
ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", XLINK_NS)


def get(url, binary=False, tries=6):
    for attempt in range(tries):
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
                return data if binary else json.loads(data.decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code in (429, 503) and attempt < tries - 1:
                wait = int(e.headers.get("Retry-After") or 30)
                print(f"  rate limited ({e.code}); waiting {wait}s", flush=True)
                time.sleep(min(wait, 120) + 1)
                continue
            raise


def local(tag):
    return tag.split("}", 1)[1] if tag.startswith("{") else tag


def ns(tag):
    return tag[1:].split("}", 1)[0] if tag.startswith("{") else SVG_NS


def sanitise(data: bytes) -> bytes:
    """Keep only SVG-namespace drawing elements; drop editor metadata; refuse anything active."""
    text = data.decode("utf-8")
    if re.search(r"<!ENTITY|<\?xml-stylesheet", text, re.I):
        raise ValueError("entity or stylesheet PI")
    text = re.sub(r"<!DOCTYPE[^>]*>", "", text)  # plain DTD references only (entities refused above)
    root = ET.fromstring(text)
    if local(root.tag) != "svg":
        raise ValueError("root is not svg")

    def clean(el):
        for child in list(el):
            if ns(child.tag) != SVG_NS or local(child.tag) in ("metadata",):
                el.remove(child)
                continue
            tag = local(child.tag)
            if tag not in ALLOWED:
                raise ValueError(f"disallowed element <{tag}>")
            clean(child)
        for attr in list(el.attrib):
            a_ns = ns(attr) if attr.startswith("{") else SVG_NS
            name = local(attr)
            val = el.attrib[attr]
            if a_ns not in (SVG_NS, XLINK_NS):
                del el.attrib[attr]  # inkscape:, sodipodi:, rdf: ...
                continue
            if name.lower().startswith("on"):
                raise ValueError(f"event handler {name}")
            if name == "href" and not val.startswith("#"):
                raise ValueError("external href")
            v = val.replace(" ", "").lower()
            if "javascript:" in v or "url(http" in v or "@import" in v:
                raise ValueError(f"unsafe value in {name}")
        if local(el.tag) == "style" and el.text:
            v = el.text.replace(" ", "").lower()
            if "@import" in v or "url(http" in v or "url(//" in v:
                raise ValueError("unsafe CSS")

    clean(root)
    out = ET.tostring(root, encoding="utf-8", xml_declaration=True)
    if len(out) > MAX_BYTES:
        raise ValueError(f"too large after sanitising ({len(out)} bytes)")
    return out


def dims(data: bytes):
    """Rendered proportions: width/height attributes when both are absolute, else the viewBox."""
    root = ET.fromstring(data.decode("utf-8"))

    def num(v):
        m = re.match(r"\s*([0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?)\s*(px)?\s*$", v or "")
        return float(m.group(1)) if m else None

    w, h = num(root.get("width")), num(root.get("height"))
    if w and h:
        return w, h
    vb = root.get("viewBox")
    if vb:
        parts = [float(x) for x in re.split(r"[ ,]+", vb.strip())]
        return parts[2], parts[3]
    return None, None


def strip_html(s):
    return html.unescape(re.sub(r"<[^>]+>", "", s or "")).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--offline", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    countries = json.loads(CATALOG.read_text(encoding="utf-8"))["countries"]
    manifest_path = OUT / "MANIFEST.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}

    todo = [c for c in countries if c["iso2"] not in manifest or not (OUT / f"{c['iso2'].lower()}.svg").exists()]
    if todo and not args.offline:
        # 1. Resolve titles in batches of 50 (two candidate spellings each, redirects followed).
        cands = {}
        for c in todo:
            n = COMMONS_NAME.get(c["iso2"], c["name"])
            if c["iso2"] in FILE_OVERRIDE:
                cands[c["iso2"]] = [FILE_OVERRIDE[c["iso2"]]]
                continue
            cands[c["iso2"]] = [f"File:Flag of {n}.svg"] + ([f"File:Flag of the {n}.svg"] if not n.startswith(("the ", "The ")) else [])
        all_titles = sorted({t for ts in cands.values() for t in ts})
        info = {}
        for i in range(0, len(all_titles), 50):
            batch = all_titles[i:i + 50]
            q = urllib.parse.urlencode({
                "action": "query", "format": "json", "redirects": 1, "prop": "imageinfo",
                "iiprop": "url|sha1|size|extmetadata", "titles": "|".join(batch)})
            d = get(f"{API}?{q}")
            norm = {x["from"]: x["to"] for x in d["query"].get("normalized", [])}
            redir = {x["from"]: x["to"] for x in d["query"].get("redirects", [])}
            pages = {p["title"]: p for p in d["query"]["pages"].values()}
            for t in batch:
                t2 = redir.get(norm.get(t, t), norm.get(t, t))
                p = pages.get(t2)
                if p and "imageinfo" in p:
                    info[t] = (t2, p["imageinfo"][0])
            print(f"resolved batch {i // 50 + 1}", flush=True)
            time.sleep(2)
        # 2. Download each resolved file.
        for c in todo:
            iso = c["iso2"]
            hit = next((info[t] for t in cands[iso] if t in info), None)
            if not hit:
                print(f"UNRESOLVED {iso} {c['name']} (tried {cands[iso]})", flush=True)
                continue
            title, ii = hit
            try:
                raw = get(ii["url"], binary=True)
                if hashlib.sha1(raw).hexdigest() != ii["sha1"]:
                    raise ValueError("sha1 mismatch with Commons")
                clean = sanitise(raw)
            except Exception as e:  # noqa: BLE001 - reported, never filled in
                print(f"REJECTED {iso} {title}: {e}", flush=True)
                continue
            (OUT / f"{iso.lower()}.svg").write_bytes(clean)
            w, h = dims(clean)
            md = ii.get("extmetadata", {})
            manifest[iso] = {
                "commons_title": title,
                "source_url": ii.get("descriptionurl") or f"https://commons.wikimedia.org/wiki/{urllib.parse.quote(title.replace(' ', '_'))}",
                "file_url": ii["url"],
                "license": strip_html(md.get("LicenseShortName", {}).get("value")),
                "license_url": strip_html(md.get("LicenseUrl", {}).get("value")) or None,
                "artist": strip_html(md.get("Artist", {}).get("value"))[:300] or None,
                "restrictions": strip_html(md.get("Restrictions", {}).get("value")) or None,
                "aspect_ratio": round(w / h, 4) if w and h else None,
                "sha256": hashlib.sha256(clean).hexdigest(),
                "bytes": len(clean),
            }
            print(f"ok {iso} {title} [{manifest[iso]['license']}] {manifest[iso]['aspect_ratio']}", flush=True)
            time.sleep(1)
    for iso, entry in manifest.items():  # keep derived fields consistent with the files on disk
        f = OUT / f"{iso.lower()}.svg"
        if f.exists():
            data = f.read_bytes()
            w, h = dims(data)
            entry["aspect_ratio"] = round(w / h, 4) if w and h else None
            entry["sha256"] = hashlib.sha256(data).hexdigest()
            entry["bytes"] = len(data)
    manifest = dict(sorted(manifest.items()))
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    missing = [c["iso2"] for c in countries if c["iso2"] not in manifest]
    print(f"manifest: {len(manifest)} flags; missing: {missing}")
    return 0 if not missing else 2


if __name__ == "__main__":
    sys.exit(main())
