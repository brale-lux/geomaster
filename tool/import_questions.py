#!/usr/bin/env python3
"""GeoMaster question-bank validator and importer.

Usage
-----
  # 1. Validate the bank, sanitise visuals, archive the raw files and write QA reports.
  python3 -I tool/import_questions.py validate --zip GeoMaster_520_Questions_and_Visuals.zip

  # 2. Validate and load into Postgres/Supabase in ONE transaction (idempotent).
  python3 -I tool/import_questions.py import --zip ... --database-url "$SUPABASE_DB_URL"

Design notes
------------
* Standard library only (no pip install). The database load shells out to `psql`
  with ON_ERROR_STOP and --single-transaction, so a failure leaves the database untouched.
* Nothing in the bank is ever marked verified. Questions that fail a hard check are still
  imported (so all 520 IDs are preserved) but with editorial_status = 'quarantined',
  which keeps them out of every playable pool. Everything else stays 'draft_unverified'.
* Re-running is a no-op: the SQL side upserts by external id (GM-0001...) and never
  overwrites a stored question whose content differs; it reports a conflict instead.
"""
from __future__ import annotations

import argparse
import csv
import datetime as _dt
import difflib
import hashlib
import io
import json
import os
import re
import secrets
import shutil
import stat
import subprocess
import sys
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter, defaultdict
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parent.parent

# Display name in the bank -> stable slug (v1.2 prompt, section 2).
CATEGORY_SLUGS = {
    "Geography & Nature": "geography_nature",
    "History & Civilizations": "history_civilizations",
    "Economics & Trade": "economics_trade",
    "Politics & World Affairs": "politics_world_affairs",
    "Space & Astronomy": "space_astronomy",
    "Explorers, Pioneers & Discoverers": "explorers_pioneers_discoverers",
    "Connected World": "connected_world",
}
ALL_SLUGS = set(CATEGORY_SLUGS.values())

REQUIRED_KEYS = {
    "id", "category", "subcategory", "question", "options", "correct_option", "correct_answer",
    "explanation", "difficulty", "visual_asset", "period", "source_hint", "review_status",
    "language", "question_type",
}
ID_RE = re.compile(r"^GM-(\d{4})$")
ORIGINAL_RANGE = range(1, 501)
EXPLORER_RANGE = range(501, 521)
MAX_ASSET_BYTES = 512 * 1024
MAX_ZIP_ENTRIES = 2000
MAX_ZIP_TOTAL = 50 * 1024 * 1024

# Wording that usually makes a fact time-sensitive.
TIME_SENSITIVE_RE = re.compile(
    r"\b(current|currently|today|now|as of|latest|present-day|incumbent|apportionment|"
    r"member states|population|most populous|gdp|inflation|exchange rate)\b", re.I)
MOJIBAKE_RE = re.compile(r"(Ã.|â€|Â\s|�)")
HTML_ENTITY_RE = re.compile(r"&(amp|lt|gt|quot|#\d+|#x[0-9a-f]+);", re.I)
DISCOVERY_RE = re.compile(r"\bdiscover(ed|y|er)?\b", re.I)

# SVG safety policy: a strict allow-list of elements; no scripts, events, external refs.
SVG_NS = "http://www.w3.org/2000/svg"
SVG_ALLOWED = {
    "svg", "g", "rect", "circle", "ellipse", "line", "polyline", "polygon", "path", "text",
    "tspan", "title", "desc", "defs", "linearGradient", "radialGradient", "stop", "clipPath",
}


def slugify(text: str) -> str:
    t = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", t.lower()).strip("_")


def entities(text: str) -> frozenset[str]:
    """Capitalised words and numbers after the first word: the 'slot' values of templated prompts."""
    words = re.findall(r"[\w’'-]+", unicodedata.normalize("NFKC", text))
    return frozenset(w.casefold() for w in words[1:] if w[:1].isupper() or w[:1].isdigit())


