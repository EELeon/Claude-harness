---
description: Arranca un run autónomo con goal + criterios de aceptación
argument-hint: <goal>
---

# /start

Goal recibido: **$ARGUMENTS**

Antes de tocar código, completa este contrato en tu respuesta inicial (no en archivos):

1. **Reformulación del goal** — una frase tuya, sin copiar la mía. Si la mía es ambigua, pide aclaración antes de seguir.
2. **Criterios de aceptación** — lista breve de "qué cuenta como hecho". Incluye: tests que deben pasar, lint/typecheck limpio, output verificable.
3. **Scope fence** — qué archivos/directorios vas a tocar y cuáles NO. Si crees que el goal te obliga a salir del scope, dilo aquí.
4. **Plan de descomposición** — TodoWrite con las subtareas. Marca cuáles son paralelizables (tocan archivos distintos) y cuáles secuenciales.
5. **Modo de ejecución** — uno de:
   - **One-shot**: cambio acotado, un solo turn.
   - **Iterativo**: requiere repetir hasta convergencia → vas a usar `/loop` con auto-pacing.
   - **Paralelo**: subtareas independientes → vas a lanzar `Agent` con `isolation: "worktree"` para cada una. Scheduling continuo: cuando un subagente termine, lanzar el siguiente sin esperar a que el resto del lote termine.

Después espera mi confirmación ("ok" / "go") antes de empezar a editar.

## Reglas operativas durante el run
- Commit atómico por subtarea (revertible con `git reset --hard HEAD~1`).
- Si un test falla 2 veces por la misma razón, parar y reportar — no acumular fixes.
- Si descubres que el scope era incorrecto, parar y reportar — no expandir silenciosamente.
- Al terminar: resumen en 2-3 líneas (qué cambió, qué validaste, qué quedó pendiente). Nada más.
