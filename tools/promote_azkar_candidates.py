#!/usr/bin/env python3
"""Promote reviewer-approved azkar records from the candidate dataset to the release dataset.

Content-safety contract (NON-NEGOTIABLE — see TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md):
  - This script NEVER authors, paraphrases, edits, or repairs religious text.
    It copies records verbatim from the candidate file to the release file.
  - Per policy §3.ب and §5, every promoted record MUST carry:
      * sourceUrl (the specific Dorar SNH record page),
      * retrievedAt (date the source page was verified),
      * a human sharia review evidence block: reviewedBy (name/role) and
        reviewedAt (decision date).
  - Only records whose IDs are explicitly passed via --ids are copied; every
    requested id must have that evidence or promotion aborts.
  - Promoted records are stamped with the --review-set name (e.g.
    "v1-reviewed-3") and reviewStatus "approved".
  - The release loader (ZikrModel.fromJson) rejects anything but approved
    records, so a policy-violating promotion fails at runtime + tests.

Usage:
  python tools/promote_azkar_candidates.py --ids gen_travel --review-set v1-reviewed-2 \
      --reviewer "الشيخ <name> — المراجع الشرعي" --reviewed-at 2026-08-30
  python tools/promote_azkar_candidates.py --check --ids m1 --review-set v1-reviewed-2 \
      --reviewer "..." --reviewed-at 2026-08-30      # dry-run, no files written
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CANDIDATE = ROOT / "assets" / "data" / "azkar.json"
RELEASE = ROOT / "assets" / "data" / "azkar_release.json"
CATEGORIES = ("morning", "evening", "general", "duas")

# Provenance fields required by the Islamic content sources policy.
REQUIRED_PROVENANCE = ("sourceUrl", "retrievedAt")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    for key in CATEGORIES:
        if not isinstance(data.get(key), list):
            raise SystemExit(f"{path.name}: missing '{key}' list")
    return data


def save(path: Path, data: dict) -> None:
    """Serialize in the historical compact style: records inline per category.

    Keeping the release file byte-format stable means the git diff shows only
    the promoted records, and reviewers can diff religious text line-by-line.
    """
    categories = ("morning", "evening", "general", "duas")
    lines = ["{"]
    for i, category in enumerate(categories):
        body = json.dumps(data[category], ensure_ascii=False, separators=(",", ":"))
        comma = "," if i < len(categories) - 1 else ""
        lines.append(f'  "{category}": {body}{comma}')
    lines.append("}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def index_by_id(data: dict) -> dict[str, tuple[str, dict]]:
    index: dict[str, tuple[str, dict]] = {}
    for category in CATEGORIES:
        for record in data[category]:
            record_id = record.get("id")
            if not record_id:
                continue
            if record_id in index:
                raise SystemExit(f"Duplicate candidate id: {record_id}")
            index[record_id] = (category, record)
    return index


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--ids",
        default="",
        help="Comma-separated candidate record ids to promote (e.g. m23,e23)",
    )
    parser.add_argument(
        "--review-set",
        default="",
        help="Review-set stamp written into datasetVersion (e.g. v1-reviewed-3)",
    )
    parser.add_argument(
        "--reviewer",
        default="",
        help="Reviewer name/role recorded as review evidence (policy §5)",
    )
    parser.add_argument(
        "--reviewed-at",
        default="",
        help="Review decision date, YYYY-MM-DD (policy §5)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Dry-run: report what would change without writing anything",
    )
    args = parser.parse_args()

    if wanted_any := [i.strip() for i in args.ids.split(",") if i.strip()]:
        missing = [
            flag
            for flag, value in (
                ("--review-set", args.review_set),
                ("--reviewer", args.reviewer),
                ("--reviewed-at", args.reviewed_at),
            )
            if not value.strip()
        ]
        if missing:
            raise SystemExit(
                "promotion requires review evidence: "
                + ", ".join(missing)
                + " (human sharia review is mandatory before release)"
            )

    candidate = load(CANDIDATE)
    release = load(RELEASE)
    candidate_index = index_by_id(candidate)

    release_ids = {
        category: {record.get("id") for record in release[category]}
        for category in CATEGORIES
    }

    promotions: dict[str, list[dict]] = {c: [] for c in CATEGORIES}
    skipped: list[str] = []
    for record_id in wanted_any:
        if record_id not in candidate_index:
            skipped.append(record_id)
            continue
        category, record = candidate_index[record_id]
        if record.get("reviewStatus") != "pendingReview":
            # Already promoted or in an unexpected state — never double-copy.
            skipped.append(record_id)
            continue
        missing_fields = [
            field
            for field in REQUIRED_PROVENANCE
            if not str(record.get(field) or "").strip()
        ]
        if missing_fields:
            raise SystemExit(
                f"Record {record_id} is missing provenance fields "
                f"{missing_fields} (policy §5: sourceUrl + retrievedAt are "
                "mandatory)."
            )
        promotions[category].append(record)

    total = sum(len(v) for v in promotions.values())
    print(f"candidate ids requested : {len(wanted_any)}")
    print(f"promotions resolved     : {total}")
    for category in CATEGORIES:
        for record in promotions[category]:
            print(
                f"  + {category:8s} {record['id']:38s} "
                f"source={record.get('sourceUrl', '')}"
            )
    for record_id in skipped:
        print(f"  = skipped (released or unknown): {record_id}")

    if total == 0:
        print("nothing to promote")
        return 0

    if args.check:
        print("dry-run: no files written")
        return 0

    for category in CATEGORIES:
        for record in promotions[category]:
            promoted = dict(record)
            promoted["datasetVersion"] = args.review_set
            promoted["reviewStatus"] = "approved"
            promoted["reviewedBy"] = args.reviewer.strip()
            promoted["reviewedAt"] = args.reviewed_at.strip()
            release[category].append(promoted)

    before = sha256(RELEASE)
    save(RELEASE, release)
    after = sha256(RELEASE)
    print(f"release sha256: {before[:12]}... -> {after[:12]}...")
    print(
        "next: run flutter test test/core/content/ test/assets/ "
        "test/features/azkar/ to validate the release file."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
