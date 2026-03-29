# Template para EXECUTION_PLAN.md

<!-- Este archivo se genera junto con los specs y se commitea al repo -->

# Plan de Ejecución — [Nombre del batch]

Generado: [fecha]
Total tickets: [N]
Sprints: [N]

## Orden de ejecución

| # | Ticket | Título | Sprint | Complejidad | Modo | Subtareas | Estado |
|---|--------|--------|--------|-------------|------|-----------|--------|
| 1 | T-[N]  | [título] | A | [S/M/A] | Subagente | [N] | ⬜ |
| 2 | T-[N]  | [título] | A | [S/M/A] | Subagente | [N] | ⬜ |
| 3 | T-[N]  | [título] | B | Alta | Sesión principal | [N] | ⬜ |

<!--
Estados: ⬜ pendiente | 🔄 en progreso | ✅ completado | ❌ bloqueado

Modo de ejecución:
  Subagente (default): corre dentro del mega-prompt como subagente.
  Sesión principal: corre fuera del mega-prompt, directamente en el
    contexto principal de Claude Code. Usar SOLO cuando el ticket
    es de complejidad Alta + tiene 4 subtareas de 5+ archivos cada una.
    Estos tickets necesitan lanzar sus propios subagentes internos,
    lo cual no es posible si ya corren como subagente.
-->

## Sprints

### Sprint A — [Nombre temático]
- **Rama:** `sprint-a-[nombre]`
- **Tickets:** T-[N], T-[N], T-[N]
- **Dependencias internas:** T-[X] antes de T-[Y]
- **Tickets fuera del mega-prompt:** [ninguno | T-[N] (razón)]

### Sprint B — [Nombre temático]
- **Rama:** `sprint-b-[nombre]`
- **Tickets:** T-[N], T-[N]
- **Dependencias:** Requiere Sprint A mergeado
- **Tickets fuera del mega-prompt:** [ninguno | T-[N] (razón)]

<!-- Repetir por sprint -->

---

## Mega-prompts por sprint

### Mega-prompt Sprint A

<!-- Copiar y pegar este bloque completo en Claude Code -->

```
[AQUÍ VA EL MEGA-PROMPT GENERADO POR EL SKILL]
[Seguir el template en templates/orchestrator-prompt.md]
[Incluye todos los tickets del sprint que corren como subagente]
```

### Mega-prompt Sprint B

```
[MEGA-PROMPT DEL SPRINT B]
```

<!-- Repetir por sprint -->

---

## Instrucciones de ejecución

```bash
# Sprint A
git checkout -b sprint-a-[nombre]
claude

# Dentro de Claude Code:
#   1. Pegar el mega-prompt del Sprint A (arriba)
#   2. Esperar ejecución autónoma
#   3. Si hay tickets fuera del mega-prompt:
#      > "Lee specs/ticket-[N].md e impleméntalo. Usa subagents."
#      > /learn ticket-[N] [título]
#   4. Revisar resumen final

gh pr create --title "Sprint A: [nombre]"

# Sprint B (después de mergear Sprint A)
git checkout main && git pull
git checkout -b sprint-b-[nombre]
claude
# Pegar mega-prompt Sprint B...
```

## Fallback: ejecución manual (si el mega-prompt falla)

Si la ejecución autónoma falla a mitad del sprint:
1. Revisar qué tickets ya se completaron: `/status`
2. Para el ticket que falló: `/next-ticket` (ejecuta el siguiente pendiente)
3. Después de corregir: `/learn ticket-[N] [título]`
4. `/clear` y continuar con `/next-ticket`

---

## Infraestructura instalada

### Agentes custom

| Agente | Archivo | Dominio |
|--------|---------|---------|
| [nombre] | `.claude/agents/[nombre].md` | [dominio] |

### Comandos

| Comando | Archivo | Propósito |
|---------|---------|-----------|
| `/learn` | `.claude/commands/learn.md` | Captura lecciones post-ticket |
| `/next-ticket` | `.claude/commands/next-ticket.md` | Inicia siguiente ticket |
| `/status` | `.claude/commands/status.md` | Muestra progreso del sprint |
| `/retrospective` | `.claude/commands/retrospective.md` | Análisis retroactivo de sesiones (instalar post Sprint 1) |

### Hook Stop

- **Archivo:** `.claude/settings.json`
- **Tipo:** Anti-racionalización
- **Acción:** Bloquea respuestas que declaren victoria prematura

### Tracking de resultados (dos archivos)

**`results.tsv`** — Escrito por el orquestador. Tracking estructurado
para retomar sprints después de `/clear` y para análisis automatizado.
```
ticket	commit	tests	status	description
T-1	a1b2c3d	passed	keep	block por nivel con tabla y capa DXF
T-5	c3d4e5f	failed	discard	capas eléctricas — tests fallaron
T-5	d4e5f6g	passed	keep	capas eléctricas — fix aplicado
```

**`done-tasks.md`** — Escrito por `/learn`. Lecciones narrativas
para humanos y para que `/retrospective` analice.
```
## [fecha] — Ticket [N]: [título]
- Subtareas completadas: [lista]
- Tests: [pasaron/fallaron]
- Lecciones: [resumen de 1 línea]
- Reglas nuevas en CLAUDE.md: [N agregadas, N modificadas, N eliminadas]
```

Ambos archivos se commitean al repo.
