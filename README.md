# Claude harness — v5.2 (Opus 4.7)

Harness mínimo para ejecutar trabajo autónomo en Claude Code aprovechando lo que la plataforma ya hace nativo (TodoWrite, `Agent` + worktrees, `/loop`, git, auto-memory).

**Filosofía.** Un solo slash command (`/start <goal>`) cubre todo: ticket atómico (3h), sprint largo (días), retoma tras crash. Sin comandos extras, sin sintaxis estructurada, sin ledger. El estado vive en git (commits descriptivos en una rama del sprint) y en TodoWrite. La iteración prolongada usa `/loop` con auto-pacing.

## Qué hay aquí

```
templates/
├── CLAUDE.md       # Reglas de cómo trabajar (paralelizar, commitear, abortar)
├── start.md        # Slash command /start <goal>
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

3. **Copia `templates/settings.json` → `<repo>/.claude/settings.json`**
   - Si ya existe, fusiona los permisos en `permissions.allow`.
   - Añade los comandos del stack del repo (ej: `Bash(npm test:*)`, `Bash(pytest:*)`, `Bash(cargo test:*)`).

## Cómo se usa

En el repo target, dentro de Claude Code:

```
/start <goal>
```

El goal puede ser un ticket pequeño ("agregar índice X a tabla Y") o un sprint completo enumerado ("Sprint Z — Mando v2: 1) reescribir handler apertura..., 2) construir wizard UI..., 3) ..., 30) borrar skills viejos. Pausa para mi confirmación antes de los pasos de borrado big-bang"). El contrato fuerza descomposición + scope fence + criterios + modo, y luego ejecuto.

**Sprint largo:** un sola rama, commits atómicos por subtarea, **un PR al final** del sprint completo (no PR por ticket interno). Para >2h de ejecución continua, uso `/loop` con auto-pacing.

**Tras crash o `/clear`:** vuelves a invocar `/start` con el mismo goal; leo `git log` de la rama actual para detectar qué se completó y retomo desde la siguiente subtarea.

## Lo que cambió vs v4.7

- Borrado: 7 skills, 8 commands, `references/`, `.ai/`, plugin bundles, manifest de plugin, ledger TSV.
- Reemplazado: specs autocontenidos por goal + criterios definidos en `/start`.
- Reemplazado: ledger por git log + commits descriptivos.
- Reemplazado: `/preflight`, `/validate-meta`, `/recursive-audit`, `/retrospective`, `/learn`, `/sprint` (intentado en v5.1) por nada — un solo `/start` cubre todos los casos.
- Reemplazado: skill de `bootstrap` por estos 3 archivos copiables a mano.

Para 4.7 los specs rígidos y los comandos múltiples son fricción: el modelo descompone tareas mejor que un humano escribiendo specs, y el flujo de un sprint es lineal (planificar → ejecutar → PR → CI), no requiere comandos separados. Lo único que sigue valiendo es **definir bien la meta + delimitar el blast radius + dejar que la plataforma haga lo demás**.
