# Flutter Android App Template — Agent Execution Protocol

> **Purpose:** Permanent operating rules for AI coding agents building and maintaining the Flutter Android App Template (blank-first GitHub template + bundled project generator) from `v0.1.0` through `v1.0.0` and its maintenance releases.
>
> **Execution mode:** Autonomous inside the approved roadmap; evidence-based research that changes decisions; strict milestone boundaries; small verified slices; tiered verification that is cheap while iterating and strict at release; commit / PR / merge / tag / release automation only when every applicable gate passes and repository permissions allow it.
>
> **Document role:** This file defines *how* work is planned, executed, verified, and delivered. The canonical roadmap defines *what* ships and *in which order*. Neither duplicates the other.
>
> **Protocol version:** 1.0 (prepared 2026-10-18). Derived from the WPF agent protocol, adapted for Flutter/Dart/Android and a generator-based product, with a resumable agent loop and tiered verification added.

---

## 0. The loop at a glance (read this first)

```text
P0 Orient      → verify repo, releases, toolchain, host capabilities; pick the milestone
P1 Research    → only decisions that change the plan; reuse the research cache
P2 Plan        → docs/releases/<version>-plan.md → mark Ready (readiness checklist)
P3 Slice       → one task ID at a time: test → implement → V1 check → record evidence → commit
P4 Integrate   → merge slices, keep a draft PR + CI running in parallel with local work
P5 Verify      → V2 milestone gate, then V3 release gate on the exact candidate commit
P6 Report      → finish the living report from the evidence ledger (not from memory)
P7 Deliver     → PR checks green → merge → tag → GitHub Release → verify remotely
P8 Handoff     → update roadmap status, leave next milestone untouched, final status message
```

Always:

1. **Resume, don't restart.** Read the plan's *Resume block* before anything else; continue from the last verified state.
2. **Cheapest check first, strictest check last.** Iterate with V0/V1; reserve V2/V3 for gates.
3. **Evidence or it did not happen.** Every claim carries a status word from §9.11.
4. **Stay in the milestone.** Out-of-scope discoveries go to `docs/DEFERRED.md`, not into the diff.
5. **Fix problems at the source.** A defect in generated output is fixed in the brick/template/generator and covered by a regression test — never patched in one generated copy.
6. **Ask only when blocked.** Discover facts yourself; batch unavoidable questions with a recommended default (§3.3).

---

## 1. Governing documents and authority

### 1.1 Files and resolved paths

Resolve these at P0 and record the actual paths in the version plan. Follow existing repository structure; never create duplicates or silently move documents.

| Role | Default path | Notes |
|---|---|---|
| This protocol | `FLUTTER-AGENT-EXECUTION-PROTOCOL.md` (repo root) | `AGENTS.md` must point to it. |
| Canonical roadmap | `Flutter-Android-App-Template-Roadmap-v0_1_0-to-v1_0_0.md` (repo root) | Roadmap §10 names a `ROADMAP.md`. Keep exactly **one** canonical roadmap file; if renamed, do it deliberately, record it, and update `AGENTS.md`. |
| Agent entry point | `AGENTS.md` | Created in the first milestone if absent (§19). |
| Version plan / report | `docs/releases/<version>-plan.md`, `docs/releases/<version>-report.md` | One pair per version. |
| ADRs | `docs/adr/ADR-NNN-<slug>.md` | Roadmap §10 shows both `docs/adr/` and `docs/DECISIONS/`; resolve once in the first milestone (default `docs/adr/`) and record it. |
| Deferred backlog | `docs/DEFERRED.md` | Out-of-scope discoveries. |
| Research cache | `docs/research/<topic>.md` | Dated findings reused across milestones (§6.2). |
| Manifests / presets / schema | `manifests/modules/`, `manifests/presets/`, `manifests/schema/` | Contract files for the generator. |
| Testing / compatibility | `docs/TESTING.md`, `docs/COMPATIBILITY.md` | Canonical commands and the tested matrix. |

### 1.2 Authority order

1. Explicit user instructions for the current task.
2. This protocol — process, scope discipline, safety, verification, delivery.
3. The canonical roadmap — **single source of truth for release order, milestone scope, and intended outcomes.**
4. Accepted ADRs, module manifests/schema, and established repository conventions (when they do not conflict with 1–3).
5. The current version plan — operationalizes the roadmap milestone; may refine but never broaden it.
6. Existing code, test output, package metadata, third-party examples — all must be **checked, not presumed correct**.

Do not copy the release sequence into this protocol or create a competing roadmap. If the roadmap is missing, unreadable, or materially inconsistent with repository state: inspect tags/releases/reports, record the discrepancy, complete only work that is independent of the dispute, and block the disputed work until the user resolves it. Never guess the next milestone.

### 1.3 Reading map (context efficiency)

Do not load the whole roadmap on every task. Read in full once per session: roadmap §1–§2 (promise, non-goals, decisions), the **current milestone's section in §11**, the matching parts of §12, and this protocol's §0–§4. Then read by task type:

| Task type | Also read |
|---|---|
| Generator, manifests, presets | Roadmap §4, §7, §9.1; ADR-002; manifest schema; existing generator tests |
| Architecture, state, routing | §5; ADR-001, ADR-003 |
| Auth, networking, storage | §5.4, §6.2–§6.4, §8; ADR-004–006 |
| Persistence, offline, commerce | §6.4–§6.5; ADR-005 |
| Android platform services | §6.6–§6.7; ADR-007–008; `android/` and Gradle config |
| UI, localization, accessibility | §6.8; design-token and l10n files |
| Dependencies | §13 and the package review checklist |
| Release / maintenance | §9.3–§9.4, §12, §14 |
| Before the final diff review | §15 (anti-patterns) |

Use targeted search (`grep`/`rg`, symbol search) instead of re-reading unchanged files. Keep a short *read set* in the plan's Resume block so a resumed session does not repeat reads.

---

## 2. Non-negotiable operating rules

1. **Plan before implementation.** Each version has a saved, readiness-checked plan before production code or new feature tests change.
2. **Autonomous within scope.** Make routine decisions from evidence and conventions (§4.2). Autonomy never widens scope.
3. **The roadmap owns release order.** No skipping, combining, reordering, or starting future milestones.
4. **Research must change a decision.** Compare real alternatives; validate material uncertainty with inspection, a prototype, a test, or a measurement.
5. **Test as you build.** Features ship with tests; fixes ship with regression tests; focused checks run immediately.
6. **No false green.** Required-but-skipped, zero-test, unobserved-CI, unexplained-warning, or unverified results block the gate. A planned run is not a pass.
7. **The product is the generated output.** The template repo building is not proof that generated projects work. Test the actual generated projects (§9.4–§9.5).
8. **Optional means absent.** Unselected modules leave no files, dependencies, imports, routes, registrations, permissions, config keys, or runtime behaviour — and this is verified, not assumed.
9. **Blank stays blank.** The blank preset makes no network calls, requests no unnecessary permissions, and carries no optional dependency, telemetry, or demo content.
10. **Smallest justified design.** No speculative abstractions, no dependency without a demonstrated need, no framework-within-a-framework, no placeholder integrations presented as finished.
11. **Security and privacy are baseline.** No secrets in Git; no client-side "secret" claims; server-side responsibilities stated, not implied.
12. **Platform honesty.** Android background timing, Play-backed updates, notification permissions, and iOS support are documented and claimed exactly as far as they were tested.
13. **Gates are never weakened to get green.** No deleting/skipping tests, loosening analyzer rules, widening tolerances, or adding blanket `continue-on-error` without a documented, dated, scoped decision.
14. **Recoverable repository.** Preserve user changes and history; never force-push, rewrite shared history, move or delete published tags/releases, expose secrets, or bypass branch protection.
15. **Contracts are deliberate.** CLI flags, module IDs, manifest schema, preset contents, and generated layout change only per §15.
16. **Truthful delivery.** Report local commit, pushed branch, PR, merge, tag, GitHub Release, and every other channel separately.
17. **Reproducible.** Pinned toolchain, committed lockfile, deterministic generation, documented commands.

