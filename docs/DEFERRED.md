# Deferred backlog

Out-of-scope discoveries, recorded rather than implemented. Every entry names the problem,
the evidence, the value, the likely milestone, the dependencies, and the risk.

## The authentication form and its states

Problem: an application with an authentication adapter has no way to sign in. The
contract provides the operations, but there is no form, no validation, and no busy,
success, failure, offline, or recovery state.
Evidence: the road map §6.2 requires that auth forms have validation, busy, success,
failure, offline, and recovery states, and that the UI must not treat local form
validation as server security. The `v0.8.0` milestone covers "polished UI states" and
lists the form fields among the core UI components.
Value: an application can reach a signed-in state without writing its own form, and the
states are consistent across providers.
Likely milestone: v0.8.0.
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
`v0.9.0` maximum-capability composition depends on it.
Value: a networked application can use a hosted data service.
Likely milestone: unscheduled; it must land before the v0.9.0 hardening milestone.
Depends on: a per-service selection, so the whole Firebase surface is not selected by
one package.
Risk: medium. A data backend brings its own permissions, its own security rules, and its
own cost model, and the template must not imply that a client-side rule is a server-side
one.

## The response cache and the token-storage policy

Problem: an authenticated client caches nothing, and the policy for what may be persisted
is not written down.
Evidence: ADR-004 defers both to v0.6.0, where the persistence and offline modules
arrive. The road map §5.4 requires a cache to state expiration, invalidation, offline
behaviour, and what is safe to persist.
Value: a networked application can cache without guessing.
Likely milestone: v0.6.0.
Depends on: the persistence modules.
Risk: low.

## The exhaustive module-combination matrix

Problem: the built matrix covers the four presets and the three authentication presets. It
does not cover every combination of the modules that can coexist.
Evidence: the road map §9.4 requires the pairwise set and the maximum-capability
composition at the hardening milestone, and the `v0.9.0` milestone completes the
compatibility matrix.
Value: a reviewer knows exactly which combinations are proven and which are not.
Likely milestone: v0.9.0.
Depends on: nothing.
Risk: low, as long as the gap is stated rather than implied away.
