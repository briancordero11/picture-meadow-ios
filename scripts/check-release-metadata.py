"""Fail on missing release decisions. This cannot certify Apple approval or legal compliance."""
import argparse
import ipaddress
import json
import re
from pathlib import Path
from urllib.parse import urlsplit
from urllib.request import Request, urlopen


def public_https(value):
    if not isinstance(value, str) or not value or any(c.isspace() for c in value):
        return False
    try:
        url = urlsplit(value)
        host = (url.hostname or "").lower()
        if url.scheme != "https" or not host or url.username or url.password or url.fragment or url.query:
            return False
        if host in {"localhost", "example.com", "example.org", "example.net"} or host.endswith((".localhost", ".local", ".test", ".invalid", ".example", ".example.com", ".example.org", ".example.net")):
            return False
        if "." not in host or "$(" in value or "[" in value or "]" in value:
            return False
        try:
            return ipaddress.ip_address(host).is_global
        except ValueError:
            return True
    except ValueError:
        return False


def validate(metadata):
    problems = []
    publisher = metadata.get("publisherName")
    if not isinstance(publisher, str) or not publisher.strip() or any(x in publisher.lower() for x in ("placeholder", "your company", "[publisher", "todo")):
        problems.append("Set the actual legal publisher name.")
    email = metadata.get("supportEmail", "")
    if not isinstance(email, str) or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email) or not public_https("https://" + email.rsplit("@", 1)[-1]):
        problems.append("Set a real public support email.")
    for key in ("privacyPolicyURL", "supportURL"):
        if not public_https(metadata.get(key)):
            problems.append(f"Set a public HTTPS {key}; placeholder and local URLs are not release values.")
    audience = metadata.get("audience", {})
    if not isinstance(audience, dict):
        audience = {}
    if not isinstance(audience.get("kidsCategory"), bool):
        problems.append("Decide whether the app will use Apple's Kids Category.")
    if audience.get("kidsCategory") is True and audience.get("kidsAgeBand") not in {"5-and-under", "6-8", "9-11"}:
        problems.append("Choose the Kids Category age band: 5-and-under, 6-8, or 9-11.")
    low, high = audience.get("minimumAge"), audience.get("maximumAge")
    valid_low = not isinstance(low, bool) and isinstance(low, (int, float)) and 0 <= low <= 120
    # Once a minimum is specified, null maximum means an open-ended age range.
    valid_high = "maximumAge" in audience and (high is None or (not isinstance(high, bool) and isinstance(high, (int, float)) and valid_low and low <= high <= 120))
    if not valid_low or not valid_high:
        problems.append("Specify the intended audience age range.")
    elif audience.get("kidsCategory") is True and (high is None or high > 11):
        problems.append("Review the Kids Category choice against an audience range extending above age 11 or having no upper age limit.")
    countries = audience.get("launchCountries")
    if not isinstance(countries, list) or not countries or any(not isinstance(code, str) or not re.fullmatch(r"[A-Z]{2}", code) or code in {"XX", "ZZ"} for code in countries):
        problems.append("Choose actual launch countries using two-letter country codes; verify availability in App Store Connect.")
    reviewed = metadata.get("reviewed", {})
    if not isinstance(reviewed, dict):
        reviewed = {}
    required = ["privacyPolicy", "appPrivacyAnswers", "ageAssuranceForLaunchRegions", "parentalGateWithTargetAudience", "brandAndArtworkRights", "nativeDeviceTesting", "archivePrivacyManifest"]
    if metadata.get("onlinePreviewEnabled") is True or metadata.get("sceneGenerationEnabled") is True:
        if not public_https(metadata.get("apiBaseURL")) or urlsplit(metadata.get("apiBaseURL", "")).path not in {"", "/"} or urlsplit(metadata.get("apiBaseURL", "")).query:
            problems.append("Online preview requires a reviewed public HTTPS API origin without a query or path.")
        required.append("backendAndHostingRetention")
    if metadata.get("onlinePreviewEnabled") not in (True, False) or not isinstance(metadata.get("onlinePreviewEnabled"), bool):
        problems.append("Explicitly choose onlinePreviewEnabled true or false; the default app build is offline.")
    if not isinstance(metadata.get("sceneGenerationEnabled"), bool):
        problems.append("Explicitly choose sceneGenerationEnabled true or false; the default app build is offline.")
    if metadata.get("sceneGenerationEnabled") is True:
        if metadata.get("aiProviderName") != "OpenAI (direct)":
            problems.append("AI provider disclosure must match the backend's OpenAI (direct) route.")
        required.extend(["aiProviderRetentionAndNoTraining", "aiConsentAndAdultReview", "aiServiceAccessAndBudget", "aiFailureAndCancellation"])
    for item in required:
        if reviewed.get(item) is not True:
            problems.append(f"Complete and record the {item} review.")
    return problems


def check_public_page(url):
    # Optional publication check; contact details and policy accuracy still require review.
    with urlopen(Request(url, headers={"User-Agent": "WishExplorer-ReleaseCheck/1.0"}), timeout=15) as response:
        if not public_https(response.geturl()) or response.status != 200:
            return False
        kind = response.headers.get_content_type()
        return kind in {"text/html", "text/plain", "application/pdf"} and bool(response.read(512).strip())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("metadata", type=Path)
    parser.add_argument("--check-public-links", action="store_true")
    args = parser.parse_args()
    try:
        metadata = json.loads(args.metadata.read_text(encoding="utf-8-sig"))
        if not isinstance(metadata, dict):
            raise ValueError("Metadata must be a JSON object")
    except (OSError, ValueError) as error:
        parser.exit(2, f"Release metadata could not be read: {error}\n")
    problems = validate(metadata)
    if args.check_public_links and not problems:
        for key in ("privacyPolicyURL", "supportURL"):
            try:
                if not check_public_page(metadata[key]):
                    problems.append(f"{key} did not return a public readable HTTPS page.")
            except Exception as error:
                problems.append(f"{key} could not be checked ({type(error).__name__}).")
    if problems:
        print("NOT READY FOR SUBMISSION")
        for problem in problems:
            print(f"- {problem}")
        return 1
    print("Release metadata checks passed. This does not verify the native build, policy accuracy, regional legal obligations, or Apple approval.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
