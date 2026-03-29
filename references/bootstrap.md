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
├── .claude/
│   ├── commands/
│   │   ├── learn.md            # Adaptar: paths y comandos reales del repo
│   │   ├── next-ticket.md      # Adaptar: paths
│   │   ├── status.md           # Adaptar: paths
│   │   └── preflight.md        # Copiar tal cual (lógica universal)
│   ├── agents/                 # NO instalar aún — esperar evidencia
│   └── settings.json           # Guard destructivo activado
├── CLAUDE.md                   # Personalizado para este repo (≤100 líneas)
```

3. **Personalizar** — NO copiar plantillas sin adaptar:
   - `CLAUDE.md`: reglas de dominio reales, comandos reales, convenciones reales
   - `commands/*.md`: paths y comandos que existen en este repo
   - `settings.json`: guard destructivo con los destructive patterns del stack

4. **Reportar al usuario:**
   - Qué se instaló y dónde
   - Qué se personalizó (decisiones tomadas)
   - Qué quedó diferido (agents, hooks opcionales, retrospective)

**Importante:** El scaffold (CLAUDE.md, commands, settings) vive en el repo
y se commitea. Los artefactos de sprint (specs, results.tsv, etc.) se generan
bajo demanda cuando hay tickets reales.

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
