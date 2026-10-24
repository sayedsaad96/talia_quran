#!/usr/bin/env python3
"""Read-only verification of EveryAyah per-ayah directory listings."""

from __future__ import annotations

import argparse
import hashlib
import html.parser
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

BASE = "https://everyayah.com/data/"
CANDIDATES = [
    "MaherAlMuaiqly128kbps", "Yasser_Ad-Dussary_128kbps",
    "Nasser_Alqatami_128kbps", "ahmed_ibn_ali_al_ajamy_128kbps",
    "Abu_Bakr_Ash-Shaatree_128kbps", "Hudhaify_128kbps",
    "Muhammad_Ayyoub_128kbps", "Ibrahim_Akhdar_32kbps",
    "Fares_Abbad_64kbps", "Abdullah_Basfar_192kbps",
]
SAMPLES = [(1, 1), (2, 1), (2, 143), (2, 286), (9, 1), (114, 6)]
TIMEOUT_SECONDS = 12
MAX_LISTING_BYTES = 4 * 1024 * 1024
MAX_SAMPLE_BYTES = 1024
MAX_JS_BYTES = 64 * 1024
USER_AGENT = "TaliaReciterCatalogVerifier/1.0"


class Hrefs(html.parser.HTMLParser):
    """Collect final path components from links in a directory listing."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.values: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() == "a":
            href = dict(attrs).get("href")
            if href:
                self.values.append(href.rsplit("/", 1)[-1])


def request(url: str, limit: int, headers: dict[str, str] | None = None) -> dict:
    """Read at most limit+1 bytes and retain response metadata or failure."""
    req = Request(url, headers={"User-Agent": USER_AGENT, **(headers or {})})
    try:
        with urlopen(req, timeout=TIMEOUT_SECONDS) as response:
            body = response.read(limit + 1)
            return {
                "ok": 200 <= response.status < 300,
                "status": response.status,
                "content_type": response.headers.get("Content-Type"),
                "content_length": response.headers.get("Content-Length"),
                "content_range": response.headers.get("Content-Range"),
                "body": body[:limit],
                "truncated": len(body) > limit,
            }
    except (HTTPError, URLError, TimeoutError, OSError) as exc:
        status = exc.code if isinstance(exc, HTTPError) else None
        return {"ok": False, "status": status, "error": f"{type(exc).__name__}: {exc}", "body": b""}


def expected_filenames(surahs: list[dict]) -> set[str]:
    return {
        f"{int(row['id']):03d}{ayah:03d}.mp3"
        for row in surahs
        for ayah in range(1, int(row["ayahCount"]) + 1)
    }


def listing_files(body: bytes) -> set[str]:
    parser = Hrefs()
    parser.feed(body.decode("utf-8", errors="replace"))
    return {
        value for value in parser.values
        if len(value) == 10 and value.endswith(".mp3") and value[:6].isdigit()
    }


def fetch_directory(name: str, expected: set[str]) -> dict:
    url = f"{BASE}{name}/"
    result = request(url, MAX_LISTING_BYTES)
    row = {key: value for key, value in result.items() if key != "body"}
    row.update({"directory": name, "url": url, "expected_ayah_files": len(expected)})
    if not result["ok"]:
        return row
    if result.get("truncated"):
        row["listing_error"] = f"listing exceeds {MAX_LISTING_BYTES} byte safety limit"
        return row
    body = result["body"]
    found = listing_files(body)
    missing = sorted(expected - found)
    extras = sorted(found - expected)
    row.update({
        "listing_bytes": len(body),
        "listing_sha256": hashlib.sha256(body).hexdigest(),
        "found_expected_ayah_files": len(expected) - len(missing),
        "missing_count": len(missing),
        "missing_identifiers": [item[:-4] for item in missing],
        "extra_count": len(extras),
        "extra_identifiers": [item[:-4] for item in extras],
    })
    return row


def has_mp3_header(body: bytes) -> bool:
    return body.startswith(b"ID3") or (
        len(body) >= 2 and body[0] == 0xFF and body[1] & 0xE0 == 0xE0
    )


def fetch_sample(name: str, surah: int, ayah: int) -> dict:
    filename = f"{surah:03d}{ayah:03d}.mp3"
    url = f"{BASE}{name}/{filename}"
    result = request(url, MAX_SAMPLE_BYTES, {"Range": f"bytes=0-{MAX_SAMPLE_BYTES - 1}"})
    body = result.pop("body")
    result.update({
        "directory": name,
        "filename": filename,
        "url": url,
        "mp3_header_detected": has_mp3_header(body),
        "sampled_bytes": len(body),
        "sample_sha256": hashlib.sha256(body).hexdigest() if body else None,
    })
    return result


def fetch_recitations_js() -> dict:
    url = f"{BASE}recitations.js"
    result = request(url, MAX_JS_BYTES)
    body = result.pop("body")
    result["url"] = url
    if result.get("ok"):
        result.update({
            "bytes_read": len(body),
            "sha256": hashlib.sha256(body).hexdigest(),
            "truncated": result.get("truncated", False),
            "source_metadata_excerpt": body.decode("utf-8", errors="replace")[:20000],
        })
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("audit_artifacts/reciters_2026_10_24/verification.json"),
    )
    args = parser.parse_args()
    args.root = args.root.resolve()
    args.output = args.output if args.output.is_absolute() else args.root / args.output
    allowed = (args.root / "audit_artifacts" / "reciters_2026_10_24").resolve()
    if args.output.resolve().parent != allowed:
        parser.error(f"output must be directly inside {allowed}")
    return args


def build_report(root: Path) -> dict:
    surahs = json.loads((root / "assets/data/surahs.json").read_text(encoding="utf-8"))
    expected = expected_filenames(surahs)
    reciters = [fetch_directory(name, expected) for name in CANDIDATES]
    samples = [fetch_sample(name, s, a) for name in CANDIDATES for s, a in SAMPLES]
    listings_complete = all(r.get("ok") and r.get("missing_count") == 0 for r in reciters)
    samples_passed = all(
        s.get("ok") and (s.get("content_type") or "").lower().startswith("audio/mpeg")
        and s["mp3_header_detected"] for s in samples
    )
    return {
        "checked_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_policy": "Read-only metadata and at most 1024 bytes per audio sample; no corpus downloads",
        "canonical_source": (root / "assets/data/surahs.json").relative_to(root).as_posix(),
        "canonical_surah_count": len(surahs),
        "canonical_ayah_count": len(expected),
        "reciters": reciters,
        "samples": samples,
        "recitations_js": fetch_recitations_js(),
        "technical_probe_passed": listings_complete and samples_passed,
        "rights": "Explicit reuse permission not verified; obtain rights review before release.",
        "review": "HTTP/MP3 headers do not verify audible content, ayah boundaries, riwayah or owner approval.",
    }


def main() -> int:
    args = parse_args()
    report = build_report(args.root)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    summary = {
        "output": str(args.output),
        "technical_probe_passed": report["technical_probe_passed"],
        "canonical_ayah_count": report["canonical_ayah_count"],
        "sample_count": len(report["samples"]),
        "missing_by_reciter": {r["directory"]: r.get("missing_count") for r in report["reciters"]},
    }
    print(json.dumps(summary, ensure_ascii=False))
    return 0 if report["technical_probe_passed"] else 2


if __name__ == "__main__":
    sys.exit(main())