---

## 3. Operating loop and agent efficiency

### 3.1 Phases, artifacts, and exit conditions

| Phase | Work | Exit condition / artifact |
|---|---|---|
| **P0 Orient** | §5 preflight: Git/release state, toolchain, host capability ledger, baseline | Milestone confirmed; baseline recorded; Resume block started |
| **P1 Research** | §6: only questions that change a decision; reuse research cache | Findings in plan/research note; ADRs drafted where required |
| **P2 Plan** | §7: write plan, change-impact map, claim ledger, owner-action register | Readiness checklist passes → status `Ready` |
| **P3 Slice** | §8.1 loop per task ID | Task `Done` with evidence entry and (usually) a commit |
| **P4 Integrate** | Rebase/merge slices; push branch; open **draft** PR early so CI runs alongside local work | Branch buildable; CI feedback arriving |
| **P5 Verify** | §9: V2 milestone gate, then V3 release gate on the exact candidate commit | All required gates `Verified`; no blocker (§12.6) |
| **P6 Report** | §13: finalize the living report from the evidence ledger | Report complete except post-publication identifiers |
| **P7 Deliver** | §12: PR checks green → merge → tag → Release → remote verification | Remote state verified, or precise blocker recorded |
| **P8 Handoff** | §14: roadmap status, final message | Next milestone untouched |

Phases may be revisited (a failed V3 returns to P3). Skipping P2 or P5 is never allowed.

### 3.2 Efficiency rules

