"""Network-boundary regressions for the reciter evidence command."""

import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[2] / "scripts/verify_reciter_catalog.py"
SPEC = importlib.util.spec_from_file_location("reciter_verifier", SCRIPT)
verifier = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verifier)


class HttpResponse(io.BytesIO):
    status = 200

    def __init__(self, body, content_type="text/html"):
        super().__init__(body)
        self.headers = {"Content-Type": content_type}


class ReciterVerificationTest(unittest.TestCase):
    def run_verification(self, listing, sample=b"ID3\0\0", content_type="audio/mpeg"):
        temporary_root = SCRIPT.parent.parent / "build/reciter_verifier_tests"
        temporary_root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=temporary_root.resolve()) as directory:
            root = Path(directory)
            source = root / "assets/data/surahs.json"
            source.parent.mkdir(parents=True)
            source.write_text('[{"id":1,"ayahCount":2}]', encoding="utf-8")

            def respond(request, **_):
                if request.full_url.endswith(".mp3"):
                    return HttpResponse(sample, content_type)
                if request.full_url.endswith(".js"):
                    return HttpResponse(b"{}", "application/javascript")
                return HttpResponse(listing)

            with (
                patch.object(verifier, "CANDIDATES", ["Example"]),
                patch.object(verifier, "SAMPLES", [(1, 1)]),
                patch.object(verifier, "urlopen", side_effect=respond),
                patch.object(sys, "argv", [str(SCRIPT), "--root", str(root)]),
                patch("sys.stdout", new_callable=io.StringIO),
            ):
                exit_code = verifier.main()
            evidence = root / "audit_artifacts/reciters_2026_10_24/verification.json"
            return exit_code, json.loads(evidence.read_text(encoding="utf-8"))

    def test_complete_catalog_excludes_extra_basmalah_tracks(self):
        listing = b'<a href="001001.mp3">1</a><a href="001002.mp3">2</a><a href="001000.mp3">extra</a>'
        exit_code, report = self.run_verification(listing)
        self.assertEqual(exit_code, 0)
        self.assertEqual(report["reciters"][0]["missing_identifiers"], [])
        self.assertEqual(report["reciters"][0]["extra_identifiers"], ["001000"])

    def test_missing_ayah_fails_even_when_http_succeeds(self):
        exit_code, report = self.run_verification(b'<a href="001001.mp3">1</a>')
        self.assertEqual(report["reciters"][0]["missing_identifiers"], ["001002"])
        self.assertEqual(exit_code, 2)

    def test_non_audio_responses_cannot_pass_as_audio_samples(self):
        listing = b'<a href="001001.mp3">1</a><a href="001002.mp3">2</a>'
        for body, content_type in [(b"<html>error</html>", "text/html"), (b"ID3", None)]:
            with self.subTest(content_type=content_type):
                exit_code, _ = self.run_verification(listing, body, content_type)
                self.assertEqual(exit_code, 2)


if __name__ == "__main__":
    unittest.main()
