"""Unit tests for tool/import_questions.py (standard library only).

    python3 -m unittest discover -s tests -p 'test_*.py'
"""
import copy
import importlib.util
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "content/raw/geomaster-test-2026-11-plus20"
spec = importlib.util.spec_from_file_location("iq", ROOT / "tool/import_questions.py")
iq = importlib.util.module_from_spec(spec)
spec.loader.exec_module(iq)

GOOD_SVG = b'<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><text>River</text></svg>'


def real_bank():
    return json.loads((RAW / "GeoMaster_520_Test_Questions.json").read_text(encoding="utf-8"))


def make_zip(path: Path, bank: dict, extra: dict | None = None, assets: dict | None = None):
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("GeoMaster_520_Test_Questions.json", json.dumps(bank, ensure_ascii=False))
        for name in sorted({q["visual_asset"] for q in bank["questions"] if q["visual_asset"]}):
            z.writestr(name, (assets or {}).get(name, GOOD_SVG))
        for name, data in (extra or {}).items():
            z.writestr(name, data)


class Args:
    def __init__(self, zip_path, tmp):
        self.zip, self.json, self.csv = str(zip_path), None, None
        self.out, self.assets_out, self.archive = str(tmp / "out"), str(tmp / "assets"), str(tmp / "raw")


def run(bank, extra=None, assets=None):
    tmp = Path(tempfile.mkdtemp())
    z = tmp / "bank.zip"
    make_zip(z, bank, extra, assets)
    payload = iq.build(Args(z, tmp))
    report = json.loads((tmp / "out/qa_report.json").read_text())
    codes = {(i["code"], i["id"]) for i in report["issues"]}
    status = {q["external_id"]: q["editorial_status"] for q in payload["questions"]}
    return payload, report, codes, status


class RealBank(unittest.TestCase):
    def test_real_package_is_clean(self):
        tmp = Path(tempfile.mkdtemp())
        payload = iq.build(Args(RAW / "GeoMaster_520_Questions_and_Visuals.zip", tmp))
        m = payload["content_version"]["metrics"]
        self.assertEqual(m["questions"], 520)
        self.assertEqual(m["errors"], 0)
        self.assertEqual(len(m["by_category"]), 7)
        self.assertEqual(m["by_cohort"], {"original_500": 500, "explorers_plus20": 20})
        self.assertEqual(m["approved"], 0)
        self.assertTrue(all(q["editorial_status"] == "draft_unverified" for q in payload["questions"]))

    def test_category_mapping_covers_all_seven(self):
        self.assertEqual(len(set(iq.CATEGORY_SLUGS.values())), 7)
        self.assertIn("politics_world_affairs", iq.CATEGORY_SLUGS.values())


