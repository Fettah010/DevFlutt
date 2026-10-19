# ADR-002: Mason-based code generation

- Status: Accepted
- Date: 2026-10-18
- Deciders: DevFlutt maintainers

## Context

v0.2.0 needs a generation pipeline that composes a Flutter project from a base scaffold and a set of
selected modules. The roadmap (§4.4) prefers "a Dart CLI using Mason-style bricks" unless the proof
of concept reveals a blocker. The generator must be deterministic, safe (temp-dir then move), and
must not regex-rewrite Dart/Gradle/manifest files.

## Options considered

1. **Mason (`package:mason`)** — reusable bricks, `MasonGenerator`, `DirectoryGeneratorTarget`,
   `FileConflictResolution`, hooks, and brick bundles. Verified publisher `brickhub.dev`, MIT,
   actively maintained (`mason` 0.1.3, `mason_cli` 0.1.4, published 2026-10-04).
2. **Custom renderer** — hand-rolled string templates and file writes. No dependency, but reinvents
   templating, conflict resolution, and composition, and is harder to test and maintain.

## Decision

Use Mason. The generator depends on `package:mason` (core only, not `mason_cli`). Bricks live under
`bricks/`; a `project` brick composes the base scaffold and each module brick contributes its own
files. Composition of shared files (for example `pubspec.yaml` dependencies) is done by the generator
computing the union and passing it as brick vars — never by regex rewriting.

## Evidence

- `mason` 0.1.3 and `mason_cli` 0.1.4 on pub.dev, verified publisher `brickhub.dev`, MIT, published
  2026-10-04 (checked 2026-10-18).
- Mason API: `MasonGenerator.fromBrick` / `fromBundle`, `DirectoryGeneratorTarget`,
  `FileConflictResolution`, `GeneratorHooks` (pub.dev documentation, checked 2026-10-18).
- Roadmap §4.4 and §7.3 (composition via explicit integration points and generated registries).

## Trade-offs

- Adds a dev-only dependency (`mason`) to the generator. Generated apps never depend on it.
- Mason's Handlebars-style templating is less powerful than a full programming language, which is a
  feature: it keeps templates declarative and reviewable.

## Consequences

- Bricks must declare a `brick.yaml` with a `mason` environment constraint compatible with 0.1.3.
- The generator must pin the Mason version and re-verify at each release.
- Brick bundles can be produced later (`mason bundle`) so the generator can ship without brick sources.

## Revisit triggers

- Mason becomes unmaintained or incompatible with the pinned Dart SDK.
- A composition need arises that Mason cannot express without regex rewriting.
