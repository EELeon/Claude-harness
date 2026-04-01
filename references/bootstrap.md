# Bootstrap de un repo nuevo

Cuando el usuario pide preparar un repo para usar con el orquestador
(ej: "instalar harness en este repo", "preparar este repo para Code"):

1. **Auditar el repo:**
   - Stack y herramientas (lenguaje, framework, package manager)
   - Comandos reales de test/lint/build
   - Estructura de carpetas relevante
   - Archivos sensibles que NUNCA deben tocarse
   - Reglas de dominio que deberían ir en CLAUDE.md

2. **Instalar scaffold persistente:**

```
repo-target/
├── .ai/
│   ├── standards/              # Crear vacío (el usuario lo llena con su harness de auditoría)
│   ├── specs/
│   │   ├── active/             # Crear vacío (se llena al preparar sprints)
│   │   └── archive/            # Crear vacío (se llena al finalizar sprints)
│   ├── runs/                   # Crear vacío (results.tsv se genera por sprint)
│   ├── prompts/                # Crear vacío (prompts archivados)
│   └── done-tasks.md           # NO crear aún — se crea con el primer /learn
├── .claude/
│   ├── commands/
│   │   ├── learn.md            # Adaptar: paths y comandos reales del repo
│   │   ├── next-ticket.md      # Adaptar: paths
│   │   ├── status.md           # Adaptar: paths
│   │   └── preflight.md        # Copiar IDÉNTICO del skill (lógica universal)
│   ├── agents/                 # NO instalar aún — esperar evidencia
│   └── settings.json           # Hook PreToolUse del skill (NO permissions.deny)
├── CLAUDE.md                   # Personalizado para este repo (≤100 líneas)
```

3. **Personalizar** — NO copiar plantillas sin adaptar:
   - `CLAUDE.md`:
     - **Si ya existe:** leerlo primero, preservar TODO el contenido existente,
       y solo agregar las secciones que faltan (comandos del orquestador,
       archivos sensibles si no están, convenciones si no están). Nunca borrar
       ni reemplazar reglas que el usuario ya definió.
     - **Si no existe:** generar desde `templates/claudemd-template.md`
       con reglas de dominio reales, comandos reales, convenciones reales.
   - `commands/learn.md`, `next-ticket.md`, `status.md`: adaptar paths y
     comandos reales del repo
   - `commands/preflight.md`: copiar IDÉNTICO del skill, sin simplificar
     ni recortar. Su lógica es universal y no depende del repo.
   - `settings.json`: DEBE usar formato de hooks `PreToolUse`, NO
     `permissions.allow/deny`. Leer `templates/stop-hook.md` sección
     "Hook 1" y copiar el JSON tal cual. Solo agregar patrones
     destructivos específicos del stack (ej: `DROP TABLE` para SQL).
     NUNCA bloquear `git reset --hard` — el orquestador lo usa para
     rollback controlado en Regla 2.

4. **Reportar al usuario:**
   - Qué se instaló y dónde
   - Qué se personalizó (decisiones tomadas)
   - Qué quedó diferido (agents, hooks opcionales, retrospective)

**Importante:** El scaffold (CLAUDE.md, commands, settings) vive en el repo
y se commitea. La estructura `.ai/` y los artefactos de sprint
(specs, results.tsv, rules.md) se generan bajo demanda cuando hay
tickets reales.

## Fuentes de personalización

Para generar cada archivo, leer las plantillas del skill:

| Archivo destino | Plantilla fuente |
|----------------|-----------------|
| `CLAUDE.md` | `templates/claudemd-template.md` |
| `commands/learn.md` | `commands/learn.md` |
| `commands/next-ticket.md` | `commands/next-ticket.md` |
| `commands/status.md` | `commands/status.md` |
| `commands/preflight.md` | `commands/preflight.md` |
| `settings.json` | `templates/stop-hook.md` sección "Hook 1" |
