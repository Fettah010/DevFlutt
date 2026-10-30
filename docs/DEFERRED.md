# Deferred backlog

Out-of-scope discoveries, recorded rather than implemented. Every entry names the problem,
the evidence, the value, the likely milestone, the dependencies, and the risk.

## The authentication form and its states

Problem: an application with an authentication adapter has no way to sign in. The
contract provides the operations, but there is no form, no validation, and no busy,
success, failure, offline, or recovery state.
Evidence: the road map §6.2 requires that auth forms have validation, busy, success,
failure, offline, and recovery states, and that the UI must not treat local form
validation as server security. The `v0.9.0` milestone covers "polished UI states" and
lists the form fields among the core UI components.
Value: an application can reach a signed-in state without writing its own form, and the
states are consistent across providers.
Likely milestone: v0.9.0.
Depends on: `auth-core` and one adapter; the design-system module for the widgets.
Risk: low. The form is a thin layer over the adapter, and the contract already defines
the failure cases it has to show.

## Social sign-in

Problem: no adapter can sign a user in with Google, Apple, Facebook, or another social
provider.
Evidence: each social provider needs provider-console setup, platform-specific
configuration, and a redirect that only the developer can choose. The road map §6.2 makes
social sign-in an opt-in subfeature for that reason, and the `v0.5.0` Implement list
requires the subfeature only "where the provider path can be tested/documented
correctly". The capability descriptor reports `social-sign-in` as unsupported for every
adapter.
Value: applications that need social sign-in get a tested path rather than an untested
one.
Likely milestone: unscheduled.
Depends on: the `google_sign_in` package, a deep-link scheme, and provider-console
configuration that cannot be exercised in CI.
Risk: medium. A social sign-in path that is not exercised against the real provider is
easy to get wrong, and the failure is silent until a user tries it.

## Multi-factor authentication, phone sign-in, and anonymous sign-in

Problem: the authentication contract does not model them, although Firebase and Supabase
support them.
Evidence: the `v0.5.0` exit criteria name the operations the milestone must cover, and
these are not among them. The contract is deliberately small.
Value: applications that need a second factor can add it without a contract change.
Likely milestone: unscheduled.
Depends on: a contract change, which is a public-surface change.
Risk: medium. Multi-factor authentication has a recovery path and a re-enrolment flow, and
the contract has to model them or the feature will be pushed into feature code.

## The data-backend adapters

Problem: there is no `--backend` option, so an application cannot select Firestore,
Postgres, Storage, Realtime, or Edge Functions.
Evidence: the road map §6.3 lists the backend choices, and requires the generator to
represent the auth decision and the backend decision separately instead of using one
overloaded `backend` flag. The `v0.5.0` Implement list contains no data-backend adapter.
ADR-006 reserves the `--backend` name for the milestone that adds them, and the
`v0.10.0` maximum-capability composition depends on it.
Value: a networked application can use a hosted data service.
Likely milestone: unscheduled; it must land before the v0.10.0 hardening milestone.
Depends on: a per-service selection, so the whole Firebase surface is not selected by
one package.
Risk: medium. A data backend brings its own permissions, its own security rules, and its
own cost model, and the template must not imply that a client-side rule is a server-side
one.

## The response cache and the token-storage policy

Problem: the reference sample has no generic authenticated-response cache, and its
persistence policy applies only to the sample's notes.
Evidence: ADR-004 deferred response-cache behavior to v0.7.0. The v0.7 persistence and
offline sample states its own expiration, invalidation, offline
behaviour, and what is safe to persist.
Value: a networked application can cache without guessing.
Likely milestone: future; v0.7.0 delivers a bounded local-first notes example, not a generic
authenticated-response cache.
Depends on: a separate cache policy and implementation.
Risk: low.

## The exhaustive module-combination matrix

Problem: the built matrix covers the four presets, the three authentication presets, and
the five v0.7 persistence/commerce compositions individually. It does not cover every
combination of the modules that can coexist.
Evidence: the road map §9.4 requires the pairwise set and the maximum-capability
composition at the hardening milestone, and the `v0.10.0` milestone completes the
compatibility matrix.
Value: a reviewer knows exactly which combinations are proven and which are not.
Likely milestone: v0.10.0.
Depends on: nothing.
Risk: low, as long as the gap is stated rather than implied away.

## Patrol coverage for generated projects

Problem: Patrol currently exercises the reference app, not every generated preset or
module composition.
Evidence: the reference Patrol workflow now launches the actual DevFlutt app, while the
former matrix used a synthetic widget. Generated-project native UI coverage needs a
harness that launches each generated app's own entry point.
Value: UI behavior can be proven for generated output without presenting a synthetic test
as product evidence.
Likely milestone: v0.10.0 integration hardening.
Depends on: a generated-project Patrol harness that uses the generated test bundle and
Android host configuration.
Risk: medium. Running a full generated UI matrix adds emulator time and maintenance; keep
the fast generator build/test matrix as the baseline.

## Scheduled v0.7.0 release job lacks Git identity

Problem: the scheduled release workflow cannot create its annotated tag because its Git
runner has no committer identity configured.
Evidence: GitHub Actions run
[40537208016](https://github.com/Fettah010/DevFlutt/actions/runs/40537208016) failed at
the tag step with `fatal: empty ident name`; the `v0.7.0` tag and pre-release were later
published and verified at `e3584db`.
Value: scheduled releases can complete without relying on a separate manual recovery.
Likely milestone: maintenance before the next release workflow is used.
Depends on: the release workflow's Git tag creation and repository identity policy.
Risk: low for the already-published v0.7.0 release; medium for a future release if the
workflow still attempts to create a tag without configuring an identity.

## v0.8.0 physical-device and Play-track verification

Problem: local generated-project checks cannot prove notification lifecycle behavior on
physical hardware or a real Play in-app update flow.
Evidence: generated-module tests and Android builds pass locally; the available API 36 AVD
configuration files contain unresolved placeholders and fail to start. No physical device
or Play internal-testing track is available in this environment.
Value: confirms permission prompts, notification tap routing, background execution, and
Play update behavior beyond fake-backed tests and build-time evidence.
Likely milestone: v0.8.0 release gate.
Depends on: a valid API 33+ emulator or owner-provided Android device and a signed build
published to a Google Play internal-testing track.
Risk: high; the release must remain blocked until these behaviors are tested and recorded.