- **E1 Cheapest first.** Order checks: format → analyze → focused tests → broader tests → builds → matrices → device runs. Stop at the first failure and fix it before running more expensive checks.
- **E2 Scope to the change.** During slices, run only checks selected by the change-impact map (§9.3). Run full suites at V2/V3.
- **E3 Parallelize independent work.** Run independent commands concurrently; start CI early; do research and baseline measurement while other tasks proceed. Never parallelize edits to the same file or interdependent Git operations.
- **E4 Reuse caches, never results.** Pub/Gradle caches are fine. A result obtained on a *different commit* is not evidence for the current one.
- **E5 Fix at the brick.** Change the template/brick/generator, regenerate, and verify — do not hand-edit generated samples.
- **E6 One pass per file where possible.** Plan edits per file; avoid repeated read–patch–read churn; avoid re-reading unchanged files.
- **E7 Batch questions.** Group unavoidable user questions into one message with a recommended default for each.
- **E8 Loop breaker.** Same root cause not fixed after three distinct attempts → stop, write a short hypothesis log (tried / observed / ruled out), change approach (smaller repro, bisect, different tool) or mark the task `Blocked` with a recovery path (§8.6).
- **E9 Delegate with a contract.** If the harness supports sub-agents, delegate only independent, bounded work (research on one question, triage of one failing job, one module's tests) with a written brief: goal, scope limits, files allowed, output format, evidence required. The main agent owns decisions and verifies delegated results before relying on them.

### 3.3 Communication

- Post a brief update (3–6 lines) at each phase boundary and when blocked: what is done, what is next, what needs the user (if anything). Not per command.
- Ask the user only when safe progress is impossible or a product decision would change (§4.2, level C). Offer a recommended default.
- Never end a turn with a question that inspecting the repository, docs, or CI could have answered.
- Never announce completion because code was written. Completion is evidence-backed acceptance.

---

## 4. Scope, autonomy, and risk

### 4.1 In-scope rule

A task is in scope only if it directly advances the current roadmap milestone or is the smallest prerequisite needed to make that work correct, secure, testable, or maintainable. Every task has a stable ID (`T01…`) and maps to at least one acceptance criterion.

When you find unrelated improvements: do not implement them. Add an entry to `docs/DEFERRED.md` (problem, evidence, value, likely milestone, dependencies, risk) and continue.

If in-scope work exposes a blocker in earlier foundations, make only the minimum fix, record why, add a regression test, and do not use it as a reason for refactoring. Adjacent "easy wins" because a package makes something simple are scope creep (roadmap §11 preamble).

### 4.2 Autonomy ladder

| Level | Examples | Action |
|---|---|---|
| **A — decide** | File/class naming inside conventions, test structure, internal helper shape, small in-scope refactors, commit slicing | Decide; no record needed beyond the diff |
| **B — decide and record** | Choosing among roadmap-listed package candidates, internal API shape of a new module, tolerance values, generator internals, a plan clarification | Decide from evidence; record in plan/research note/ADR as §6.5 requires |
| **C — propose, don't implement** | Changing milestone scope/order, replacing a roadmap default outside its ADR, adding a proprietary or paid service dependency, adding a delivery channel the roadmap omits, breaking a released contract (§15), reversing an accepted ADR, ambiguous license, anything needing credentials the agent does not have | Write a proposal (evidence, options, impact, recommendation); continue independent work; stop only the disputed change |

### 4.3 Risk tiers (rigor scales with risk; release gates never scale down)

| Tier | Typical work | Additional required practice |
|---|---|---|
| **R1 low** | Docs, copy, internal refactor under existing tests | V0/V1 checks |
| **R2 standard** | Feature code, module templates, CLI options, UI components | Tests in the same slice; V1; change-impact gates |
| **R3 high** | Auth/session/token refresh, secure storage, networking retry/idempotency, native Android/Gradle/manifest, generator write/overwrite/composition logic, schema/migration code, security controls, anything handling sensitive data | **Failing test first** (show it red where practical); explicit edge-case list (concurrency, cancellation, expiry, malformed input, partial failure); research note or ADR; self-review against the threat model; relevant matrix subset before each commit; second review pass of the diff before merge |

Classify each task in the plan. When unsure, pick the higher tier.

### 4.4 Milestone-sensitive controls

These are **process gates, not a second roadmap**. The roadmap retains authority over milestone content and order. Apply the ones that match the current milestone's theme.

- **Foundation / blank milestone:** pin and record the Flutter/Dart/JDK/Gradle/Android SDK toolchain; prove clean-clone build; prove CI propagates failure (gate self-test, §9.2); prove the blank app is network-free and permission-minimal using the **merged release manifest** (Flutter's debug/profile manifests add `INTERNET` for tooling — do not confuse them with release); document an observed first run.
- **Generator / manifest milestone:** validate before writing; write to a temporary directory then move; never mutate unrelated files; schema-version every manifest; deterministic output (including line endings on Windows vs POSIX); actionable diagnostics; test Windows and at least one POSIX path.
- **Architecture / navigation milestone:** validate Riverpod and routing choices with a prototype before locking ADRs; test cold-start deep link, unknown route, redirect loops, and unknown/loading session state; keep registrations generator-controlled.
- **Networking / logging / secure-storage milestone:** fake transport for deterministic tests; redaction tests with a regression corpus; retry only for idempotent requests; cancellation and timeout tests; confirm blank/core outputs contain none of these dependencies.
- **Auth / backend milestone:** one shared contract-test suite run against every adapter; capability descriptors instead of pretending parity; serialized token refresh with a concurrency test; no real keys anywhere; live provider flows are **owner-action** items unless credentials and a test project are provided (§9.10).
- **Persistence / offline / commerce milestone:** keep schema fixtures and test upgrades from the previous schema; state the conflict policy per sync sample; never call caching "sync"; server-authoritative pricing/totals; no card data stored or logged.
- **Android platform-services milestone:** WorkManager semantics (no exact-time promises); Android 13+ notification permission requested in context; exact alarms avoided; Play in-app update claims require Play internal-testing evidence — otherwise claim only fallback/contract behaviour; native code isolated under `android/` behind adapters; iOS generation rejects Android-only modules cleanly; permission diff appears in the generation summary.
- **Localization / accessibility / motion milestone:** `gen-l10n`, English + Arabic RTL, long-string and mixed-direction tests, text scaling, semantics/focus order, reduced-motion handling for template-owned animation; blank output stays free of l10n/gallery assets unless selected.
- **Hardening / RC milestone:** complete the full compatibility matrix, real-device smoke, performance/size baselines, security review mapped to the threat model and relevant MASVS items; **no features** — release blockers and necessary corrections only; any change after freeze restarts RC validation.
- **Stable milestone:** exact-commit full gate from a clean checkout; tag-to-commit identity proof; docs verified against actual generated output; repository flagged as a template (owner action if not permitted to the agent).

### 4.5 Roadmap updates

Update milestone status only after evidence exists. Do not change future milestone intent during implementation. If research proves an outcome invalid, submit a proposal (evidence, alternatives, scope/version impact, contract impact, release consequence) and do not implement it meanwhile.

---

## 5. Preflight (P0)

Record results in the plan. Do not assume anything this section can check.

**Repository state.** `git status --short --branch`; current branch; recent commits; remotes; tags; existing releases (`gh release list` when available); previous plan/report; whether the target version already has commits, tag, release, or plan. Treat uncommitted/untracked files as user work unless proven otherwise; never discard, overwrite, stage, or commit them. If the tree is dirty, work on a separate branch and do not claim a clean baseline. Resume from verified state instead of duplicating work.

**Greenfield case.** If no earlier milestone exists (first run), there is no previous plan/report; verify the repository, create the minimum documents required by the first milestone, and record that this was a greenfield start.

**Toolchain and host capability ledger.** Record: Flutter and Dart versions (`flutter --version`), `flutter doctor -v` summary, JDK, Gradle/AGP, Android SDK/cmdline-tools, emulator or attached device, OS/shell (Windows PowerShell vs POSIX), `git`, `gh`, network access, available scanners. Then mark each gate in §9 as **runs locally**, **runs in CI only**, or **unavailable (reason)**. Examples: iOS builds need macOS (CI runner or Mac); Play-backed update tests need Play internal testing; live Firebase/Supabase flows need a configured project. Unavailable gates must be routed to CI or recorded as owner action — never silently dropped.

**Baseline.** Run the repository's verify command (or the individual commands) on the starting commit. Separate pre-existing failures from failures introduced by this milestone. Record exact commands and results.

**Owner-action register.** Start a list of things only the repository owner can do (Actions secrets, branch protection, "template repository" setting, Play Console/internal testing, Firebase/Supabase projects, signing custody). Keep it current; surface it in the report.

Never write tokens, keystores, connection strings, or private paths into plans, logs, commits, or screenshots.

---

## 6. Research (P1)

### 6.1 When to research

| Research | Skip research |
|---|---|
| Choosing or upgrading a package/plugin; Flutter/Dart/AGP/Gradle changes | Facts already in a *fresh* research-cache entry (§6.2) |
| Android platform behaviour or policy (background work, notifications, permissions, Play updates, target SDK) | Ordinary Dart/Flutter coding questions answerable from the SDK source/docs already present |
| A security- or privacy-sensitive design (auth, storage, logging, analytics) | Conventions already decided by an accepted ADR |
| Generator/composition strategy, schema design | Naming, formatting, file placement |
| Any claim you are about to make about the outside world | Re-surveying the ecosystem when nothing material changed |

Start with the code and tests; go external only for questions that can change a decision. Time-box each question; if it is still unresolved, prototype or measure rather than reading more.

### 6.2 Sources and freshness

Prefer, in order: official documentation and platform guidance (Flutter, Dart, Android Developers, pub.dev package pages/changelogs, OWASP MASVS); upstream source, tags, licenses, issues/discussions; reproducible benchmark or local prototype; secondary articles only as supplements. Popularity (stars, downloads) is a signal, not a decision.

**Research cache.** Store dated findings in `docs/research/`. Reuse an entry if it is still applicable and within its freshness window; otherwise re-verify.

| Fact type | Re-verify when |
|---|---|
| Package versions, SDK constraints, advisories | At plan time, and again at the release gate if >14 days old |
| Licenses and publisher/maintenance status | At adoption and when the version changes |
| Android policy/API behaviour, Play requirements | Each milestone that relies on it |
| Flutter/Dart stable versions | At plan time and at the release gate |
| Architecture/pattern rationale (ADRs) | Only at their stated revisit triggers |

The roadmap's snapshot values (versions, star counts) are historical — never reuse them as fresh facts.

### 6.3 Record format (actionable findings only)

For each significant question record: **Question → Options (real candidates) → Evidence (URL, version/tag, date checked) → Finding (and remaining uncertainty) → Impact → Decision → Validation**. A list of links is not research. Distinguish measured values from estimates. Never invent benchmark numbers, package status, license text, or CI results.

### 6.4 Package review

For every new or upgraded nontrivial dependency, complete the roadmap §13 checklist (publisher, cadence, SDK/platform compatibility, license, issues/security, transitive count, tests, size contribution, why SDK-native is insufficient, replacement plan). Prefer stable, permissively licensed packages; a pre-release package needs a documented material benefit and fallback. Do not add or upgrade merely because a newer version exists.

### 6.5 ADRs

The roadmap §2 lists ADR-001–ADR-009. Create each ADR in the first milestone that depends on it, run a *focused proof of concept* where the roadmap says to, and reference it from the plan. An ADR states context, options, decision, evidence, trade-offs, consequences, and revisit triggers (§16.5). Do not silently reverse an accepted ADR: research the case, document migration impact, and stop the disputed change if it is outside existing approval. Small implementation choices do not need an ADR; an ADR is a record of an evaluated decision, not a reason to delay obvious work.

---

## 7. Version plan (P2)

**The plan must be saved and checked before implementation.** Research, inspection, baseline verification, and planning documents are allowed first.

Location: `docs/releases/<version>-plan.md` (verify the version against the roadmap and live release state). Use the outline in §16.1. Proportionality rule: keep every section concrete and short — a plan is a working instrument, not an essay. Omit a section only with an explicit reason.

### 7.1 Plan features that make execution efficient

- **Resume block** (top of file): current phase, last completed task ID, next action, open blockers, last verified commit and commands, read set. Update it at every slice commit and at every phase boundary so any session can resume cold.
- **Task table** with IDs, dependencies, risk tier (R1–R3), likely paths, definition of done, verification. Group independent tasks into **waves** so parallel work is obvious.
- **Change-impact → gate selection** (from §9.3, customized): which checks run per slice and which run at V2/V3 for *this* milestone.
- **Claim ledger:** the specific claims this release will make (for example "all five presets build", "blank is network-free", "refresh is serialized"), each mapped to the evidence that will support it. Anything without a planned verification is not claimed.
- **Owner-action register** and **host capability ledger** snapshots from P0.
- **Non-goals pulled from later milestones**, named explicitly.

### 7.2 Plan readiness checklist (all must be true before `Ready`)

- [ ] Milestone confirmed against roadmap, live tags/releases, and previous report (or greenfield start recorded).
- [ ] Repo state, toolchain, host capability ledger, and baseline results recorded.
- [ ] Material decisions have dated evidence and a recommendation; required ADRs drafted.
- [ ] Every task maps to current-milestone scope, an acceptance criterion, and a risk tier.
- [ ] Every acceptance criterion has a verification method and a gate (V1/V2/V3).
- [ ] Test, matrix, performance, accessibility, security/license, and documentation impacts considered.
- [ ] Risks, rollback/recovery, and owner actions defined.
- [ ] Plan does not silently change roadmap scope, architecture, public contracts, or dependency policy.

### 7.3 Amending the plan

Clarify the plan when discoveries invalidate an assumption: record the evidence, the impact on tasks/tests/risks/criteria, and keep the change inside the milestone. Never loosen an acceptance criterion to fit an implementation. If an adjustment effectively adds a feature, changes a public contract, replaces a chosen library, or expands supported scope, do not implement it incidentally — defer it or raise a level-C proposal. Fixing a defect required by existing criteria is not scope expansion.

---

## 8. Implementation (P3, P4)

### 8.1 The slice loop (one task ID at a time)

1. **Re-read** the task, its acceptance criteria, and risk tier.
2. **Test first** when practical — mandatory and shown red for R3 tasks and bug fixes.
3. **Implement** the smallest maintainable change that satisfies the criterion.
4. **Run V1** (§9.1) for the paths touched; fix failures before moving on.
5. **Review the diff** (`git diff`, `git diff --check`): scope, secrets, local paths, accidental generated files, unrelated formatting, new permissions or dependencies.
6. **Record** an evidence entry (§16.3) and update the task status and Resume block.
7. **Commit** the coherent, passing slice with explicit file staging (§12.1).

Keep the repository buildable after each slice. Do not defer tests or integration to the end. Do not commit knowingly broken work (documentation-only planning commits may be labelled as such).

### 8.2 Dart/Flutter engineering standards

- Follow existing conventions; if none exist, define them once and document them.
- Use the ADR-approved state, routing, and HTTP choices consistently; do not add second-class alternatives (no parallel BLoC/Provider support in v1.0).
- Feature-first structure with lightweight layers; add a domain layer only when business rules or multiple implementations justify it. Do not create empty layers or folders for appearance.
- UI never touches raw HTTP clients, secure storage, or database APIs. Provider SDK types stay behind adapters; features use app-owned models, errors, and results.
- Typed configuration validated at startup with actionable errors; no secrets in bundles; HTTPS-only production endpoints.
- Respect cancellation, async error handling, disposal, and lifecycle (the process may be killed; in-memory state does not persist).
- Prefer `const`, null-safety discipline, small files, readable code. No `print` in app code (use the logging interface), no blanket `// ignore` or `ignore_for_file`, no dead code, no placeholder TODO architecture.
- Localizable user-facing strings where localization is selected; logical (direction-aware) layout, not hand-reversed rows.
- Animation uses template motion tokens and honours reduced motion; no decorative animation that costs startup or input latency.
- Do not add telemetry, authentication, remote calls, scheduled work, or background services without explicit module selection and documentation.
- Dependency injection and registrations through generated registries or documented integration points — never ad-hoc global state.

### 8.3 Generator and module standards

- The generator is a development tool; generated apps never depend on it or on the template repository at runtime.
- Use templates for known files; use bounded, tested insertion points or generated registries for composition. **No broad regular-expression rewriting of Dart, Gradle, or manifest files.**
- Every generated file has an ownership class: *generator-owned*, *developer-owned*, or *generated-once-and-user-editable*. Where safe regeneration cannot be guaranteed, generate once and document.
- Validate names, paths, IDs, and selections **before** writing; write to a temporary directory, verify, then move into place; never leave a half-generated destination; never overwrite a non-empty directory without the documented explicit behaviour.
- Use `package:path` and process APIs; never assume `/` separators or shell semantics. PowerShell and Windows paths are first-class; normalize line endings so output is identical across hosts (enforce with `.gitattributes`/writer settings and verify by diffing).
- No timestamps, random IDs, or host-specific paths in generated source. Machine-readable metadata (template version, module versions, SDK constraints, required native setup) goes in a documented file.
- Every module has: a manifest that validates against the schema, a module README, tests, a removal-behaviour test, and a compatibility entry.
- Each real compatibility bug gets a permanent test case (roadmap §7.4 item 8).

### 8.4 Android native standards

- Prefer a maintained Flutter plugin; add Kotlin/Gradle code only where plugins cannot reasonably provide the behaviour, isolated behind a platform adapter with documented channel interfaces and tests for failure and unsupported-platform behaviour.
- Every permission, manifest entry, exported component, and backup rule has a named feature owner and a documented reason. No unused permissions by default.
- Android-only APIs never appear in shared Dart paths without a platform guard or adapter.
- No signing material, keystore passwords, `key.properties`, `local.properties`, or real `google-services.json` in Git or templates; placeholders must be unmistakably inert.
- Record minimum SDK, compile/target SDK, JDK, Gradle/AGP, and Kotlin versions with the tested toolchain; changes are reviewed, not incidental.

### 8.5 Mid-version changes

Follow §7.3. Re-check the claim ledger whenever a plan adjustment is made.

### 8.6 Failure handling and the loop breaker

- A failing test is a real result. Reproduce, diagnose, determine whether it is pre-existing or introduced, fix in-scope causes, and add a regression test.
- Never remove or skip a failing test to proceed. Quarantine a flaky test only with: reproduction evidence, a tracked issue/deferred entry, an owner, a review date, and a replacement coverage plan — and it must not be a required release-gate test without an explicit decision.
- Apply E8: after three distinct failed attempts at the same root cause, stop and write a hypothesis log; then bisect, minimize the repro, or change approach. If still blocked, mark the task `Blocked` with evidence and a recovery path, continue independent tasks, and surface it.
- If the plan itself proves wrong, amend it (§7.3) rather than working around it.

---

## 9. Verification (P5)

Verification is continuous and tiered. The tiers keep iteration fast without lowering the release bar.

### 9.1 Verification tiers

| Tier | When | Contents |
|---|---|---|
| **V0 — edit loop** | After every meaningful edit | `dart format` on touched files; `flutter analyze` (or `dart analyze` for pure-Dart packages) on touched packages |
| **V1 — slice gate** | Before each commit | V0 + focused tests for touched paths (`flutter test <path>` / `dart test <path>`) + the change-impact checks in §9.3 that are marked V1 |
| **V2 — milestone gate** | Before the PR is marked ready | Full format/analyze/unit/widget/CLI tests; manifest validation; static matrix; built matrix for affected modules and presets; debug + release Android builds; security/dependency/license checks; docs/link checks; generated-project checks (§9.5) |
| **V3 — release gate** | On the exact candidate commit from a clean checkout/CI | Everything in V2 for the **full** matrix; real-device/emulator smoke; performance/size comparison; fresh-version rechecks (§6.2); artifact checks; tag-readiness checks |

Failing at a lower tier is fixed at that tier — do not escalate to expensive runs to discover cheap failures.

### 9.2 Command discovery and truthfulness

- Discover the repository's real commands (scripts under `tool/`, `Makefile`/task files, CI workflows) and document the canonical set in `docs/TESTING.md`. Do not invent command names. Flutter/Dart SDK commands are standard (`flutter pub get`, `flutter analyze`, `flutter test`, `dart test`, `flutter build apk --debug`, `flutter build appbundle --release`, `flutter gen-l10n`, `flutter pub outdated`, `dart pub deps`, `dart format --output=none --set-exit-if-changed .`); use `--enforce-lockfile` where the pinned SDK supports it so a verify run cannot silently change dependencies.
- A `tool/verify.*` wrapper (Windows and POSIX) must **print every command, propagate every exit code, and write per-command logs** to an ignored directory (for example `build/verify-logs/`). It must never end with an unconditional success message.
- **Gate self-test:** at least once per milestone that touches CI or `tool/verify`, deliberately introduce a known failure on a throwaway branch (failing test, analyzer error, bad manifest) and observe the gate go red. Record it. A gate that was never seen failing is unproven.
- **Zero-test guard:** confirm tests actually executed. Assert non-zero executed counts, expected matrix size (N cases enumerated = N cases run), and that required integration/device tests were not skipped.
- Record for every check: exact command, environment (OS, shell, Flutter/Dart versions), exit code, concise result, log path or CI run ID. Warnings are reviewed, not hidden.

### 9.3 Change-impact → required checks

Select checks from what changed. When a change touches several rows, run the union. "V1" = before commit; "V2/V3" = at the gates.

| Change touches | Required checks |
|---|---|
| Docs only | V1: link/anchor check, consistency with code and roadmap. V3: docs verified against actual generated output |
| App code under `lib/` or tests | V1: format, analyze, affected tests. V2: full unit+widget, debug build |
| `pubspec.yaml`, lockfile, SDK pins | V1: `pub get` (lockfile-enforced), analyze, full tests. V2: dependency/license/vulnerability scan, preset rebuilds. V3: freshness recheck |
| `bricks/`, manifests, presets, schema | V1: manifest/schema validation, **static matrix** (§9.4), absence checks, determinism diff. V2: **built matrix** for affected modules + presets. V3: full built matrix |
| Generator/CLI code | V1: CLI unit tests; e2e temp-dir generation; dry-run accuracy; safe-overwrite cases; Windows path cases. V2: Windows + one POSIX run (CI acceptable) |
| `android/`, Gradle, manifests, native bridge | V1: debug build; merged-manifest permission diff; native/platform-adapter tests. V2: release/AAB build, emulator smoke. V3: real-device smoke for permissions/lifecycle |
| Auth, session, network, storage, logging | V1 (R3): red-first tests; shared contract tests; concurrency/refresh tests; redaction tests; secret scan. V2: log inspection across regression tests; logout/clear-data tests |
| UI, theme, l10n, accessibility, motion | V1: widget tests, semantics, text scale, RTL, reduced motion. V2: manual accessibility checklist for high-impact flows. Goldens (if adopted): generate and compare on the **same CI platform only** — font rendering differs across OSes; review every changed baseline intentionally |
| CI workflows / verify scripts | V1: run on a branch; gate self-test (§9.2) |
| Performance-sensitive paths | V1: targeted profile-mode measurement vs baseline. V3: full comparison (§9.8) |

### 9.4 Generator and compatibility matrix policy

The generated project is the product. Use a **two-tier matrix** — cheap enough to run constantly, rigorous at release.

**Static matrix (cheap; every generator/manifest change).** Enumerate every valid combination the validator accepts and every combination it must reject. For each, generate with `--no-pub` into a temp directory and check, without building: validator accept/reject decision and message quality; file list vs dry-run; `pubspec.yaml` dependencies vs manifests; imports, routes, registrations, permissions, config keys, and native entries match the selection; **no residue** from unselected modules.

**Built matrix (expensive; scoped by impact at V2, complete at V3).** Fully build and test:

1. every named preset (`blank`, `core`, `recommended`, `commerce`, `full`, plus any later documented preset) against each supported backend choice it claims;
2. each module in isolation with only its declared prerequisites;
3. the documented pairwise set over compatible modules, plus targeted high-risk combinations (auth × navigation, storage × auth, background × notifications × navigation, offline × commerce, localization × UI);
4. the maximum-capability Android composition;
5. the blank output separately, with absence enforced;
6. iOS/cross-platform smoke for the shared core and modules advertised as iOS-compatible (§9.6);
7. one regression case per historical compatibility bug.

Check the computed matrix, the pairwise method, and known gaps into `docs/COMPATIBILITY.md`. Never say "all combinations passed" unless the matrix actually was exhaustive; report the exact coverage method and residual gaps.

**Additional generator checks:** generate the same inputs twice into different directories and diff — output must be identical; compare the dry-run report to the real output (files, dependencies, permissions, native changes); verify safe-overwrite and failure paths leave no half-written destination; verify invalid input fails with a non-zero exit code and an actionable *what / why / how-to-fix* message; verify `--yes` never skips validation.

### 9.5 Generated-project checklist

For every generated project in the built matrix: scaffold into a clean temporary directory **outside the repository** (isolated config/cache where practical; share the pub/Gradle caches for speed); then check

- names, package ID, application ID, namespaces, paths, SDK constraints, version metadata, template-origin marker, module manifest file, and generated docs;
- residue: unresolved template tokens, template-repo names, absolute local paths (`C:\`, `/Users/`, `/home/`), sample secrets, disabled-module files/dependencies/imports/routes/permissions, generator source, dead files;
- `pub get`, formatter, analyzer (warnings as errors where the repository policy says so), code generation if selected, generated tests, `flutter build apk --debug`, and a release compile for the named presets;
- merged release manifest: permissions and exported components match the selection exactly;
- the generated project works with no access to the template repository.

Preserve per-run logs and a summary as CI artifacts; remove only the temporary directories the run created.

### 9.6 Android, device, and iOS evidence

- Document and test the Android minimum SDK, compile/target SDK, JDK, Gradle/AGP, and Flutter/Dart range actually used.
- Emulator results are valid for functional smoke but **proxy evidence** for device-specific behaviour (permissions UX, OEM battery policy, performance). Release candidates need at least one real low/mid-range Android device run; record model, Android version, build, and limitations.
- Native/behaviour claims need native-level evidence: permission denial, background retry/reschedule, lifecycle, notification tap → route, update unsupported/failed/cancelled states.
- Play-backed update availability can only be claimed after Play internal-testing evidence. Without it, claim "fallback and contract behaviour tested; Play flow not exercised" and register an owner action.
- **iOS:** iOS builds require macOS. Claim iOS compatibility only for the shared core and modules whose generation **and build smoke** ran on a macOS runner or machine and were observed. If none is available, state iOS as *unverified* and ensure Android-only modules are rejected for iOS-only projects. Never generate broken native code silently.

### 9.7 Security and privacy verification

- Run secret scanning and dependency-vulnerability scanning with actively maintained tools (for example gitleaks for secrets and OSV-Scanner for `pubspec.lock`; verify availability and current status before relying on them); record tool, version, scope, findings, and triage. Passing a scanner is not a safety claim. Accepted exceptions need rationale, owner, and review date.
- Review each permission/manifest diff; review deep-link parsing and exported components; confirm no disabled TLS validation, no cleartext production endpoints, no secrets in logs.
- Log-redaction regression tests must cover tokens, auth headers, passwords, personal payloads, and payment-like fields.
- Blank output: observe zero network activity and no telemetry; verify statically (no networking/telemetry dependencies or imports) and by an observed run where practical.
- Map relevant OWASP MASVS items to validation steps; never claim full MASVS compliance.
- Server-side responsibilities (authorization, rate limiting, MFA, revocation, recovery) are documented as backend duties and never implied by client code.

### 9.8 Performance and size

- Measure in **release or profile** builds only (never debug). Useful tools: `flutter build apk --analyze-size`, `flutter run --profile --trace-startup`, `integration_test` performance tracing, DevTools.
- Establish baselines for blank, core, recommended, and full outputs: app size, startup to first usable frame, memory, representative-screen jank. Record device/emulator model, Android version, build mode, and sample count; report **median and range** (≥5 runs where practical).
- Investigate any unexplained regression >10% (roadmap §9.4); adjust tolerance only after recording why the measurement is noisy or inappropriate. Do not relax a ratified budget silently.
- Label emulator or faster-host numbers **proxy/provisional**. A claim that requires a real-device result may not be supported by proxy data; defer the claim or mark the gate blocked.
- Report per-module cost only when repeatable; never call modules "lightweight" without data.

### 9.9 Accessibility and localization

Where relevant verify: semantic labels and focus order; text scaling; contrast; tap-target size; keyboard/switch navigation where relevant; Arabic RTL and LTR layouts; long and mixed-direction strings; locale-aware formatting; reduced motion (honour the platform animation setting for template-owned animation); notification-permission UX; theme light/dark. Automated checks do not replace a manual review of high-impact flows; record both.

### 9.10 Environment limits and owner-dependent checks

If a required check cannot run here (no macOS, no device, no Play testing, no provider project/credentials): say precisely why, route it to CI or the owner, and record it as **Not run** or **Owner action** — not Verified. If a *required* gate stays unavailable, do not publish; mark the version `Blocked`, preserve reproducible work, and state the recovery path. Contract tests with fakes are real evidence of contract behaviour and must be labelled as such; they are not evidence that a live provider flow works.

### 9.11 Claim vocabulary

Use these terms exactly in plans, reports, PRs, and final messages.

| Term | Meaning |
|---|---|
| **Verified** | Observed this session on the stated commit with command and result recorded |
| **Verified (CI)** | Remote CI run observed *completed* and green, with run ID; required jobs actually executed |
| **Contract-tested** | Passed against fakes/mocks only; live behaviour not exercised |
| **Proxy** | Evidence from a non-reference environment (emulator, faster host); labelled, never equated with device proof |
| **Not run** | Not executed; reason given |
| **Unverified** | Inferred or expected; no evidence |
| **Owner action** | Requires credentials/permissions/hardware only the owner has |

"Queued", "should pass", "passed earlier on another commit", and "passed locally but CI not observed" are all **not Verified (CI)**.

---

## 10. Dependencies, licensing, and supply chain

- Keep an auditable inventory (`THIRD-PARTY-NOTICES.md` plus dependency review notes) and a committed lockfile for the reference app and generated apps; pin the toolchain used by CI.
- For each nontrivial dependency record purpose, exact version, upstream URL, license source, SDK/platform compatibility, transitive/native footprint, maintenance evidence, alternatives, test evidence, and removal cost. Re-check against primary sources at implementation time.
- No dependency without a demonstrated need. No competing suite (second state manager, second router, second HTTP stack) without comparison, proof of concept, conflict and license review, and an ADR.
- Do not copy substantial code, bricks, or assets from third-party templates without a license check and attribution; the roadmap's reference projects are ideas to evaluate, not code to paste.
- Do not vendor source, alter licenses, or ship unlicensed assets. Do not claim an audit is complete if tooling or metadata was unavailable — state the limitation.
- Upgrade by reviewed change: update locks, run the relevant matrix, record migration notes. Never bulk-upgrade to the newest versions.
- No runtime network request or telemetry by default in `blank`, `core`, or `recommended` unless the preset explicitly includes and explains it.

---

## 11. Documentation and repository hygiene

Keep documentation proportional and decision-oriented; traceability, not paperwork. Maintain the documents listed in roadmap §10 by `v1.0.0`; adapt to existing structure and do not duplicate equivalent files.

```text
FLUTTER-AGENT-EXECUTION-PROTOCOL.md      # this process contract
Flutter-Android-App-Template-Roadmap-…md # canonical product roadmap
AGENTS.md                                # agent entry point (points to both)
README.md  CHANGELOG.md  CONTRIBUTING.md  SECURITY.md  THIRD-PARTY-NOTICES.md
docs/
  releases/<version>-plan.md | <version>-report.md
  adr/ADR-NNN-*.md        research/        DEFERRED.md
  ARCHITECTURE.md  MODULES.md  COMPATIBILITY.md  SECURITY-BASELINE.md
  TESTING.md  RELEASING.md  UPGRADING.md  modules/<module>.md
```

- Update docs in the same milestone as behaviour changes. Each new module ships its README (setup, capabilities, limits, provider-side steps, removal behaviour, test plan).
- `docs/UPGRADING.md` explains that "Use this template" copies a snapshot and that later template commits do not flow into copies; keep per-release upgrade notes.
- README quickstart must work for a new developer without private credentials; test it exactly as written at each RC/stable gate.
- The demo/showcase content is optional output, never part of the blank app and never a required dependency of any other preset.

---

## 12. Git, pull request, and release (P4, P7)

The user authorizes autonomous Git and release operations **only when every applicable gate passes** and repository policy allows them. This never authorizes destructive history operations, bypassing protection, exposing secrets, or ignoring gates.

### 12.1 Branches and commits

- Work on a dedicated branch (for example `work/<version>` or the repository convention); do not implement a release directly on the default branch when PRs are supported.
- Small, coherent, passing commits; one slice or tightly related slices each. Conventional Commits (or `type(scope): summary` if none is adopted). Do not claim unverified outcomes in messages.
- Stage explicit files; inspect `git status`, `git diff --check`, and the staged diff first. Exclude secrets, local config, build output, temporary benchmarks, generated verification logs, and unrelated user work.

### 12.2 Early draft PR and CI feedback

After the first green slice, push the branch and open a **draft** PR (when permissions allow) so CI runs in parallel with local work. Treat CI results as feedback, but only completed, observed, green required jobs count as Verified (CI). Keep the PR description current: milestone, scope, risks, links to plan/report, evidence summary. Mark ready only after V2.

### 12.3 Integration

1. Re-run candidate checks from a clean or controlled checkout and inspect the full final diff.
2. Push; update the PR; verify every required check **completed successfully and executed its required cases** (a green check with skipped required tests is not a pass).
3. Merge only when required checks pass and branch protection, permissions, and mandatory reviews allow it. If policy needs a human review, stop at that boundary.
4. Never bypass protection, disable a required check, force-push, or rewrite shared history. Follow a repository's documented alternative model only when allowed, and record why.

If authentication, access, protection, review, or CI blocks a step, stop there, preserve commits and results, and report exactly what remains. Do not claim a push, merge, or check unless the remote confirms it.

### 12.4 Versioning, tags, and artifacts

- Keep the version consistent across `pubspec.yaml`, CLI version output, template metadata, changelog heading, tag, and release notes. SemVer; roadmap milestones define the sequence.
- Tag `v<version>` at the exact verified release commit. Confirm the tag does not exist; never move, replace, or reuse a published tag. A fix after a failed release gate goes on a **new commit** and reruns the full V3 gate — do not patch and retag.
- Pre-1.0 milestones and RC iterations are published as GitHub **pre-releases** unless the user directs otherwise; only the stable milestone is a normal release. Decide and document the RC iteration naming scheme in the repository's release conventions during the first milestone, then follow it.
- Build artifacts only with documented reproducible commands. Check existence, names, versions, checksums (SHA-256), signatures if used, and absence of debug symbols, credentials, internal logs, or personal paths. Never attach signing keys or keystores.
- After publishing, verify remotely: tag, tag→commit identity, release page, assets, checksums. Record proof in the report.
- At the stable milestone also verify the repository's template-repository flag (for example `gh repo view --json isTemplate` when available); if the agent cannot set it, register an owner action.

### 12.5 Independent delivery channels

Report each channel separately with its own status. Publish a channel only when the roadmap/plan includes it, its exact artifact was built and verified, credentials are configured, and its channel tests passed.

| Channel | Notes |
|---|---|
| Local commit / pushed branch / PR / merge | Distinct states; remote-verified |
| Git tag | Created at verified commit; remote-verified |
| GitHub Release (+ assets, checksums) | Pre-release or stable per §12.4 |
| Template-repository flag | Owner action if not permitted |
| CLI distribution artifacts | Only if the roadmap/plan adds them; verify generate-from-artifact separately from generate-from-source |
| pub.dev, Play Store, signing, other registries | **N/A unless the roadmap adds them.** Never publish speculatively; never fabricate a push; if a required channel needs owner credentials, report *not published — owner action required* with the exact action |

Never label a milestone "fully published" if a required channel is incomplete.

### 12.6 Release blockers

Do **not** tag or publish if any apply:

- a required restore/build/test/CI gate failed, is unverified, or was queued but not observed complete;
- required integration/device tests did not execute, or unexpected skips exist;
- a named preset, claimed module, required pairwise/high-risk combination, or the maximum-capability composition is broken or unverified;
- a generated project contains residue from unselected modules, undeclared permissions, sample secrets, or generator/template dependencies;
- generation is non-deterministic, dry-run disagrees with output, or an invalid selection does not fail before writing;
- untriaged critical/high security findings, committed secrets/signing material, or missing license/dependency evidence;
- a claim requiring real-device or Play or macOS evidence rests only on proxy or no evidence;
- a public contract, ADR-required decision, or architecture change lacks its record;
- documentation contradicts actual generated output or the commands do not work as written;
- an in-scope P0/P1 defect remains;
- artifacts are missing, inconsistent, unverified, or contaminated;
- repository protections or permissions do not allow the operation.

Fix in-scope blockers; otherwise mark the version `Blocked` with evidence and a recovery path. Do not reduce the gate to obtain a release.

---

## 13. Completion report and evidence ledger (P6)

`docs/releases/<version>-report.md` is a **living document**: create the skeleton when the plan becomes `Ready` and append evidence as slices complete. Writing the report from memory at the end is a quality risk and a time cost.

- **Evidence ledger:** one entry per verification (§16.3): ID, task, tier, commit, command, environment, result, log/CI link. The acceptance table cites entry IDs.
- **Scope audit:** each task and acceptance criterion marked passed / failed / deferred / blocked with evidence IDs.
- Include research/ADR outcomes (and material alternatives rejected), exact commands and CI run IDs, skipped/unavailable checks with reasons, matrix coverage actually exercised (with method and gaps), performance data with hardware labels, security/dependency/license results, owner actions, known issues, Git evidence, release-channel table, and reproduction/recovery steps.
- Concrete over vague: "all tests passed" is not acceptable; name the checks.
- After publication, append verified remote identifiers (release URL, tag commit, checksums).

Use the template in §16.2.

---

## 14. End-of-version handoff (P8)

A version is complete only when required acceptance criteria are Verified, the report is written, in-scope docs are current, and Git/release status is accurately recorded.

1. Update the roadmap's status for the milestone from report evidence only.
2. Confirm no accidental uncommitted implementation changes; never erase legitimate user changes to force cleanliness.
3. Verify the published tag/release points to the intended commit (if publishing was possible).
4. Leave the next milestone unimplemented. Useful preparation may be recorded in `docs/DEFERRED.md`, research notes, or ADR drafts — never delivered as functionality.
5. Update the Resume block to `Complete` with the next milestone pointer.
6. Emit the final status message (§18).

The next version restarts at P0.

---

## 15. Contract stability (CLI, modules, schema, generated output)

Stability tightens as the project matures:

| Phase | Rule |
|---|---|
| **Pre-1.0 development milestones** | Changes to CLI flags, module IDs, manifest schema, preset contents, or generated layout are allowed when needed, but each must be listed in `CHANGELOG.md` with an upgrade note, and (once users could plausibly automate a released flag) deprecated with a compatibility period rather than silently renamed or repurposed |
| **Hardening and RC** | Public flags, module IDs, schema, presets, and directory conventions are **frozen**. Only release blockers and necessary corrections; any change to the frozen surface restarts RC validation |
| **1.x and later** | SemVer. Breaking CLI flags, module IDs, manifest schema, generated public contracts, default presets, or SDK floors require a major version; add options compatibly; pin manifest/schema versions to the generator and fail safely on unsupported versions |

Inventory the contract surface (flags, module IDs, schema fields, preset expansions, generated file ownership, config keys, template metadata) in the docs and treat any change as a contract change. Do not promise automated updates of generated apps: until a safe, tested migration engine exists, provide upgrade notes, template-origin markers, manifests, and compare-with-upstream guidance (roadmap §6.7).

---

## 16. Templates

### 16.1 Version plan — `docs/releases/<version>-plan.md`

```markdown
# <VERSION> — <Milestone Name> Plan

- Status: Draft | Ready | In Progress | Blocked | Complete
- Prepared: YYYY-MM-DD
- Roadmap section: <heading/link>
- Branch / starting commit: <verified>
- Previous version: <tag, report, commit> (or: greenfield start)

## 0. Resume block
- Phase: P_ | Last completed task: T__ | Next action: <one line>
- Open blockers: <none | list> | Last verified commit/commands: <hash + evidence IDs>
- Read set: <files/sections already read this milestone>

## 1. Outcome and success definition
## 2. Current repository state, toolchain, host capability ledger, baseline
## 3. Research (Question | Options | Evidence + date | Finding | Decision | Validation)
## 4. In scope
## 5. Out of scope (including features not to be pulled forward)
## 6. Design / architecture (components, boundaries, contracts, fallbacks, ADR links)
## 7. Tasks
| ID | Task | Wave | Deps | Risk R1–R3 | Likely paths | Definition of done | Verification |
## 8. Acceptance criteria
| ID | Observable criterion | Evidence required | Gate V1/V2/V3 |
## 9. Claim ledger (each release claim → supporting evidence)
## 10. Change-impact → gate selection for this milestone; matrix definition and coverage method
## 11. Performance and size plan (metrics, environments, baseline, tolerance; proxy vs real)
## 12. Security, privacy, accessibility, localization notes
## 13. Dependency / license / security impact
## 14. Documentation and examples to update
## 15. Risks and mitigations; rollback/recovery
## 16. Git, PR, and release plan; owner-action register
## 17. Deferred work
## 18. Plan-readiness checklist (§7.2)
## 19. Progress log (append-only, one line per slice)
```

### 16.2 Completion report — `docs/releases/<version>-report.md`

```markdown
# <VERSION> — <Milestone Name> Completion Report

- Status: In Progress | Complete | Blocked
- Completed: YYYY-MM-DD | Plan: <link> | Final commit: <hash>
- PR / merge: <URL + status | blocker>
- GitHub Release: <URL/status | not published + reason>
- Template flag / other channels: <status each | N/A + reason>

## 1. Delivered outcome (vs plan)
## 2. Acceptance and task audit
| ID | Expected | Outcome | Evidence IDs |
## 3. Research and ADR decisions (incl. rejected alternatives)
## 4. Evidence ledger (§16.3 entries) and exact commands
## 5. Matrix coverage actually exercised (method, cases run, gaps)
## 6. Performance and size (hardware labelled: real vs proxy)
## 7. Security, privacy, dependencies, licenses
## 8. Accessibility / localization / device evidence
## 9. Known issues, deferred work, owner actions
## 10. Git and channel evidence
| Channel | Required? | Artifact/version/hash | Verification | Remote status/URL | Blocker / owner action |
## 11. Reproduction and recovery instructions
```

### 16.3 Evidence entry

```text
[E-014] T07 | V1 | 2026-10-18T14:02Z | commit abc1234 | tree clean
cmd: flutter test test/unit/config
env: Windows 11, PowerShell 7, Flutter <pinned>, Dart <pinned>
result: exit 0 — 18 passed, 0 skipped
log: build/verify-logs/E-014.txt | CI: <run ID or n/a>
status: Verified
```

### 16.4 Deferred-backlog entry

```text
### <short title>
Problem: … | Evidence: … | Value: … | Likely milestone: … | Depends on: … | Risk: … | Found during: <version/task>
```

### 16.5 ADR outline

`ADR-NNN: Title` — Status (Proposed/Accepted/Superseded) · Context · Options considered · Decision · Evidence (URLs + dates, prototype results) · Trade-offs · Consequences · Revisit triggers.

---

## 17. Release gate checklist

Mark `N/A` only with a documented reason; `N/A` must not hide missing verification.

### Plan and scope
- [ ] Roadmap, previous report (or greenfield), and live release state confirmed; milestone correct.
- [ ] Plan existed, was `Ready`, and held concrete research before implementation.
- [ ] Every change maps to an in-scope task or documented prerequisite; out-of-scope discoveries deferred.

### Implementation
- [ ] Follows architecture, generator, and Android standards (§8); R3 work met its extra requirements.
- [ ] Tests accompany implementation; no test/lint/gate was weakened.
- [ ] Public contracts and dependencies changed deliberately and documented (§10, §15).
- [ ] Anti-patterns in roadmap §15 checked against the final diff.

### Verification
- [ ] V2 passed; V3 passed on the exact candidate commit from a clean checkout/CI.
- [ ] Required CI jobs observed completed and green with required cases executed (no unexpected skips; non-zero test counts).
- [ ] Gate self-test recorded where CI/verify changed.
- [ ] Static matrix and built matrix coverage recorded, with method and gaps; blank absence verified.
- [ ] Generation deterministic; dry-run matches output; invalid selections fail before writing.
- [ ] Merged release manifest and permissions reviewed; no undeclared permission.
- [ ] Security, secret, dependency, license checks recorded; no untriaged critical/high findings.
- [ ] Performance/size compared to baseline with labelled hardware; claims match evidence class.
- [ ] Accessibility/localization/reduced-motion checks relevant to the change recorded.
- [ ] Device/iOS/Play/provider claims limited to what was actually verified.

### Documentation and delivery
- [ ] README quickstart, changelog, testing guide, module docs, compatibility matrix, and upgrade notes are accurate and tested as written.
- [ ] Report complete with evidence IDs, limitations, and owner actions.
- [ ] Staged diff reviewed; no secrets, local paths, signing material, or build output.
- [ ] Commits meaningful; PR/merge respected policy and required checks.
- [ ] Tag/release created only after gates, at the verified commit; remote state verified; channels reported separately.
- [ ] If anything blocked delivery: status `Blocked`, no false release claim.

---

## 18. Standard final status message

End every run with a concise report:

1. **Version and scope** — target version; delivered; deliberately deferred.
2. **Plan/report** — repository paths.
3. **Verification** — key results with claim-vocabulary terms (§9.11); skipped/unavailable gates and why.
4. **Performance/size/accessibility** — measured results (real vs proxy) or what was not measured.
5. **Git** — branch, commit hashes, PR/merge status.
6. **Channels** — tag/URL, assets/checksums, GitHub Release status, template flag, other channels: published / N/A with reason / blocked or owner action.
7. **Blockers and owner actions** — only actionable items. Do not begin the next milestone in the same scope.

If a gate failed, say so directly, preserve the work, and give the recovery path.

---

## 19. Adoption and kickoff

1. Place this file at the repository root as `FLUTTER-AGENT-EXECUTION-PROTOCOL.md` and the roadmap beside it (§1.1).
2. Create or update `AGENTS.md` (preserving any existing unrelated instructions) with at least:

```markdown
# AGENTS.md
Before any work, read in order:
1. FLUTTER-AGENT-EXECUTION-PROTOCOL.md  (how to work)
2. Flutter-Android-App-Template-Roadmap-v0_1_0-to-v1_0_0.md  (what to build, in what order)
3. The current docs/releases/<version>-plan.md Resume block, relevant ADRs, manifests, and tests.
Rules in brief: one milestone at a time; plan before code; test with every change; no commit, tag, or
release until the applicable gates pass; never weaken a gate; report claims with evidence.
```

3. Inspect reality (P0). The first roadmap milestone is expected to start from a greenfield or near-empty repository, but verify.
4. Write the plan, pass the readiness checklist, then implement.
5. Preserve legitimate uncommitted user changes.

**Suggested kickoff prompt:**

> Read `AGENTS.md`, `FLUTTER-AGENT-EXECUTION-PROTOCOL.md`, and the roadmap. Run P0 to identify the next unfinished milestone and report it. Then research, write and ready the plan, implement in verified slices, run the gates, and deliver only if every applicable gate passes. Resume from the plan's Resume block if one exists.

**Operating principle:** Inspect reality; research only what changes a decision; plan the whole milestone before coding; implement in small verified slices; verify cheaply while iterating and strictly at release; prove that every generated project works and that unselected modules leave no trace; report each claim with the evidence behind it; and commit, merge, and publish only when the gates pass and the repository allows it.
