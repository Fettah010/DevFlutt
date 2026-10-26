# ADR-008: Preferences, local database, offline sample, and checkout boundary

- Status: Accepted
- Date: 2026-10-26
- Deciders: DevFlutt maintainers
- Roadmap: v0.7.0

## Context

The v0.7 roadmap adds durable local storage, an offline-oriented feature, and a commerce foundation. These concepts need separate boundaries: non-sensitive preferences are not credentials; cached records are not server truth; queued local edits are not successful server writes; and a locally calculated cart estimate is not a checkout quote.

ADR-004 explicitly defers response-cache policy to this milestone. Existing `ApiClient` retries only safe idempotent methods and must not automatically replay non-idempotent checkout operations.

## Decisions

### Preferences

The `preferences` module uses Flutter's `SharedPreferencesAsync` behind an app-owned asynchronous `PreferencesStore` port. It exposes supported primitive values and remove/clear operations. It does not store tokens, passwords, payment data, or other secrets; those remain in `secure-storage`. A memory implementation is provided for deterministic tests.

### Relational local data

The `local-database` module uses Drift over SQLite. The template commits generated Drift source so generated apps compile without code generation during generation. It also declares `drift_dev` and `build_runner` as optional generated-project dev dependencies, allowing users to regenerate that source after editing tables. The database uses one app-owned filename, a stable schema version, explicit migrations, transaction-safe writes, and an in-memory constructor for tests.

Schema v1 contains local documents with a key, type, JSON payload and update timestamp. Schema v2 adds a pending-operation table with a stable operation ID, document key, operation kind, payload and enqueue time. Upgrade v1→v2 preserves all local documents. The database is local durable storage, not encrypted storage; sensitive records must use secure storage or an appropriately reviewed encrypted database.

### Offline reference feature and cache policy

The `offline-data` module depends on `local-database`, `networking`, and `navigation`. Reads use the local repository. A manual refresh fetches remote snapshots and updates records that have no pending local operation. Pending edits are retained. A conflict for the same document uses a visible local-wins demonstration policy and remains pending until an explicit successful refresh/acknowledgement. Each queued operation has a stable ID reused on replay. Queued writes are replayed only by explicit refresh; safe GET retries follow the existing networking policy. No automatic background worker or replay of unsafe HTTP methods is added.

Cache metadata records fetch/update time. The sample's remote snapshot freshness target is five minutes; stale data remains readable offline and is marked stale. Explicit refresh invalidates that freshness marker before the request and resets it only after a successful response. This is a bounded reference policy, not a generic authenticated-response cache.

### Commerce and checkout

The `commerce` module provides an in-memory demo catalog, immutable cart model, deterministic integer minor-unit arithmetic, and a checkout port/fake. Cart persistence is optional and is supplied by the explicit `commerce-persistence` module, which requires `local-database`. Checkout sends only item identifiers and quantities. The adapter response carries an authoritative server quote and order ID; the client estimate is display-only. Checkout is never put through automatic retry unless a provider-specific idempotency contract is added. No payment SDK or card data storage is included.

## Consequences

- Five opt-in module IDs are added: `preferences`, `local-database`, `offline-data`, `commerce`, and `commerce-persistence`; existing presets remain unchanged.
- The manifest may declare an optional `devDependencies` array. Older manifests continue to parse as having no dev dependencies. Generated `pubspec.yaml` separates runtime and development dependencies.
- Local data remains available offline, but background synchronization and cross-device merge guarantees are not claimed.
- The package set increases only in generated projects selecting the relevant module. License inventory and security audit must include each generated dependency combination.
- Future remote backends can implement the app-owned ports without changing feature/domain contracts.

## Revisit triggers

- A future synchronization service needs a different conflict policy or server operation protocol.
- The app stores sensitive relational data, requiring an encryption-at-rest decision.
- A real checkout provider requires a reviewed idempotency-key and payment-SDK contract.
- Drift's stable API or Android packaging changes the migration/runtime design.
