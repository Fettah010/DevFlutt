# Security baseline

What the generated project does about security by default, what it explicitly does not do,
and how each claim is checked. This is a baseline, not a certification. It does not claim
[OWASP MASVS](https://mas.owasp.org/MASVS/) compliance; it maps the relevant checklist items
to the controls the template ships and the steps that verify them.

## What the template guarantees

| Control | Where | Verified by |
| --- | --- | --- |
| HTTPS-only production base URL, with the scheme and host validated at startup | `core/config/app_config.dart` | `app_config_test.dart` |
| Configuration errors never repeat the offending value | `AppConfig.fromWire`, `AppConfig` | `app_config_test.dart` |
| No secret, token, or authorization header reaches a log sink | `core/logging/redactor.dart` | `logging_test.dart` redaction corpus |
| The response body of a failed request is not carried in the error | `core/networking/api_error.dart` | `networking_test.dart` |
| A non-idempotent request is never replayed automatically | `core/networking/retrying_api_client.dart` | `networking_test.dart` |
| Session secrets go through a small interface, not through the plugin directly | `core/secure_storage/secure_store.dart` | `secure_store_test.dart` |
| Encrypted values are never restored without their Keystore key | `android/app/src/main/res/xml/backup_rules.xml` | merged-manifest inspection |
| The generated project adds no Android permission of its own | the module manifests | merged-manifest inspection |
| No provider SDK, no telemetry, no analytics in the default presets | the module manifests | the absence tests in the generator |
| Committed secrets fail CI | `.github/workflows/ci.yml` (`secret-scan`) | the gate self-test |
| Known-vulnerable dependencies fail CI | `.github/workflows/ci.yml` (`dependency-audit`) | the scan output |
| Every locked dependency's licence is inventoried | `THIRD-PARTY-NOTICES.md` | `license-inventory` job |

## What the template does not do

These are backend responsibilities, or deliberate non-goals. The template never implies
otherwise.

- **Authorization, rate limiting, MFA policy, and session revocation are server
  responsibilities.** A client-side check is a convenience, never a security boundary.
- **No secret is ever shipped in the bundle.** The template carries no credential, no
  signing material, and no service-account key. Production values are injected through a
  protected environment or secret store outside the repository.
- **Obfuscation and generated constants are not a secret vault.** A value in the binary is
  extractable.
- **The redaction is a heuristic, not a proof.** A field that is neither named like a
  credential nor shaped like one is logged. Add new sensitive shapes to the corpus.
- **There is no crash-reporting or analytics provider.** The interface exists; the adapter
  does not. Adding one is a separate, reviewed module that states the data it collects.
- **iOS is unverified.** No macOS host or runner is available, so the iOS build of the new
  modules has not been observed.
- **No real-device run.** The functional evidence is from an emulator or a build host, which
  is proxy evidence for device-specific behaviour.

## Threat-model boundary

Untrusted inputs the template does handle:

- compile-time configuration values, which are validated at startup;
- response bodies, which are decoded by a caller-supplied function and reported as
  `ApiMalformedError` when they do not match;
- unknown route locations, which resolve to the not-found screen;
- log field names and values, which are redacted before a sink sees them.

Untrusted inputs the template does not handle, and leaves to the application:

- anything the user types into a form;
- deep-link parameters beyond the path;
- content of any file the application reads.

## MASVS mapping

| MASVS area | Template control | Verification |
| --- | --- | --- |
| V1 — Architecture, Design, and Verification | One documented architecture; the composition root picks the implementations | the generated-project matrix |
| V2 — Encryption | `flutter_secure_storage` with RSA-OAEP and AES-GCM; the backup exclusion | the module tests and the merged manifest |
| V3 — Secure Authentication and Session Management | Deferred to v0.5.0; the `SecureStore` interface is the seam it will use | — |
| V4 — Network Security | Typed client, timeouts, cancellation, bounded retry, no body in errors | `networking_test.dart` |
| V5 — Sensitive Data Protection | Redaction by default; no secrets in the bundle; no telemetry | the redaction corpus, the secret scan |
| V8 — Data Storage | The backup exclusion; no permission added | the merged manifest |
| V10 — Malicious Code | The dependency audit and the licence inventory | the CI jobs |
| V14 — Configuration | Typed, validated configuration; the debug/release logging floor | `app_config_test.dart` |

## Reporting a vulnerability

See `SECURITY.md` at the repository root.