def norm_prompt(text: str) -> str:
    t = unicodedata.normalize("NFKC", text).lower()
    t = re.sub(r"[“”\"'’‘]", "", t)
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", " ", t)).strip()


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def canonical_hash(q: dict) -> str:
    """Hash of the fields that define a question; used to detect changed content on re-import."""
    keep = {k: q[k] for k in ("id", "category", "subcategory", "question", "options",
                               "correct_option", "correct_answer", "explanation", "difficulty",
                               "visual_asset", "period", "source_hint", "question_type", "language")}
    return sha256_bytes(json.dumps(keep, ensure_ascii=False, sort_keys=True).encode("utf-8"))


# --------------------------------------------------------------------------- ZIP & SVG safety

class Issue:
    __slots__ = ("severity", "code", "qid", "detail")

    def __init__(self, severity: str, code: str, qid: str | None, detail: str):
        self.severity, self.code, self.qid, self.detail = severity, code, qid, detail

    def as_dict(self):
        return {"severity": self.severity, "code": self.code, "id": self.qid, "detail": self.detail}


def inspect_zip(zip_path: Path, issues: list[Issue]) -> dict[str, bytes]:
    """Return {posix_name: bytes} for safe regular files; record unsafe entries as errors."""
    out: dict[str, bytes] = {}
    with zipfile.ZipFile(zip_path) as zf:
        infos = zf.infolist()
        if len(infos) > MAX_ZIP_ENTRIES:
            raise SystemExit(f"ZIP has {len(infos)} entries; refusing (limit {MAX_ZIP_ENTRIES}).")
        if sum(i.file_size for i in infos) > MAX_ZIP_TOTAL:
            raise SystemExit("ZIP uncompressed size exceeds limit; refusing.")
        for info in infos:
            name = info.filename
            p = PurePosixPath(name)
            mode = (info.external_attr >> 16) & 0o170000
            if name.startswith("/") or "\\" in name or ".." in p.parts or re.match(r"^[A-Za-z]:", name):
                issues.append(Issue("error", "zip_path_traversal", None, f"Unsafe entry name: {name!r}"))
                continue
            if mode == stat.S_IFLNK:
                issues.append(Issue("error", "zip_symlink", None, f"Symlink entry rejected: {name!r}"))
                continue
            if info.is_dir():
                continue
            if info.flag_bits & 0x1:
                issues.append(Issue("error", "zip_encrypted", None, f"Encrypted entry: {name!r}"))
                continue
            out[str(p)] = zf.read(info)
    return out


def _local(tag: str) -> str:
    return tag.split("}", 1)[1] if tag.startswith("{") else tag


def check_svg(name: str, data: bytes) -> tuple[list[str], list[str]]:
    """Return (problems, text_nodes). Any problem means the SVG is unsafe and is not shipped."""
    problems: list[str] = []
    if len(data) > MAX_ASSET_BYTES:
        problems.append(f"larger than {MAX_ASSET_BYTES} bytes")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return ["not valid UTF-8"], []
    if re.search(r"<!DOCTYPE|<!ENTITY|<\?xml-stylesheet", text, re.I):
        problems.append("DOCTYPE/ENTITY/stylesheet PI present")
        return problems, []
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        return [f"XML parse error: {e}"], []
    if _local(root.tag) != "svg":
        problems.append("root element is not <svg>")
    texts: list[str] = []
    for el in root.iter():
        tag = _local(el.tag)
        if tag not in SVG_ALLOWED:
            problems.append(f"disallowed element <{tag}>")
        for attr, val in el.attrib.items():
            a = _local(attr).lower()
            v = val.strip().lower()
            if a.startswith("on"):
                problems.append(f"event handler attribute {a}")
            if a in ("href",) and not v.startswith("#"):
                problems.append(f"external reference {a}={val[:60]!r}")
            if "javascript:" in v or "url(http" in v.replace(" ", "") or "@import" in v:
                problems.append(f"unsafe attribute value in {a}")
        if tag in ("text", "tspan", "title", "desc") and el.text and el.text.strip():
            texts.append(el.text.strip())
    return sorted(set(problems)), texts


