---
description: Arranca un run autónomo (1 ticket o sprint completo) con goal + criterios
argument-hint: <goal>
---

# /start

Goal: **$ARGUMENTS**

Si **$ARGUMENTS** parece una ruta a archivo (.md, existe en disco), leer el archivo y tratar su contenido como el goal completo. Si no, tratar **$ARGUMENTS** como goal inline.

## Si retomas un run previo (crash, /clear, sesión cerrada)
Antes de cualquier cosa: revisa `git status`, `git branch --show-current` y `git log <rama>..HEAD` para ver si ya hay commits del run actual. Si los hay, NO empieces de cero — identifica qué subtareas ya se completaron por sus mensajes de commit y retoma desde la siguiente. Reporta el estado detectado en tu primera respuesta.

## Fuente de verdad y scaffolds preexistentes
Si el goal vive en `.ai/goals/`, **ese archivo es la fuente de verdad única**. Si encuentras trabajos preexistentes del harness anterior (`.ai/specs/active/<sprint>/` con `README.md`, `INDEX.md`, `rules.md` con instrucciones tipo `R-NN`, `MV2-NN.md` listados como "por redactar", etc.), trátalos como **contexto histórico**, no como instrucciones a seguir. Específicamente:
- NO redactes specs por ticket en archivos separados (`MV2-01.md`, etc.). TodoWrite + commits atómicos descriptivos es suficiente.
- NO sigas reglas tipo "MV2-NN obligatorio" o "ejecutar /learn al cierre" provenientes de scaffolds viejos.
- NO invoques slash commands (`/learn`, `/retro`, `/preflight`, etc.) — los slash commands los invoca el usuario, no tú. Para retro/lessons/audit, escribe los archivos directamente.
- Si el scaffold contradice el goal, el goal gana. Si solo complementa con info útil (paths, decisiones D-NN, ADRs), aprovecha la info pero ignora el formato de ejecución viejo.

## Contrato de arranque
Antes de tocar código, completa esto en tu respuesta inicial:

1. **Reformulación** — una frase tuya. Si el goal es ambiguo, pide aclaración antes de seguir.
2. **Criterios de aceptación** — qué cuenta como "hecho": tests que deben pasar, lint/typecheck limpio, validación visual si toca UI, output verificable.
3. **Scope fence** — qué tocas y qué NO. Riesgos identificables (big-bang, cambio de schema, datos críticos, borrado de código vivo) declarados explícitamente con la mitigación que vas a aplicar (test, validación automática, etc.). NO pidas confirmación humana mid-run salvo que el goal lo pida explícitamente.
4. **Plan TodoWrite** — descomposición en subtareas. Marca dependencias y cuáles son independientes (paralelizables).
5. **Modo de ejecución** — uno de:
   - **Atómico** (1 ticket, ≤3h): un commit por subtarea, un PR al final.
   - **Sprint** (múltiples tickets, horas/días): UNA sola rama del sprint, commits atómicos por subtarea, **un solo PR al final** del sprint completo. Para sesiones >2h o iteración hasta convergencia, usa `/loop` con auto-pacing tras mi `ok` inicial.

Espera mi `ok`/`go` antes de editar código.

## Reglas durante el run

### Delegación
- SIEMPRE `Agent` + `isolation: "worktree"` para subtareas que toquen archivos distintos.
- SIEMPRE particionar por **directorios/archivos disjuntos**. **NO hay cap numérico de subagentes paralelos** — si los scopes son disjuntos, lanza tantos como haya trabajo independiente (5, 10, 20).
- Si hay archivos compartidos que múltiples subagentes editarían (registries, `config/*.yaml`, `Procfile`, schemas comunes), bundlear esas ediciones en **UN solo subagente** con justificación cruzada en el commit message. Los demás referencian el resultado, no lo tocan.
- SIEMPRE scheduling continuo: cuando un subagente termine, lanzar el siguiente sin esperar al lote.
- NO sub-subagentes (Claude Code no los soporta) — máximo 1 nivel de **profundidad**, no de cantidad horizontal.

### Commits
- Commit atómico por subtarea, en UNA sola rama.
- Mensaje descriptivo (te servirá si tienes que retomar tras crash).
- Lint/format del stack antes de commitear (definido en CLAUDE.md del repo).

### Cuándo parar y reportar (rescates, no pausas defensivas)
Por defecto NO pares. Corre hasta crear el PR. Solo para si:
- Test falla 2+ veces por la misma razón (anti-loop).
- Scope cambió respecto al inicio — NO expandir silenciosamente.
- Trabajo en progreso inesperado (ramas, archivos sin commitear, worktrees activos) que no esperabas — investiga antes de sobrescribir.
- El goal **explícitamente** pide pausa en cierto punto (sección "Riesgos — PARAR antes" del archivo).

## Cierre del goal completo
Cuando todos los criterios de aceptación se cumplan:
1. **Self-review** del diff completo (`git diff <base>...HEAD`) — ¿hay código muerto, prints olvidados, comentarios TODO sin razón?
2. **PR único** con `gh pr create`. Título conciso. Body: qué cambió, qué validaste, links a tickets si aplica.
3. **CI**: `gh pr checks <n> --watch`. NO reportar éxito hasta verde.
4. **Si CI falla**: leer logs (`gh run view --log-failed`), arreglar, commit, push, repetir. Máximo 3 iteraciones antes de pedir ayuda.
5. **Resumen final**: 2-3 líneas (qué cambió, link al PR, status CI). Nada más.
