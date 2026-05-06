# Claude harness — instrucciones de mantenimiento

> Este CLAUDE.md aplica cuando trabajas EN ESTE REPO (mantenimiento del harness). NO es la plantilla que se copia a repos target — esa vive en `templates/CLAUDE.md`.

## Qué es esto
Cuatro plantillas que se copian a mano a los pocos repos donde Edwin trabaja con Claude Code:
- `templates/CLAUDE.md` — reglas de cómo trabajar (siempre cargado en repo target).
- `templates/start.md` — slash command `/start <goal | ruta>`. Cubre tickets atómicos Y sprints largos.
- `templates/draft-goal.md` — slash command `/draft-goal <rough>`. Convierte descripción suelta en archivo de goal estructurado.
- `templates/settings.json` — permisos pre-aprobados (git rollback sin atorarse).

No hay skills, commands extra, ni manifest de plugin. Es un repo de plantillas.

## Filosofía v5.2
Dos comandos. `/start` ejecuta. `/draft-goal` produce archivos de goal estructurado para sprints grandes que se invocan después con `/start <ruta>`. Sin sintaxis estructurada (`[gate]`, `[parallel]`), sin archivos de estado custom. Estado vive en git (commits descriptivos en una rama del sprint) y en TodoWrite. Iteración prolongada usa `/loop` con auto-pacing (skill de plataforma).

## Reglas de mantenimiento
- SIEMPRE escribir en español (plantillas, README, comments).
- SIEMPRE forma imperativa en reglas: "SIEMPRE X" / "NUNCA X".
- NUNCA añadir una quinta plantilla sin justificación fuerte. Cada archivo nuevo es fricción al instalar en un repo.
- NUNCA reintroducir specs rígidos por ticket (archivos separados), ledger en disco, comandos de orquestación (`/sprint`, `/preflight`, `/learn`), ni skills custom. Si una pieza nueva parece necesaria, primero pregúntate si la plataforma ya la cubre (TodoWrite, `Agent` + worktree, `/loop`, git, auto-memory).
- NUNCA dejar las plantillas largas. `templates/CLAUDE.md` < 50 líneas, `templates/start.md` < 60, `templates/draft-goal.md` < 60.
- Cambiar una plantilla NO actualiza los repos donde ya se copió — el usuario debe re-aplicar manualmente. Decir esto explícitamente cuando se proponga un cambio sustantivo.

## NO hacer
- NUNCA recrear `.ai/`, `skills/`, `commands/`, `references/`, ni `.claude-plugin/` aquí. Si vuelven a aparecer es señal de que el rewrite está degradándose.
- NUNCA bundles `.plugin` (zips). El repo es markdown + JSON.
- NUNCA convertir esto en plugin de Claude Code de nuevo a menos que Edwin pida explícitamente "redistribuirlo".

## Estructura esperada
```
templates/
├── CLAUDE.md
├── start.md
├── draft-goal.md
└── settings.json
README.md
CLAUDE.md   (este archivo)
```

Si ves más, sospecha. Si ves menos, falta algo.