def svg_size(data: bytes) -> tuple[int | None, int | None]:
    try:
        root = ET.fromstring(data.decode("utf-8"))
        w, h = root.get("width"), root.get("height")
        return (int(float(w)) if w else None, int(float(h)) if h else None)
    except Exception:  # noqa: BLE001 - informational only
        return None, None


# --------------------------------------------------------------------------- validation

def load_bank(files: dict[str, bytes], json_path: Path | None, csv_path: Path | None,
              issues: list[Issue]):
    """Load JSON (canonical) and CSV from the ZIP or explicit paths."""
    def pick(suffix: str, explicit: Path | None) -> tuple[str, bytes] | None:
        if explicit:
            return explicit.name, explicit.read_bytes()
        cands = [n for n in files if n.lower().endswith(suffix) and "/" not in n]
        return (cands[0], files[cands[0]]) if cands else None

    j = pick(".json", json_path)
    if not j:
        raise SystemExit("No question JSON found (looked in ZIP root and --json). Not fabricating data.")
    try:
        bank = json.loads(j[1].decode("utf-8-sig"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise SystemExit(f"Question JSON is not valid UTF-8 JSON: {e}")
    c = pick(".csv", csv_path)
    rows = None
    if c:
        rows = list(csv.DictReader(io.StringIO(c[1].decode("utf-8-sig"))))
    else:
        issues.append(Issue("warning", "csv_missing", None, "No CSV found; JSON used alone."))
    return j, bank, c, rows


def validate(bank: dict, files: dict[str, bytes], csv_rows, issues: list[Issue]):
    for k in ("schema_version", "content_version", "status", "question_count", "questions"):
        if k not in bank:
            issues.append(Issue("error", "root_key_missing", None, f"Root key {k!r} missing"))
    qs = bank.get("questions") or []
    if bank.get("question_count") != len(qs):
        issues.append(Issue("error", "count_mismatch", None,
                            f"question_count={bank.get('question_count')} but {len(qs)} questions present"))
    if len(qs) != 520:
        issues.append(Issue("error", "expected_520", None, f"Expected 520 questions, found {len(qs)}"))

    ids = [q.get("id") for q in qs]
    for qid, n in Counter(ids).items():
        if n > 1:
            issues.append(Issue("error", "duplicate_id", qid, f"ID appears {n} times"))
    nums = {int(m.group(1)) for i in ids if isinstance(i, str) and (m := ID_RE.match(i))}
    missing = sorted(set(range(1, 521)) - nums)
    if missing:
        issues.append(Issue("error", "id_gap", None, f"Missing IDs: {['GM-%04d' % n for n in missing][:20]}"))

    seen_cats = set()
    by_cat_prompts: dict[str, list[tuple[str, str, dict]]] = defaultdict(list)
    for q in qs:
        qid = q.get("id") if isinstance(q.get("id"), str) else None

        def err(code, detail, sev="error"):
            issues.append(Issue(sev, code, qid, detail))

        keys = set(q.keys())
        if REQUIRED_KEYS - keys:
            err("missing_fields", f"Missing: {sorted(REQUIRED_KEYS - keys)}")
            continue
        if keys - REQUIRED_KEYS:
            err("extra_fields", f"Unexpected: {sorted(keys - REQUIRED_KEYS)}", "warning")
        if not qid or not ID_RE.match(qid):
            err("bad_id", f"ID {q.get('id')!r} does not match GM-0000")
        cat = q["category"]
        if cat not in CATEGORY_SLUGS:
            err("unknown_category", f"Category {cat!r} has no slug mapping")
        else:
            seen_cats.add(CATEGORY_SLUGS[cat])
        n = int(ID_RE.match(qid).group(1)) if qid and ID_RE.match(qid) else 0
        if n in EXPLORER_RANGE and cat != "Explorers, Pioneers & Discoverers":
            err("cohort_category", "GM-0501..0520 are expected to be Explorers questions", "warning")

        opts = q["options"]
        if not isinstance(opts, list) or len(opts) != 4:
            err("options_not_four", f"Expected 4 options, got {opts!r}")
            continue
        if any(not isinstance(o, str) or not o.strip() for o in opts):
            err("empty_option", "An option is empty or not a string")
        if len({o.strip().casefold() for o in opts if isinstance(o, str)}) != 4:
            err("duplicate_option", f"Options are not unique: {opts}")
        if any(isinstance(o, str) and o != o.strip() for o in opts):
            err("option_whitespace", "Option has leading/trailing whitespace", "warning")
        co = q["correct_option"]
        if not isinstance(co, int) or isinstance(co, bool) or not 0 <= co <= 3:
            err("bad_correct_index", f"correct_option={co!r} is not a zero-based index 0..3")
        elif opts[co] != q["correct_answer"]:
            err("answer_mismatch", f"options[{co}]={opts[co]!r} != correct_answer={q['correct_answer']!r}")
        if not isinstance(q["question"], str) or len(q["question"].strip()) < 10:
            err("prompt_too_short", "Question text missing or shorter than 10 characters")
        if not isinstance(q["explanation"], str) or len(q["explanation"].strip()) < 10:
            err("explanation_missing", "Explanation missing or shorter than 10 characters")
        d = q["difficulty"]
        if not isinstance(d, int) or isinstance(d, bool) or not 1 <= d <= 5:
            err("bad_difficulty", f"difficulty={d!r} is not 1..5")
        if q["question_type"] != "multiple_choice":
            err("question_type", f"Unsupported question_type {q['question_type']!r}")
        if q["review_status"] != "draft_unverified":
            err("review_status", f"review_status={q['review_status']!r}; bank must import as draft only",
                "warning")
        if q["language"] != "en":
            err("language", f"language={q['language']!r}", "warning")

        all_text = " ".join([q["question"], q["explanation"], *[str(o) for o in opts]])
        if MOJIBAKE_RE.search(all_text):
            err("encoding_mojibake", "Text contains mojibake / replacement characters")
        if HTML_ENTITY_RE.search(all_text):
            err("html_entity", "Text contains escaped HTML entities", "warning")
        if re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", all_text):
            err("control_chars", "Text contains control characters")

        va = q["visual_asset"]
        if va is not None:
            p = PurePosixPath(va)
            if ".." in p.parts or p.is_absolute() or p.parts[0] != "assets" or p.suffix.lower() != ".svg":
                err("visual_path_unsafe", f"visual_asset {va!r} must be assets/<name>.svg")
            elif va not in files:
                err("visual_missing", f"visual_asset {va!r} not found in ZIP")

        # Content warnings for the editorial queue (never auto-fixed).
        if TIME_SENSITIVE_RE.search(q["question"]) and not q["period"] and cat in (
                "Economics & Trade", "Politics & World Affairs", "Connected World"):
            err("needs_reference_year", "Time-sensitive wording without a period/reference year", "warning")
        if cat == "History & Civilizations" and not q["period"]:
            err("history_without_period", "Historical question without a period", "warning")
        if re.search(r"\b(un|us|uk|eu|nato|imf|wto|gdp)\b", q["question"]):
            err("lowercase_acronym", "Lower-case acronym in prompt (template artefact?)", "warning")
        if DISCOVERY_RE.search(q["question"] + " " + q["explanation"]) and cat in (
                "Explorers, Pioneers & Discoverers", "History & Civilizations", "Connected World"):
            err("discovery_framing", "Uses 'discover' wording; check prior/Indigenous knowledge framing",
                "warning")
        ans = q["correct_answer"]
        if isinstance(ans, str) and len(ans) > 3 and re.search(rf"\b{re.escape(ans)}\b", q["question"], re.I):
            err("answer_in_prompt", "Correct answer text appears in the prompt", "warning")
        if not q["source_hint"]:
            err("source_missing", "No source hint", "warning")
        by_cat_prompts[cat].append((qid, norm_prompt(q["question"]), q))

    for slug in sorted(ALL_SLUGS - seen_cats):
        issues.append(Issue("error", "category_absent", None, f"No questions for category {slug}"))

    # Exact and near-duplicate prompts within a category (same visual + same answer => real duplicate).
    for cat, items in by_cat_prompts.items():
        for i in range(len(items)):
            a_id, a, qa = items[i]
            for j in range(i + 1, len(items)):
                b_id, b, qb = items[j]
                if qa["visual_asset"] != qb["visual_asset"]:
                    continue
                sm = difflib.SequenceMatcher(None, a, b)
                if sm.real_quick_ratio() < 0.92 or sm.quick_ratio() < 0.92:
                    continue
                r = sm.ratio()
                # Template siblings ("...does the Elbe flow?" vs "...the Rhine flow?") differ in
                # their named entities and are distinct questions, not duplicates.
                if r >= 0.92 and (a == b or entities(qa["question"]) == entities(qb["question"])):
                    same_ans = qa["correct_answer"].casefold() == qb["correct_answer"].casefold()
                    if a == b and same_ans:
                        issues.append(Issue("error", "duplicate_question", b_id,
                                            f"Same prompt and answer as {a_id}"))
                    elif same_ans:
                        issues.append(Issue("warning", "near_duplicate", b_id,
                                            f"{r:.0%} similar to {a_id} with the same answer"))

    # CSV reconciliation.
    if csv_rows is not None:
        if len(csv_rows) != len(qs):
            issues.append(Issue("error", "csv_count", None, f"CSV has {len(csv_rows)} rows, JSON {len(qs)}"))
        by_id = {r.get("id"): r for r in csv_rows}
        for q in qs:
            r = by_id.get(q.get("id"))
            if r is None:
                issues.append(Issue("error", "csv_missing_row", q.get("id"), "ID absent from CSV"))
                continue
            diffs = []
            for k in ("category", "subcategory", "question", "correct_answer", "explanation",
                      "source_hint", "review_status", "language", "question_type"):
                if (r.get(k) or "") != (q.get(k) or ""):
                    diffs.append(k)
            if [r.get(f"option_{c}") for c in "abcd"] != q.get("options"):
                diffs.append("options")
            if str(r.get("correct_option")) != str(q.get("correct_option")):
                diffs.append("correct_option")
            if str(r.get("difficulty")) != str(q.get("difficulty")):
                diffs.append("difficulty")
            if (r.get("visual_asset") or None) != q.get("visual_asset"):
                diffs.append("visual_asset")
            if (r.get("period") or None) != (str(q["period"]) if q.get("period") is not None else None):
                diffs.append("period")
            if diffs:
                issues.append(Issue("error", "csv_json_mismatch", q.get("id"), f"Fields differ: {diffs}"))


# --------------------------------------------------------------------------- build payload & reports

def build(args) -> dict:
    zip_path = Path(args.zip).resolve()
    issues: list[Issue] = []
    files = inspect_zip(zip_path, issues)
    (jname, jbytes), bank, csvinfo, rows = load_bank(
        files, Path(args.json) if args.json else None, Path(args.csv) if args.csv else None, issues)
    validate(bank, files, rows, issues)

    version = bank.get("content_version", "unknown")
    if not re.match(r"^[A-Za-z0-9._-]{1,80}$", version):
        raise SystemExit(f"Unsafe content_version {version!r}")
    out_dir = Path(args.out).resolve()
    assets_dir = Path(args.assets_out).resolve()
    archive_dir = Path(args.archive).resolve() / version
    for d in (out_dir, assets_dir, archive_dir):
        d.mkdir(parents=True, exist_ok=True)

    # Visual assets: inventory, sanitise, copy safe ones.
    referenced = Counter(q["visual_asset"] for q in bank["questions"] if q.get("visual_asset"))
    assets = []
    unsafe_assets = set()
    for name in sorted(n for n in files if n.startswith("assets/")):
        data = files[name]
        if not name.lower().endswith(".svg"):
            issues.append(Issue("warning", "asset_not_svg", None, f"{name} ignored (only SVG expected)"))
            continue
        problems, texts = check_svg(name, data)
        if problems:
            unsafe_assets.add(name)
            issues.append(Issue("error", "svg_unsafe", None, f"{name}: {problems}"))
            continue
        if name not in referenced:
            issues.append(Issue("warning", "asset_unreferenced", None, f"{name} is not used by any question"))
        base = PurePosixPath(name).name
        (assets_dir / base).write_bytes(data)
        w, h = svg_size(data)
        alt = ". ".join(texts) if texts else None
        assets.append({
            "zip_path": name, "file_name": base,
            "storage_path": f"{version}/{base}",
            "bundle_path": f"assets/questions/{base}",
            "sha256": sha256_bytes(data), "byte_size": len(data), "width": w, "height": h,
            "alt_text": alt, "alt_text_status": "auto_from_svg_text" if alt else "missing",
            "attribution": "[PLACEHOLDER] Supplied in GeoMaster test package; author not recorded",
            "license": None, "license_status": "pending_review",
        })

    # Per-question status: any error -> quarantined; flags recorded on the row.
    per_q: dict[str, list[dict]] = defaultdict(list)
    for i in issues:
        if i.qid:
            per_q[i.qid].append(i.as_dict())
    for q in bank["questions"]:
        if q.get("visual_asset") in unsafe_assets:
            per_q[q["id"]].append({"severity": "error", "code": "visual_unsafe", "id": q["id"],
                                   "detail": f"{q['visual_asset']} failed SVG safety checks"})

    questions, quarantine = [], []
    for q in bank["questions"]:
        if not isinstance(q.get("id"), str) or not ID_RE.match(q["id"]) or REQUIRED_KEYS - set(q):
            continue  # cannot be keyed safely; already reported as an error
        flags = per_q.get(q["id"], [])
        hard = [f for f in flags if f["severity"] == "error"]
        n = int(q["id"][3:])
        opts = q["options"] if isinstance(q["options"], list) else []
        co = q["correct_option"] if isinstance(q["correct_option"], int) else -1
        if hard or len(opts) != 4 or not 0 <= co <= 3:
            status = "quarantined"
            quarantine.append({"id": q["id"], "reasons": hard or [{"code": "structure"}]})
        else:
            status = "draft_unverified"
        questions.append({
            "external_id": q["id"],
            "category_slug": CATEGORY_SLUGS.get(q["category"]),
            "subcategory_slug": slugify(q["subcategory"] or "general"),
            "subcategory_name": q["subcategory"] or "General",
            "prompt": q["question"], "options": opts, "correct_position": co,
            "explanation": q["explanation"], "difficulty": q["difficulty"],
            "question_type": q["question_type"], "language": q["language"],
            "period_label": None if q["period"] is None else str(q["period"]),
            "source_hint": q["source_hint"],
            "visual_asset": q["visual_asset"],
            "visual_file": PurePosixPath(q["visual_asset"]).name if q["visual_asset"] else None,
            "cohort": "original_500" if n in ORIGINAL_RANGE else
                      "explorers_plus20" if n in EXPLORER_RANGE else "other",
            "editorial_status": status,
            "qa_flags": flags,
            "content_hash": canonical_hash(q),
        })

    errors = [i for i in issues if i.severity == "error"]
    warnings = [i for i in issues if i.severity == "warning"]
    metrics = compute_metrics(questions, assets)
    metrics.update({"errors": len(errors), "warnings": len(warnings), "quarantined": len(quarantine)})

    # Archive raw inputs (never modified) with checksums.
    zip_sha = sha256_bytes(zip_path.read_bytes())
    shutil.copy2(zip_path, archive_dir / zip_path.name)
    (archive_dir / jname.split("/")[-1]).write_bytes(jbytes)
    checks = {zip_path.name: zip_sha, jname.split("/")[-1]: sha256_bytes(jbytes)}
    if csvinfo:
        (archive_dir / csvinfo[0].split("/")[-1]).write_bytes(csvinfo[1])
        checks[csvinfo[0].split("/")[-1]] = sha256_bytes(csvinfo[1])
    (archive_dir / "SHA256SUMS").write_text("".join(f"{h}  {n}\n" for n, h in sorted(checks.items())))

    payload = {
        "content_version": {
            "version_key": version, "schema_version": bank.get("schema_version"),
            "status": bank.get("status"), "question_count": len(questions),
            "source_filename": zip_path.name, "source_sha256": sha256_bytes(jbytes),
            "package_sha256": zip_sha,
            "archive_path": f"content/raw/{version}/", "metrics": metrics,
        },
        "assets": assets,
        "questions": questions,
    }
    (out_dir / "import_payload.json").write_text(json.dumps(payload, ensure_ascii=False, indent=1),
                                                 encoding="utf-8")
    report = {
        "generated_at": _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds"),
        "content_version": version, "schema_version": bank.get("schema_version"),
        "checksums": checks, "metrics": metrics,
        "issues": [i.as_dict() for i in issues],
    }
    (out_dir / "qa_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding="utf-8")
    (out_dir / "quarantine.json").write_text(json.dumps(quarantine, ensure_ascii=False, indent=1),
                                             encoding="utf-8")
    (out_dir / "QA_REPORT.md").write_text(render_markdown(report, quarantine), encoding="utf-8")
    print(f"Validated {len(questions)} questions: {len(errors)} errors, {len(warnings)} warnings, "
          f"{len(quarantine)} quarantined. Reports in {out_dir}")
    return payload


def compute_metrics(questions, assets):
    m = {
        "questions": len(questions),
        "by_category": dict(sorted(Counter(q["category_slug"] for q in questions).items())),
        "by_difficulty": {str(k): v for k, v in sorted(Counter(q["difficulty"] for q in questions).items())},
        "by_visual": {"visual": sum(1 for q in questions if q["visual_asset"]),
                      "text_only": sum(1 for q in questions if not q["visual_asset"])},
        "by_status": dict(Counter(q["editorial_status"] for q in questions)),
        "by_cohort": dict(Counter(q["cohort"] for q in questions)),
        "by_correct_position": {str(k): v for k, v in sorted(Counter(q["correct_position"] for q in questions).items())},
        "approved": sum(1 for q in questions if q["editorial_status"] == "approved"),
        "assets_shipped": len(assets),
    }
    return m


def render_markdown(report, quarantine) -> str:
    m = report["metrics"]
    L = [f"# GeoMaster question bank QA report",
         "",
         f"Content version `{report['content_version']}` (schema {report['schema_version']}), "
         f"generated {report['generated_at']}.",
         "",
         "All questions are **draft, unverified test content**. A source hint is not a verified citation, "
         "and nothing here is cleared for ranked play.",
         "",
         "## Summary", "",
         f"| Metric | Value |", "|---|---|",
         f"| Questions | {m['questions']} |",
         f"| Hard errors | {m['errors']} |",
         f"| Editorial warnings | {m['warnings']} |",
         f"| Quarantined | {m['quarantined']} |",
         f"| Approved (verified) | {m['approved']} |",
         f"| Visual / text-only | {m['by_visual']['visual']} / {m['by_visual']['text_only']} |",
         f"| SVG assets shipped (sanitised) | {m['assets_shipped']} |",
         ""]
    for title, key in (("By category", "by_category"), ("By difficulty", "by_difficulty"),
                       ("By cohort", "by_cohort"), ("By editorial status", "by_status"),
                       ("Correct-answer position (0 = A)", "by_correct_position")):
        L += [f"### {title}", "", "| Key | Count |", "|---|---|"]
        L += [f"| {k} | {v} |" for k, v in m[key].items()] + [""]
    L += ["## Checksums (SHA-256)", ""] + [f"- `{n}`: `{h}`" for n, h in report["checksums"].items()] + [""]
    codes = Counter((i["severity"], i["code"]) for i in report["issues"])
    L += ["## Issues by type", "", "| Severity | Code | Count |", "|---|---|---|"]
    L += [f"| {s} | {c} | {n} |" for (s, c), n in sorted(codes.items())] + [""]
    L += ["## Quarantine list", ""]
    if quarantine:
        L += [f"- **{q['id']}**: " + "; ".join(r.get("detail", r.get("code", "")) for r in q["reasons"])
              for q in quarantine]
    else:
        L += ["None. No question failed a hard check."]
    L += ["", "## Editorial warnings (for human review, not auto-fixed)", ""]
    for i in report["issues"]:
        if i["severity"] == "warning":
            L.append(f"- {i['id'] or '(package)'} `{i['code']}`: {i['detail']}")
    L.append("")
    return "\n".join(L)


# --------------------------------------------------------------------------- DB load

def load_into_db(payload: dict, database_url: str, out_dir: Path) -> dict:
    data = json.dumps(payload, ensure_ascii=False)
    tag = "gm_" + secrets.token_hex(8)
    while f"${tag}$" in data:
        tag = "gm_" + secrets.token_hex(8)
    sql = (f"select public.import_question_bank(${tag}${data}${tag}$::jsonb) as result;\n")
    cmd = ["psql", database_url, "-X", "-q", "-t", "-A", "-v", "ON_ERROR_STOP=1", "--single-transaction"]
    proc = subprocess.run(cmd, input=sql.encode("utf-8"), capture_output=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode("utf-8", "replace"))
        raise SystemExit("Import failed; transaction rolled back, database unchanged.")
    result = json.loads(proc.stdout.decode("utf-8").strip().splitlines()[-1])
    (out_dir / "import_result.json").write_text(json.dumps(result, indent=1), encoding="utf-8")
    print("Import result:", json.dumps({k: v for k, v in result.items() if k != "conflicts"}),
          f"conflicts={len(result.get('conflicts', []))}")
    return result


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("validate", "import"):
        p = sub.add_parser(name)
        p.add_argument("--zip", required=True, help="GeoMaster_520_Questions_and_Visuals.zip")
        p.add_argument("--json", help="Override JSON path (default: JSON inside the ZIP)")
        p.add_argument("--csv", help="Override CSV path (default: CSV inside the ZIP)")
        p.add_argument("--out", default=str(ROOT / "reports"), help="Report output directory")
        p.add_argument("--assets-out", default=str(ROOT / "content/assets/questions"),
                       help="Where sanitised SVGs are written (copied into the Flutter bundle in Phase B)")
        p.add_argument("--archive", default=str(ROOT / "content/raw"), help="Raw archive root")
        if name == "import":
            p.add_argument("--database-url", default=os.environ.get("SUPABASE_DB_URL"),
                           help="Postgres URL (or env SUPABASE_DB_URL). Never commit it.")
    args = ap.parse_args(argv)
    payload = build(args)
    if args.cmd == "import":
        if not args.database_url:
            raise SystemExit("--database-url or SUPABASE_DB_URL is required for import")
        load_into_db(payload, args.database_url, Path(args.out).resolve())


if __name__ == "__main__":
    main()
