# Meta validation protocol

Read `.ai/meta.md` (or the provided path) and validate across two layers:
structural first, semantic second.

## Layer 1 — Structural (deterministic)

Execute these mechanical validations FIRST. If they fail, report but
continue with the rest to provide complete feedback.

### Level 1: Mandatory headings (FAIL if missing)

Verify that meta contains EXACTLY these headings:
```
## Visión
## Dominios
## Capacidades
## Restricciones transversales
## Parámetros del loop recursivo
```

Method: search for exact heading string. Do NOT interpret synonyms.
If missing or renamed → FAIL: "missing heading: [name]".

### Level 2: Non-empty content (FAIL if empty)

For each mandatory heading, verify at least 1 line of content
(excluding HTML comments and blank lines).

### Level 3: Capability format (FAIL if not compliant)

| Check | What to verify | Criterion |
|-------|--------------|----------|
| Unique IDs | Each capability has ID with format `[A-Z]+-[0-9]+` | No duplicate IDs |
| Verifiable criterion | Each capability row has non-empty "Criterio verificable" column | No empty cells |
| Valid priority | Each row has Alta, Media, or Baja | No out-of-enum values |
| Declared domain | Each ID prefix (DOM1, AUTH, etc.) appears in Dominios section | No orphan prefixes |

### Level 4: Loop parameters (FAIL if not compliant)

| Check | Criterion |
|-------|----------|
| max_iterations | Integer > 0 and ≤ 10 |
| coverage_threshold | Integer between 50 and 100 (is a %) |
| diminishing_returns | Integer ≥ 1 |
| priority_cutoff | Alta, Media, or Baja |
| audit_split | "single" or "by_domain" |

## Layer 2 — Semantic (requires interpretation)

These validations require judgment. Report as WARN, not FAIL.

### Level 5: Verifiable criterion quality (WARN)

For each capability, evaluate if the criterion is really verifiable
by an Explore agent (read-only, no runtime state):

| Criterion type | Verifiable? | Example |
|-----------------|-------------|---------|
| File/function existence | ✅ Yes | "File src/auth/login.ts exists" |
| Command output | ✅ Yes | "npm test passes" |
| Code pattern | ✅ Yes | "POST /auth/login endpoint exists in router" |
| Runtime behavior | ⚠️ Partial | "Returns 200" — needs running server |
| Subjective quality | ❌ No | "Is fast", "good UX" |
| No measurable threshold | ❌ No | "Handles many users" |

If criterion not verifiable → WARN with suggestion for reformulation.

### Level 6: Granularity consistency (WARN)

Evaluate if capabilities are at the same abstraction level:
- If very granular mixed with very abstract → WARN
- Example of inconsistency: "AUTH-01: User can register" (high level)
  with "AUTH-02: Email field has /^[a-z].../ regex validation" (very low)

### Level 7: Domain coverage (WARN)

For each domain declared in `## Dominios`:
- Has at least 1 capability defined? If not → WARN "domain without capabilities"
- Any obvious gaps? (e.g., AUTH has login but not logout) → WARN with suggestion

### Level 8: Cross-cutting restrictions (WARN)

- Does each restriction have a concrete verification method? If not → WARN
- Do restrictions contradict any capabilities? If yes → WARN

## Output format

```
## .ai/meta.md — [PASS | PASS WITH WARNINGS | FAIL]

### Structural (deterministic)
✅ Headings: 5/5 present
✅ Non-empty: 5/5 sections
✅ IDs: 15 capabilities, 0 duplicates, 0 orphan prefixes
❌ Parameters: max_iterations missing

### Semantic
✅ Verifiable criteria: 14/15 verifiable
⚠️ AUTH-05: criterion "system is secure" not observable → suggest: "npm audit returns 0 critical vulnerabilities"
⚠️ Granularity: AUTH-02 significantly more granular than AUTH-01
✅ Coverage: all domains have capabilities
✅ Restrictions: 3/3 with verification method

### Summary
  Capabilities: 15 (12 Alta, 2 Media, 1 Baja)
  Domains: 3
  Restrictions: 3
  Verifiable criteria: 14/15 (93%)
  Status: PASS WITH WARNINGS — 2 semantic warnings
```

## Severity

- **FAIL** → Meta cannot be used for audit. Fix before `/recursive-audit`.
- **PASS WITH WARNINGS** → Usable but risk of audit gaps. Review warnings.
- **PASS** → Ready for `/recursive-audit`.
