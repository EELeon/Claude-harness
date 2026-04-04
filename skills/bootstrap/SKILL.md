---
name: bootstrap
description: >
  Instalar el harness del orquestador en un repo nuevo. Usa este skill cuando el
  usuario diga: "instalar harness", "preparar este repo para Code", "bootstrap",
  "configurar repo para orquestador", o cualquier referencia a preparar un
  repositorio para uso con Claude Code y el orquestador.
---

# Bootstrap — Instalar harness en un repo

## Propósito

Auditar un repositorio y instalar la infraestructura necesaria para que
el orquestador pueda ejecutar sprints autónomos.

## Protocolo

Leer `${CLAUDE_PLUGIN_ROOT}/references/bootstrap.md` para el protocolo completo.

### Resumen

1. **Auditar el repo:**
   - Stack y herramientas (lenguaje, framework, package manager)
   - Comandos reales de test/lint/build
   - Estructura de carpetas relevante
   - Archivos sensibles que NUNCA deben tocarse
   - Reglas de dominio que deberían ir en CLAUDE.md

2. **Instalar scaffold:**
   - `.ai/` — estructura de carpetas (specs, runs, prompts, audit)
   - `.claude/commands/` — /learn, /next-ticket, /status, /preflight,
     /validate-meta, /recursive-audit
   - `.claude/settings.json` — hook PreToolUse guard destructivo
   - `CLAUDE.md` — personalizado para el repo (≤100 líneas)

3. **Personalizar** — NO copiar plantillas sin adaptar

4. **Reportar** — qué se instaló, qué se personalizó, qué quedó diferido

## Fuentes de personalización

| Archivo destino | Plantilla fuente |
|----------------|-----------------|
| `CLAUDE.md` | `${CLAUDE_PLUGIN_ROOT}/templates/claudemd-template.md` |
| `commands/learn.md` | `${CLAUDE_PLUGIN_ROOT}/commands/learn.md` |
| `commands/next-ticket.md` | `${CLAUDE_PLUGIN_ROOT}/commands/next-ticket.md` |
| `commands/status.md` | `${CLAUDE_PLUGIN_ROOT}/commands/status.md` |
| `commands/preflight.md` | `${CLAUDE_PLUGIN_ROOT}/commands/preflight.md` |
| `commands/validate-meta.md` | `${CLAUDE_PLUGIN_ROOT}/commands/validate-meta.md` |
| `commands/recursive-audit.md` | `${CLAUDE_PLUGIN_ROOT}/commands/recursive-audit.md` |
| `settings.json` | `${CLAUDE_PLUGIN_ROOT}/templates/stop-hook.md` sección "Hook 1" |
