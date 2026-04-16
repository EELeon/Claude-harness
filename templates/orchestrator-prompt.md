# Template para prompt orquestador

<!-- Rationale: references/design-rationale.md | Reglas estándar: references/reglas-orquestacion.md -->

```markdown
# [Nombre del batch]

## Setup inicial
1. Creá la rama: `git checkout -b [nombre-rama]`
2. Lee las reglas estándar en `${CLAUDE_PLUGIN_ROOT}/references/reglas-orquestacion.md`.
3. Lee los overrides de este sprint en `.ai/rules.md` (si existe).
4. Lee CLAUDE.md para contexto del proyecto.

## Contexto previo (si existe)
- `.ai/experience/` — insights de sprints anteriores
- `.ai/docs/project_notes/` — bugs conocidos, key facts
NO dejes que modifiquen los specs — los specs son la fuente de verdad.

## Tickets (en orden de ejecución)

| # | Ticket | Spec | Complejidad |
|---|--------|------|-------------|
| 1 | [prefix]-[seq] — [Título] | `.ai/specs/active/[prefix]-[seq]-[slug].md` | [Simple/Media/Alta] |

Para cada ticket:
1. Lanzá un **subagente general-purpose** con este prompt:
   > Lee e implementa el spec en `.ai/specs/active/[spec].md`. Leé CLAUDE.md para contexto. Seguí los pasos, corré tests, y hacé un commit atómico con el ticket en el mensaje. Lint con ruff si disponible. Devolvé Heat Shield: resumen (1-3 líneas), hash commit, tests, archivos tocados, tokens estimados, criterios (sí/no/parcial). NUNCA modifiques `.ai/`.
2. Aplicá verificación post-subagente (Reglas 2d → 2b → tests → 2c → 2e)
3. Registrá en `.ai/runs/results.tsv` (Regla 4)

Al terminar: seguir protocolo "Al terminar" de reglas-orquestacion.md.
```

---

## Archivo complementario: .ai/rules.md (SOLO OVERRIDES)

<!-- Este archivo es MÍNIMO. Las reglas estándar viven en el plugin.
     Solo incluir lo que es ESPECÍFICO de este sprint. -->

```markdown
# Overrides — [Nombre del batch]

Reglas estándar: `${CLAUDE_PLUGIN_ROOT}/references/reglas-orquestacion.md`
Este archivo solo contiene overrides para este sprint.

## Perfil de permiso
[conservative | standard | aggressive]

## Comando de tests del proyecto
```bash
[pytest / npm test / make test / etc.]
```

## Puntos de corte
- Después de ticket [N]: evaluar resultados. Si 2+ discards → PARAR.

## Overrides de reglas (solo si difieren del estándar)
[Ninguno | Regla N: override específico]
```
