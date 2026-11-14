# Share Good link hosting

Status: **not deployed**. The rollout remains off until the domain, both signing fingerprints, staging verification, and the signed-device checks in `qa/share_good_runtime_qa.md` are approved.

1. Choose an HTTPS host and a static host that supports the exact `_redirects` token capture and query substitution shown here. Verify that behavior with a test token before using it; static hosting providers differ.
2. Obtain the SHA-256 certificate fingerprint for the release upload key from the release keystore and the Play App Signing certificate fingerprint from Play Console’s app-integrity page. They may differ. Obtain both from the authorized release owner; never put private keys in this directory.
3. Copy `.well-known/assetlinks.json.template` to `.well-known/assetlinks.json` in the deployment output and replace the placeholder string with both quoted, comma-separated SHA-256 fingerprints. Validate the resulting JSON. The template is intentionally not a usable association file.
4. Publish this directory's `index.html`, `_redirects`, and the generated `/.well-known/assetlinks.json` on the same HTTPS host without redirects, authentication, or HTML fallback for the association file. Confirm the association file is served as JSON and the invite path produces the intended 302 to the Play listing with `referrer=inv%3D<token>`.
5. Supply the same bare hostname through `SHARE_GOOD_LINK_HOST` in the external release Dart defines file and `ORG_GRADLE_PROJECT_shareGoodLinkHost`. Builds reject mismatches and invalid names. With neither configured, Android claims only `invalid.localhost` and the release gate requires rollout off.
6. Build the signed candidate, distribute via the Play test track, and complete every applicable row in the runtime QA record before any rollout decision. Android verification and deferred install must be checked on real devices; a successful build or HTTP response alone is not verification.

This static landing page contains no analytics or scripts. Invite links contain a bearer token: do not place real tokens in logs, screenshots, analytics, or this repository.
