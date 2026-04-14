# Convención de naming para specs

## Formato

```
[sprint-prefix]-[seq]-[slug].md
```

Donde:
- **sprint-prefix**: Identificador corto del sprint, derivado del nombre de la rama.
  Ejemplos: `hardening`, `runtime-fixes`, `audit-close`, `contracts-v1`
- **seq**: Secuencia de 2 dígitos, en orden de ejecución. Empieza en 01.
- **slug**: Descripción corta en kebab-case (2-4 palabras). Describe QUÉ hace el ticket.

### Ejemplos

| Sprint | Rama | Spec |
|--------|------|------|
| Hardening P4 | `feat/hardening-p4` | `hardening-01-cherrypick-safe.md` |
| Runtime fixes | `feat/sprint-f-runtime` | `runtime-01-scheduler-drift.md` |
| Audit close | `sprint-1-audit-close` | `audit-01-enum-canon.md` |

### Reglas

1. El **sprint-prefix** se define UNA VEZ al crear el sprint y se usa para TODOS los specs del batch.
2. La **secuencia** refleja orden de ejecución, no prioridad.
3. El **slug** debe ser único dentro del sprint (no entre sprints).
4. El ID completo (prefix + seq) aparece en:
   - El nombre del archivo: `hardening-01-cherrypick-safe.md`
   - El header del spec: `# hardening-01 — Protocolo de cherry-pick seguro`
   - El commit message: `feat(hardening-01): protocolo de cherry-pick seguro`
   - El results.tsv: columna `ticket` = `hardening-01`
5. NUNCA reusar un ID dentro del mismo sprint.
6. Los specs archivados mantienen su nombre original (no renombrar al archivar).

### Migración de naming viejo

Los sprints P1-P3 usaron `ticket-N.md` con IDs `T-1` a `T-12`. Estos archivos
ya archivados conservan su nombre. El nuevo naming aplica desde P4 en adelante.

### En el orchestrator-prompt

La tabla de tickets usa el ID completo:

```
| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | hardening-01 — Cherry-pick seguro | `.ai/specs/active/hardening-01-cherrypick-safe.md` | Simple |
```

El prompt del subagente referencia el spec por ruta completa, no por ID.
