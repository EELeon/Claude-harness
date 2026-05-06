# Claude harness — v5 (Opus 4.7)

Harness mínimo para ejecutar trabajo autónomo en Claude Code aprovechando lo que la plataforma ya hace nativo (TodoWrite, `Agent` + worktrees, `/loop`, git, auto-memory).

**Filosofía.** No hay specs rígidos, ni ledger, ni `.ai/`, ni skills custom. El harness son **3 plantillas** que se copian al repo donde vas a trabajar. La disciplina vive en CLAUDE.md (siempre cargado) y en un slash command `/start <goal>` que arranca runs.

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

## Cómo se usa después

En el repo target, dentro de Claude Code:

```
/start <descripción del goal>
```

El comando me obliga a producir un contrato (reformulación, criterios, scope fence, plan, modo de ejecución) antes de tocar código y a esperar tu confirmación. A partir de ahí ejecuto: secuencial si es one-shot, con worktrees si hay paralelismo, en `/loop` si requiere iteración hasta convergencia.

## Lo que cambió vs v4.7

- Borrado: 7 skills, 8 commands, `references/`, `.ai/`, plugin bundles, manifest de plugin.
- Reemplazado: specs autocontenidos por goal + criterios definidos en `/start`.
- Reemplazado: ledger `.ai/runs/results.tsv` por git log + auto-memory.
- Reemplazado: `/preflight`, `/validate-meta`, `/recursive-audit`, `/retrospective`, `/learn` por nada — la disciplina vive en CLAUDE.md y se autoaplica.
- Reemplazado: skill de `bootstrap` por estos 3 archivos copiables a mano.

Para 4.7 los specs rígidos eran fricción: el modelo descompone tareas mejor que un humano escribiendo specs. Lo único que sigue valiendo es **definir bien la meta + delimitar el blast radius + dejar que la plataforma haga lo demás**.
