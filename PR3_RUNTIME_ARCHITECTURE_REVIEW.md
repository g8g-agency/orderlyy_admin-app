# PR #3 Runtime Architecture Governance Review

## Scope
Review target: **PR #3 — Updated Phase 2 and Phase 3**

Focus areas:
- repositories
- DTO parsing
- normalized runtime state
- polling systems
- availability overlay integration
- customer runtime architecture
- provider/store systems
- snapshot integration
- runtime merge logic

This review is strictly runtime architecture governance (not UI/styling).

---

## Verdict
**Request Changes (blocking)** — architecture direction is strong, but there are runtime-governance gaps that can break deterministic behavior, branch safety, and future realtime compatibility.

---

## 1) Repository Abstraction
**Status: Partial Pass**

### What is good
- Networking is isolated in repository implementations (for menu runtime).
- DTO parsing is handled in data layer and mapped to domain models.
- UI screens consume providers/state instead of calling HTTP clients directly.

### Blocking issues
- **Repository contract fragmentation:** multiple orders repository/provider stacks exist in parallel, creating divergent runtime contracts and higher drift risk.
- **Unsafe branch fallback:** branch defaults to `'mock_branch'` in runtime provider paths when session context is absent, which can cause cache/polling cross-contamination.

---

## 2) DTO Separation
**Status: Partial Fail**

### What is good
- DTO classes are separated from domain entities for menu snapshot pipeline.
- Repositories return typed domain models (`MenuSnapshot`) rather than raw response objects.

### Issues
- **Dynamic payload in domain:** `MenuSnapshot.metadata` is `Map<String, dynamic>`, which weakens strict domain typing.
- **DTO usage in presentation runtime paths:** checkout flow still depends on DTO-layer order objects in state assembly, reducing domain/runtime boundary clarity.

---

## Deterministic Runtime / Distributed Safety Findings

### Critical
1. **Snapshot migration instability**
   - Migration enforces strict version equality while snapshot version can be absent/optional.
   - Can trigger repeated cache invalidation loops and unstable hydration behavior.

2. **Non-deterministic identity generation**
   - Session/order-item/draft identifiers rely on `DateTime.now()`-based generation in critical flow paths.
   - This is unsafe for idempotent retries and reconciliation under distributed/offline sync conditions.

3. **Branch-safe behavior not guaranteed**
   - Runtime defaults (`mock_branch`) and fallback deserialization values can route different sessions into shared cache identity.

### Major
4. **Overlay merge stale-key risk**
   - Availability overlay is merged incrementally and can retain stale entries for removed/changed items.

5. **Polling scalability risk**
   - Fixed-interval timers without jitter/backoff coordination can produce synchronized polling bursts at scale.

6. **OCC merge scope is narrow**
   - OCC resolution is item-field centric and does not fully govern categories/modifier-groups/tax/meta evolution for future realtime patching.

---

## Governance Objective Scorecard

- **Stable runtime contracts:** ❌
- **Normalized frontend architecture:** ⚠️
- **Deterministic overlay behavior:** ⚠️
- **Future realtime compatibility:** ⚠️
- **Branch-safe runtime behavior:** ❌

---

## Merge Recommendation
**Do not merge as-is.**

Require a hardening pass for:
1. branch-scoped runtime identity (no silent mock fallback),
2. deterministic/idempotent ID strategy in checkout/draft pipeline,
3. migration logic compatible with optional snapshot versioning,
4. single canonical repository/provider contract per bounded context,
5. authoritative overlay reconciliation semantics,
6. scalability-safe polling policy and broader OCC governance coverage.
