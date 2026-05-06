# Claude harness — v5.2 (Opus 4.7)

Harness mínimo para ejecutar trabajo autónomo en Claude Code aprovechando lo que la plataforma ya hace nativo (TodoWrite, `Agent` + worktrees, `/loop`, git, auto-memory).

**Filosofía.** Dos slash commands. `/start <goal>` cubre toda la ejecución: ticket atómico (3h), sprint largo (días), retoma tras crash. `/draft-goal <descripción rough>` produce un goal estructurado en archivo .md a partir de una descripción suelta — útil para sprints grandes que se invocan después con `/start <ruta>`. Sin sintaxis estructurada, sin ledger. El estado vive en git (commits descriptivos en una rama del sprint) y en TodoWrite. La iteración prolongada usa `/loop` con auto-pacing.

## Qué hay aquí

```
templates/
├── CLAUDE.md       # Reglas de cómo trabajar (paralelizar, commitear, abortar)
├── start.md        # Slash command /start <goal | ruta>
├── draft-goal.md   # Slash command /draft-goal <rough> → archivo de goal
└── settings.json   # Permisos pre-aprobados (git rollback sin atorarse)
```

Eso es todo.

## Cómo aplicarlo a un repo

Pocos pasos manuales (es para uso personal en pocos repos — si fueran muchos, valdría un script):

1. **Copia `templates/CLAUDE.md` → `<repo>/CLAUDE.md`**
   - Si el repo ya tiene CLAUDE.md, mergea las reglas de "Cómo trabajar" en lugar de sobrescribir.
   - Rellena los `{{placeholders}}`: stack, comando de test, comando de lint, scope fence (rutas protegidas), convenciones del repo.

2. **Copia `templates/start.md` → `<repo>/.claude/commands/start.md`**
   - Sin cambios. Es genérico.
   - Crea el directorio `.claude/commands/` si no existe.

3. **Copia `templates/draft-goal.md` → `<repo>/.claude/commands/draft-goal.md`**
   - Sin cambios. Es genérico.

4. **Copia `templates/settings.json` → `<repo>/.claude/settings.json`**
   - Si ya existe, fusiona los permisos en `permissions.allow`.
   - Añade los comandos del stack del repo (ej: `Bash(npm test:*)`, `Bash(pytest:*)`, `Bash(cargo test:*)`).

## Cómo se usa

### Caso simple — ticket atómico

```
/start <goal>
```

Por ejemplo: `/start Agregar índice compuesto en money_entries (engagement_id, tipo_movimiento, fecha)`. Yo respondo con el contrato (criterios, scope, plan, modo), espero `ok`, ejecuto, abro PR, espero CI verde.

### Caso complejo — sprint largo desde descripción rough

Dos pasos en sesiones distintas:

**Sesión 1** (chat normal): pegas la descripción rough del sprint y la conviertes a goal estructurado:

```
/draft-goal <pegas tu descripción de sprint Z, rough, con scope general, ADRs base, etc.>
```

Yo leo CLAUDE.md del repo, leo los ADRs si existen, te pregunto lo ambiguo, escribo `.ai/goals/sprint-z.md` con criterios + scope fence + riesgos + lista de tickets enumerada + paralelización.

**Sesión 2** (idealmente con `/clear`):

```
/start .ai/goals/sprint-z.md
```

Yo leo el archivo, produzco el contrato basado en él, ejecuto: una rama, commits atómicos por subtarea, paralelización con worktrees donde aplique, paro en cada `PARAR antes` declarado en el goal, un solo PR al final.

**Tras crash o `/clear`:** vuelves a invocar `/start <mismo goal o ruta>`. Leo `git log` de la rama actual para detectar qué se completó y retomo desde la siguiente subtarea.

## Comandos complementarios (built-in de Claude Code, opcionales)

Estos NO son del harness, son built-in de Claude Code. Los invocas tú en momentos específicos para complementar a `/start`.

- **`/batch <descripción>`** — para cambios masivos repetitivos donde cada unidad debe ser su propio PR. Filosofía opuesta a `/start`: spawnea N agentes en worktrees aislados, cada uno hace su PR independiente. **N PRs en paralelo, no 1 PR final.** Usar para: refactor de N≥10 archivos independientes, migración de framework, actualización masiva de un patrón (ej. "actualizar todos los handlers a usar adapter v2").
- **`/schedule <descripción>`** — para tareas diferidas o recurrentes que sobreviven al cierre de sesión. Persiste en disco y ejecuta en background, a diferencia de `/loop` que solo corre con sesión abierta. Útil para: retomar parte diferida de un sprint cuando se cumple una pre-condición temporal (ej. "en 3 días verifica que el cron lleve verde y cierra Phase F"), runs nightly, etc.
- **`/loop`** — `/start` ya lo invoca internamente para sesiones >2h. Útil invocar explícitamente para monitoreo continuo (ej. `/loop 5m gh pr checks 1234`).
- **`/review <PR>`** o **`/ultrareview <PR>`** — auditoría profunda del PR antes de mergear. Invocar tras `gh pr create` del sprint, antes de aprobar el merge en GitHub.
- **`/rewind`** — retroceder a un commit anterior tras error o paso equivocado. Más limpio que `git reset --hard` cuando quieres preservar el historial conversacional.
- **`/compact`, `/context`, `/memory`** — manejo de contexto y memoria persistente. Built-in útil para sesiones muy largas; `/start` no requiere invocación manual de estos.

**Cuándo NO usar `/batch` para un sprint largo**: si tienes phases secuenciales con dependencias (Phase A → B → C/D → E → F → G), `/start` es la herramienta correcta. `/batch` rompe el modelo "1 PR final" generando N PRs sueltos. Usa `/batch` solo cuando los N cambios sean genuinamente independientes y cada PR atómico tenga sentido revisar por separado.

## Lo que cambió vs v4.7

- Borrado: 7 skills, 8 commands, `references/`, `.ai/`, plugin bundles, manifest de plugin, ledger TSV.
- Reemplazado: specs autocontenidos por goal + criterios definidos en `/start`.
- Reemplazado: ledger por git log + commits descriptivos.
- Reemplazado: `/preflight`, `/validate-meta`, `/recursive-audit`, `/retrospective`, `/learn`, `/sprint` (intentado en v5.1) por nada — un solo `/start` cubre todos los casos.
- Reemplazado: skill de `bootstrap` por estos 4 archivos copiables a mano.

Para 4.7 los specs rígidos y los comandos múltiples son fricción: el modelo descompone tareas mejor que un humano escribiendo specs, y el flujo de un sprint es lineal (planificar → ejecutar → PR → CI), no requiere comandos separados. Lo único que sigue valiendo es **definir bien la meta + delimitar el blast radius + dejar que la plataforma haga lo demás**.
