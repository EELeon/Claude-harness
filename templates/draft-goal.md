---
description: Convertir una descripción rough en un goal estructurado listo para /start
argument-hint: <descripción rough del trabajo, multilínea OK>
---

# /draft-goal

Descripción recibida:

**$ARGUMENTS**

Tu tarea: convertir esta descripción en un archivo markdown con un goal estructurado, listo para ser ejecutado luego por `/start <ruta>`. **NO ejecutar el goal todavía.** Solo escribir el archivo y reportar la ruta.

## Estructura obligatoria del archivo

```markdown
# <Título del sprint o ticket>

## Objetivo
<1-2 oraciones: qué se quiere lograr y por qué. Si la descripción menciona ADRs/docs base, listarlos con ruta.>

## Branch y modo
- Rama: <propuesta, ej. claude/sprint-z>
- Modo: <"Atómico" si es 1 ticket ≤3h, "Sprint largo" si son múltiples tickets/horas>
- Si Sprint largo: nota sobre `/loop` con auto-pacing.

## Criterios de aceptación
<Lista concreta: qué tests pasan, qué lints/builds limpian, qué archivos existen/no existen, qué validación visual aplica.>

## Scope fence
**TOCAR:** <directorios y archivos esperados>
**NO TOCAR sin confirmación:** <rutas protegidas detectadas en CLAUDE.md del repo target: baseline, single-writer, etc.>

## Riesgos — PARAR antes (OPCIONAL — incluir solo si el usuario lo pide explícitamente)
<Por defecto omitir esta sección. El sprint debe correr autónomo hasta el PR. Incluir solo si el usuario marcó pausas explícitas en su descripción rough (ej: "antes de borrar X confirmar conmigo"). Riesgos genéricos (UI, big-bang, schema) NO son pausas — se mitigan con tests/validaciones automáticas o se revisan al final en el PR.>

## Lista de tickets (orden + paralelización)
<Si Sprint largo: organizar en Phases A/B/C con sub-tickets numerados. Marcar cuáles tocan archivos distintos (paralelizables). NO marcar "PARAR" entre phases salvo que el usuario lo pidió explícitamente.>

## Notas
<Cosas excluidas, deadlines, dependencias, lo que sea relevante.>
```

## Tu proceso

1. **Auditoría profunda del repo antes de redactar** (en este orden, no saltes pasos):
   a. **`CLAUDE.md`** — lee la sección "Reglas de dominio" / BPs completa. Anota qué archivos requieren cambios *automáticos* cuando agregas un componente nuevo (capabilities en `config/*.yaml`, registries, `Procfile`, cron declarations, ADRs marcados como implementados).
   b. **AST / contract tests** (`tests/architecture/`, `tests/contract/`, `tests/integration/`) — lista los activos que pueden bloquear el merge si el sprint los viola sin saberlo (ej. `test_handler_db_read_boundary`, `test_autonomy_level_enforcement`, single-writer, capabilities-meta strict).
   c. **Scaffolds y trabajo preexistente** (`.ai/specs/active/`, `.ai/goals/`, ramas activas con `git branch`) — si existe trabajo previo del mismo sprint, referenciarlo como punto de partida explícito.
   d. **Lecciones recientes** (`.claude/lessons/`, `.ai/audit-post-sprint-*.md` últimos 3-5 sprints) — buscar patrones de fricción tipo "F-02a: cron declarado en Procfile o no corre en Railway". Convertir las aplicables al sprint actual en criterios de aceptación.
   e. **Estado puntual a respetar** — última migración numerada (para evitar colisiones), `docs/pendientes/` (decisiones diferidas que el sprint pueda absorber o explicitar como out-of-scope), aspiraciones excluidas explícitamente.
2. **Lee los ADRs/docs mencionados** en la descripción para dar contexto preciso. Si no existen, NO los inventes.
3. **Pregunta antes de escribir** si hay ambigüedad clave: modo de ejecución, riesgos no obvios, criterios de aceptación faltantes, decisiones pendientes sin resolver. NO inventes criterios silenciosamente.
4. **Propón nombre de archivo**: `.ai/goals/<sprint-id>.md` o `.ai/goals/<ticket-id>.md`. Crea el directorio `.ai/goals/` si no existe.
5. **Escribe el archivo** con la estructura de arriba.
6. **Commit automático** del goal: `git add <ruta> && git commit -m "docs(goal): draft <id>"`. Stagea solo el archivo del goal (no `-A`), para no arrastrar cambios no relacionados cuando se ejecuta en main. Si el commit falla (hook, working tree sucio en un path conflictivo), reportarlo en vez de forzar.
7. **Reporta** al usuario: ruta del archivo, hash del commit, y recordatorio de invocar `/start <ruta>` en sesión nueva (idealmente con `/clear`).

## Reglas
- NUNCA ejecutar el goal — solo escribir el archivo.
- NUNCA inventar pre-requisitos, criterios o riesgos que la descripción no implique.
- NUNCA agregar pausas humanas por defensa propia. El sprint corre autónomo hasta el PR. Solo incluir pausas si el usuario las pidió explícitamente en su descripción rough.
- Riesgos (big-bang, borrado, schema, UI): convertirlos en **criterios de aceptación verificables automáticamente** (tests, builds, validaciones), NO en pausas. La validación humana ocurre al revisar el PR final, no mid-sprint.
- Si la descripción es demasiado ambigua para producir un goal útil, decirlo y pedir aclaraciones antes de escribir.
