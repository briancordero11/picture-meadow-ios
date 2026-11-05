"""Tests the release gate's failure cases without contacting external websites."""
import copy
import importlib.util
import json
import unittest
from pathlib import Path

base = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("release_metadata", base / "check-release-metadata.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReleaseMetadataTests(unittest.TestCase):
    def valid_record(self):
        # These are test fixtures, never app configuration or a publisher assertion.
        record = json.loads((base.parent / "config/release-metadata.example.json").read_text())
        record.update(publisherName="Test Publisher", supportEmail="test@apple.com", privacyPolicyURL="https://www.apple.com/legal/privacy/", supportURL="https://support.apple.com/")
        record["audience"].update(kidsCategory=True, kidsAgeBand="9-11", minimumAge=9, maximumAge=11, launchCountries=["US"])
        record["reviewed"] = {key: True for key in record["reviewed"]}
        return record

    def test_unfilled_template_is_not_submission_ready(self):
        example = json.loads((base.parent / "config/release-metadata.example.json").read_text())
        problems = module.validate(example)
        self.assertGreaterEqual(len(problems), 12)
        self.assertTrue(any("publisher" in problem for problem in problems))
        self.assertEqual(example["audience"]["launchCountries"], ["US"])
        self.assertFalse(any("launch countries" in problem for problem in problems))
        self.assertEqual(example["audience"]["minimumAge"], 2)
        self.assertIsNone(example["audience"]["maximumAge"])

    def test_offline_record_still_requires_completed_reviews(self):
        record = self.valid_record()
        self.assertEqual(module.validate(record), [])
        record["reviewed"]["nativeDeviceTesting"] = False
        self.assertIn("Complete and record the nativeDeviceTesting review.", module.validate(record))

    def test_local_insecure_placeholder_and_tracking_urls_are_rejected(self):
        for url in ["http://real-site.org/privacy", "https://localhost/privacy", "https://127.0.0.1/privacy", "https://192.168.1.2/privacy", "https://policy.example.com", "https://site.invalid", "https://user:password@site.org", "https://site.org/privacy?token=secret", "https://site.org/#fragment", "$(PRIVACY_URL)"]:
            with self.subTest(url=url):
                self.assertFalse(module.public_https(url))

    def test_online_configuration_requires_retention_review_and_clean_origin(self):
        record = self.valid_record()
        record.update(onlinePreviewEnabled=True, apiBaseURL="https://api.apple.com")
        record["reviewed"]["backendAndHostingRetention"] = False
        self.assertTrue(any("backendAndHostingRetention" in problem for problem in module.validate(record)))
        record["reviewed"]["backendAndHostingRetention"] = True
        record["apiBaseURL"] = "https://api.apple.com/some-path"
        self.assertTrue(any("API origin" in problem for problem in module.validate(record)))

    def test_audience_and_boolean_decisions_are_explicit(self):
        record = self.valid_record()
        record["audience"]["launchCountries"] = []
        self.assertTrue(any("launch countries" in problem for problem in module.validate(record)))
        record = self.valid_record()
        record["audience"]["maximumAge"] = 18
        self.assertTrue(any("above age 11" in problem for problem in module.validate(record)))
        record = self.valid_record()
        record["onlinePreviewEnabled"] = "NO"
        self.assertTrue(any("Explicitly choose" in problem for problem in module.validate(record)))

    def test_open_ended_audience_still_needs_category_review(self):
        record = self.valid_record()
        record["audience"].update(kidsCategory=False, kidsAgeBand="", minimumAge=2, maximumAge=None)
        self.assertEqual(module.validate(record), [])
        record["audience"]["kidsCategory"] = True
        record["audience"]["kidsAgeBand"] = "5-and-under"
        self.assertTrue(any("no upper age limit" in problem for problem in module.validate(record)))
        del record["audience"]["maximumAge"]
        self.assertIn("Specify the intended audience age range.", module.validate(record))


if __name__ == "__main__":
    unittest.main()