class Validation(unittest.TestCase):
    def setUp(self):
        self.bank = real_bank()

    def q(self, qid):
        return next(q for q in self.bank["questions"] if q["id"] == qid)

    def test_wrong_index_and_mismatch_are_quarantined(self):
        self.q("GM-0100")["correct_option"] = 7
        q = self.q("GM-0101"); q["correct_answer"] = "Not an option"
        _, _, codes, status = run(self.bank)
        self.assertIn(("bad_correct_index", "GM-0100"), codes)
        self.assertIn(("answer_mismatch", "GM-0101"), codes)
        self.assertEqual(status["GM-0100"], "quarantined")
        self.assertEqual(status["GM-0101"], "quarantined")
        self.assertEqual(status["GM-0102"], "draft_unverified")

    def test_duplicate_options_and_empty_option(self):
        q = self.q("GM-0200"); q["options"][1] = q["options"][0]
        self.q("GM-0201")["options"][2] = "  "
        _, _, codes, _ = run(self.bank)
        self.assertIn(("duplicate_option", "GM-0200"), codes)
        self.assertIn(("empty_option", "GM-0201"), codes)

    def test_duplicate_id_and_count(self):
        self.bank["questions"].append(copy.deepcopy(self.q("GM-0001")))
        self.bank["question_count"] = 521
        _, _, codes, _ = run(self.bank)
        self.assertIn(("duplicate_id", "GM-0001"), codes)
        self.assertIn(("expected_520", None), codes)

    def test_exact_duplicate_question_detected(self):
        dup = self.q("GM-0150")
        target = next(q for q in self.bank["questions"]
                      if q["category"] == dup["category"] and q["id"] > dup["id"])
        for k in ("question", "options", "correct_option", "correct_answer", "visual_asset"):
            target[k] = copy.deepcopy(dup[k])
        _, _, codes, status = run(self.bank)
        self.assertIn(("duplicate_question", target["id"]), codes)
        self.assertEqual(status[target["id"]], "quarantined")

    def test_template_siblings_are_not_duplicates(self):
        _, _, codes, _ = run(self.bank)
        self.assertFalse(any(c == "duplicate_question" for c, _ in codes))

    def test_missing_visual(self):
        self.q("GM-0300")["visual_asset"] = "assets/nope.svg"
        tmp = Path(tempfile.mkdtemp()); z = tmp / "b.zip"
        with zipfile.ZipFile(z, "w") as zf:
            zf.writestr("GeoMaster_520_Test_Questions.json", json.dumps(self.bank))
            for n in sorted({q["visual_asset"] for q in self.bank["questions"] if q["visual_asset"]} - {"assets/nope.svg"}):
                zf.writestr(n, GOOD_SVG)
        payload = iq.build(Args(z, tmp))
        st = {q["external_id"]: q["editorial_status"] for q in payload["questions"]}
        self.assertEqual(st["GM-0300"], "quarantined")

    def test_visual_path_traversal_in_question(self):
        self.q("GM-0301")["visual_asset"] = "../etc/passwd.svg"
        _, _, codes, _ = run(self.bank, extra={})
        self.assertIn(("visual_path_unsafe", "GM-0301"), codes)

    def test_zip_traversal_entry_rejected(self):
        _, report, codes, _ = run(self.bank, extra={"../evil.txt": b"x"})
        self.assertIn(("zip_path_traversal", None), codes)

    def test_unsafe_svg_blocks_question(self):
        bad = b'<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'
        payload, _, codes, status = run(self.bank, assets={"assets/river_1.svg": bad})
        self.assertIn(("svg_unsafe", None), codes)
        self.assertEqual(status["GM-0001"], "quarantined")
        self.assertNotIn("river_1.svg", [a["file_name"] for a in payload["assets"]])

    def test_svg_policy(self):
        cases = {
            b'<svg xmlns="http://www.w3.org/2000/svg" onload="x()"/>': "event handler",
            b'<svg xmlns="http://www.w3.org/2000/svg" xmlns:x="http://www.w3.org/1999/xlink"><image x:href="http://e/x.png"/></svg>': "disallowed element",
            b'<!DOCTYPE svg [<!ENTITY a "b">]><svg xmlns="http://www.w3.org/2000/svg"/>': "DOCTYPE",
            b'<svg xmlns="http://www.w3.org/2000/svg"><foreignObject/></svg>': "disallowed element",
        }
        for data, needle in cases.items():
            problems, _ = iq.check_svg("x.svg", data)
            self.assertTrue(any(needle in p for p in problems), (data, problems))
        self.assertEqual(iq.check_svg("ok.svg", GOOD_SVG)[0], [])

    def test_reference_year_warning(self):
        _, _, codes, status = run(self.bank)
        self.assertIn(("needs_reference_year", "GM-0317"), codes)
        self.assertEqual(status["GM-0317"], "draft_unverified")  # warning, not quarantine

    def test_content_hash_stable(self):
        q = self.q("GM-0001")
        self.assertEqual(iq.canonical_hash(q), iq.canonical_hash(copy.deepcopy(q)))
        q2 = copy.deepcopy(q); q2["question"] += "?"
        self.assertNotEqual(iq.canonical_hash(q), iq.canonical_hash(q2))


if __name__ == "__main__":
    unittest.main()
