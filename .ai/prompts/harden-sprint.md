# Sprint: Endurecimiento del Harness

## Setup inicial
1. Creá la rama: `git checkout -b harden-sprint`
2. Lee las reglas de orquestación en `.ai/rules.md` y seguílas estrictamente.
3. Lee el perfil de permiso en `.ai/plan.md`. Usá `standard` como default.

## Consulta de experiencia previa
Antes de ejecutar el primer ticket, leé los archivos en `.ai/experience/` (si existen).
Buscá insights cuyo **Perfil** coincida con los tickets de este sprint.
Si encontrás insights relevantes, tenelos en cuenta al verificar resultados de subagentes.
NO dejes que la experience library modifique los specs — los specs son la fuente de verdad.

## Consulta de project notes
Si existe `.ai/docs/project_notes/`, leé `bugs.md` y `key_facts.md` para contexto del proyecto.

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | harden-01 — Contrato parseable YAML | `.ai/specs/active/harden-01-contrato-parseable.md` | Simple |
| 2 | harden-02 — Gate de descomposición | `.ai/specs/active/harden-02-decomposition-gate.md` | Simple |
| 3 | harden-03 — Política de iteración | `.ai/specs/active/harden-03-politica-iteracion.md` | Simple |
| 4 | harden-04 — Preflight determinístico | `.ai/specs/active/harden-04-preflight-duro.md` | Media |
| 5 | harden-05 — Verificadores de cierre | `.ai/specs/active/harden-05-verificadores-cierre.md` | Simple |
| 6 | harden-06 — Memoria de failure modes | `.ai/specs/active/harden-06-memoria-failure-modes.md` | Simple |

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/[spec].md`. Leé CLAUDE.md para contexto del proyecto. Seguí los pasos del spec, verificá con los comandos de validación indicados, y hacé un commit atómico con el número de ticket en el mensaje. Devolvé: resumen (1-3 líneas), hash del commit, estado de validación (passed/failed), lista de archivos tocados, y para cada criterio de aceptación del spec indicá si se cumplió (sí/no/parcial). NUNCA modifiques archivos en el directorio .ai/ (results.tsv, plan.md, rules.md, etc.) — estos son propiedad exclusiva del orquestador.
2. Después del subagente, aplicá Reglas 2 + 2b + 2c (scope → validación → completitud)
3. Registrá el resultado en `.ai/runs/results.tsv` (Regla 4)

Al terminar todos los tickets:
1. Ejecutá `/learn harden-sprint completo`
2. Creá el PR: `gh pr create --title "Endurecimiento del harness: contratos, preflight, cierre y memoria" --body "$(cat .ai/runs/results.tsv)"`
