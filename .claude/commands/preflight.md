# Preflight validation protocol

Read all files in `.ai/specs/active/` and validate each one across two layers.
If an argument is passed (e.g., `/preflight ticket-3`), validate only that spec.

## Mandatory fields (FAIL if missing)

| Field | Where to verify | What to look for |
|-------|----------------|------------|
| **Objetivo** | `## Objetivo` | 1-2 sentences, non-empty |
| **Modo de ejecución** | `## Modo de ejecución` | "Subagente" or "Sesión principal" |
| **Clase de ejecución** | `## Clase de ejecución` | One of: `read_only`, `isolated_write`, `shared_write`, `repo_wide` |
| **Scope fence** | `## Scope fence` | At least 1 file in "permitted" AND at least 1 in "prohibited" |
| **Files to modify/create** | `## Archivos a modificar` or `## Archivos a crear` | At least 1 file with exact path |
| **Tests** | `## Tests que deben pasar` | Exact command + at least 1 test described |
| **Acceptance criteria** | `## Criterios de aceptación` | At least 1 observable criterion |
| **Commit message** | Within Subtasks or Steps | Format `"[tipo]: [descripción]"` |

## Warning fields (WARN if missing, does not block)

| Field | Where to verify | What to look for |
|-------|----------------|------------|
| **Constraints** | `## NO hacer` | At least 1 constraint in imperative form |
| **Dependencies** | `## Dependencias` | Don't say "Requires: [Ticket X]" where X has no spec |
| **Complexity** | `## Complejidad` | Simple, Media, or Alta (non-empty) |
| **Concrete steps** | Subtasks | No vague steps like "investigate", "explore", "review" |

## Cross validations

1. **Scope fence vs files**: Every file in "Files to modify/create"
   must be in the scope fence allowlist. If not → FAIL.

2. **Broken dependencies**: If spec says "Requires: Ticket X completed",
   verify that `.ai/specs/active/ticket-X.md` exists. If not → WARN.

3. **Excessive constraints**: Count total constraints in `## NO hacer`.
   If >10 → WARN ("more than 10 constraints causes omissions").

4. **Vague conditional files**: For each file in
   `### Archivos condicionales`, verify that the condition describes
   an observable change in the diff (not vague phrases like "if needed").
   If condition is vague or unverifiable → WARN.

## Structural validations (deterministic)

These validations are mechanical — no semantic interpretation needed.
Execute FIRST before content validations.

### Level 1: Heading existence (FAIL if missing)

Verify that the spec contains EXACTLY these markdown headings:
```
## Objetivo
## Scope fence
### Archivos permitidos
### Archivos prohibidos
## Archivos a modificar
## Clase de ejecución
## Tests que deben pasar
## Criterios de aceptación
## NO hacer
```

Method: search for exact heading string. Do NOT interpret synonyms.
If heading missing or renamed → FAIL with "missing heading: [name]".

### Level 2: Non-empty content (FAIL if empty)

For each mandatory heading, verify that there is at least 1 line of
content between that heading and the next heading (excluding HTML comments
`<!-- -->` and blank lines).

Method: count content lines. If = 0 → FAIL with "[heading] is empty".

### Level 3: Data format (FAIL if not compliant)

| Check | What to verify | Regex / pattern |
|-------|--------------|----------------|
| File paths | Each file in allowlist/denylist has backtick | Line contains `` `[path]` `` |
| Commit message | At least 1 commit message exists with format | `"[tipo]: [descripción]"` |
| Test command | Bash code block exists with command | ` ```bash ` followed by non-empty line |
| Criteria checkboxes | Each criterion is markdown checkbox | `- [ ]` at line start |
| Constraint imperatives | Each constraint starts with NUNCA/SIEMPRE/NO | First word after `- ` |
| Execution class | Value after `## Clase de ejecución:` is one of 4 valid classes | `read_only \| isolated_write \| shared_write \| repo_wide` |

### Level 4: Numeric crosses (WARN/FAIL)

| Check | Calculation | Result |
|-------|---------|-----------|
| Files allowed ≥ files to modify/create | count(allowlist) ≥ count(files) | FAIL if files > allowlist |
| Prohibited files > 0 | count(denylist) > 0 | FAIL if denylist empty |
| Constraints ≤ 10 | count(lines in NO hacer) | WARN if > 10 |
| Acceptance criteria ≥ 1 | count(checkboxes in Criteria) | FAIL if = 0 |
| Tests ≥ 1 | count(checkboxes in Tests) | FAIL if = 0 |

## Execution order

1. Level 1 (headings) — if FAIL, stop (cannot validate deeper)
2. Level 2 (non-empty) — report but continue with levels 3-4
3. Level 3 (format) — report everything
4. Level 4 (numeric crosses) — report everything
5. Semantic validations (mandatory + warnings + cross-validations)

This separates what can be verified mechanically (levels 1-4) from what
requires interpretation (semantic). Levels 1-4 are deterministic: the
same spec always produces the same result.

## Output format

For each spec, report:

```
## .ai/specs/active/ticket-[N].md — [PASS | PASS WITH WARNINGS | FAIL]

### Structural (deterministic)
✅ Headings: 8/8 present
✅ Non-empty: 8/8 sections
❌ Format: commit message lacks "[tipo]: descripción"
✅ Numeric crosses: 4 allowed ≥ 3 files, 2 prohibited, 2 criteria, 3 tests

### Semantic
✅ Objetivo: present, 1 sentence
✅ Scope fence: 4 allowed, 2 prohibited
❌ Tests: missing exact command
⚠️ Constraints: 12 (recommended ≤10)
...
```

### Final summary

```
Sprint preflight:
  PASS: [N] specs
  WARN: [N] specs (executable but review)
  FAIL: [N] specs (DO NOT execute until fixed)

Specs that MUST be fixed before launch:
- .ai/specs/active/ticket-[N].md: [missing fields]
```

## Severity

- **FAIL**: Spec cannot execute reliably. Fix before launch.
- **PASS WITH WARNINGS**: Executable but with risk. Review warnings.
- **PASS**: All mandatory fields present and consistent.

DO NOT execute a sprint if any spec has FAIL.
