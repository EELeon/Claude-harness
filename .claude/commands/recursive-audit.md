# Recursive audit protocol

Execute the audit loop: audit → analyze → plan → spec → implement → repeat
until no gaps remain or stopping criteria are met.

## Prerequisites

- `.ai/meta.md` must exist and pass `/validate-meta`
- Repo must have CLAUDE.md and orchestrator infrastructure installed

## Context model

The loop uses 3 sequential subagents (not coexistent in memory).
Each reads from disk and writes to disk. Filesystem is the communication bus.

```
Subagent 1: AUDITOR (Explore) — heaviest (~60-100K tokens)
  Reads: meta.md + source code
  Writes: .ai/audit/iteration-N/raw-gaps.md

Subagent 2: ANALYST+PLANNER (Plan) — light (~35K tokens)
  Reads: raw-gaps.md + results.tsv + done-tasks.md
  Writes: .ai/audit/iteration-N/plan.md

Subagent 3: SPEC WRITER (General-purpose) — moderate (~40-70K tokens)
  Reads: plan.md + meta.md
  Writes: .ai/specs/active/ticket-N.md (one per gap)

After 3 subagents, ORCHESTRATOR EXISTING implements specs.
When implementation complete, loop returns to step 1 (auditor).
```

## Step 0 — Pre-validation

1. Verify `.ai/meta.md` exists. If not → FAIL: "Missing .ai/meta.md. Use code-orchestrator skill to define it or create manually following templates/meta-template.md."
2. Run `/validate-meta` logic. If FAIL → stop and report errors.
3. Read loop parameters from `.ai/meta.md` section `## Parámetros del loop recursivo`:
   - `max_iterations`
   - `coverage_threshold`
   - `diminishing_returns`
   - `priority_cutoff`
   - `audit_split`
4. Create audit folder: `mkdir -p .ai/audit`

## Step 1 — AUDITOR (Explore subagent)

Launch an **Explore** subagent (read-only) with this prompt:

> You are a completeness auditor. Your job is to compare the current code state
> against the project meta and find gaps.
>
> **Read these files:**
> 1. `.ai/meta.md` — the meta document with required capabilities
> 2. `CLAUDE.md` — project context
>
> **For each capability in the meta** (filter by priority_cutoff = [value]):
> 1. Read its verifiable criterion
> 2. Explore the code using Glob, Grep, and Read to determine if the capability is implemented
> 3. Classify each capability:
>
> | State | Criterion |
> |--------|----------|
> | **IMPLEMENTED** | Verifiable criterion is met — found concrete evidence in code |
> | **PARTIAL** | Implementation exists but doesn't fully meet criterion |
> | **ABSENT** | No implementation evidence found |
> | **NOT VERIFIABLE** | Criterion cannot be evaluated with read-only tools |
>
> **For cross-cutting restrictions:**
> Verify each restriction against existing code. Search for active violations.
>
> **Write result to** `.ai/audit/iteration-[N]/raw-gaps.md`

**If audit_split = "by_domain":** Launch 2 auditores in parallel.

## Step 2 — Evaluate stopping criteria

| Criterion | Condition | Result |
|----------|-----------|--------|
| No gaps | Gaps found = 0 | → **END ✓** — report total coverage |
| Max iterations | Current iteration ≥ max_iterations | → **END** — report remaining gaps |
| Coverage threshold | Coverage ≥ coverage_threshold% | → **END** — report minor remaining gaps |
| Diminishing returns | Gaps closed this iteration < diminishing_returns | → **END** — progress insufficient |

If no stopping criteria met → continue to step 3.

## Step 3 — ANALYST+PLANNER (Plan subagent)

Launch a **Plan** subagent to deduplicate, filter, prioritize, and group gaps.

## Step 4 — SPEC WRITER (General-purpose subagent)

Convert audit gaps into implementable specs in `.ai/specs/active/`.
Run preflight validation on generated specs. Fix any FAIL before finishing.

## Step 5 — IMPLEMENTATION (Existing orchestrator)

Execute standard orchestrator pipeline with generated specs.
**DO NOT create PR at end of this step.** Loop may have more iterations.

## Step 6 — Prepare next iteration

1. Archive audit artifacts to `.ai/audit/iteration-[N]/`
2. Move implemented specs to `.ai/specs/archive/audit-iteration-[N]/`
3. Preserve results, increment iteration, return to step 1

## Step 7 — Loop finalization

When stopping criterion met: generate final report in `.ai/audit/summary.md`,
archive everything, clean temporals, run `/learn`, create PR.

## Resuming after /clear

When running with existing `.ai/audit/iteration-*/`:
1. Find last completed iteration
2. Read its raw-gaps.md for current coverage
3. Continue from next iteration
4. Report: "Resuming recursive audit from iteration [N+1]"
