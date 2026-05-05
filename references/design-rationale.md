# Design Rationale — Orchestrator Prompt

Archivo de referencia para diseñadores del sistema. NO se lee en runtime.

## Modelo de ejecución
Una sola rama, un solo PR, todos los tickets en secuencia.
Los puntos de corte son pausas de contexto, NO fronteras de git.
Cada ticket termina con un commit atómico revertible individualmente.

## Principio de diseño
El prompt del orquestador debe mantenerse en ~2-3K tokens.
- Las reglas viven en `.ai/rules.md` (archivo separado)
- Los specs están en `.ai/specs/active/` (lazy loading por subagente)
- El prompt solo contiene: instrucción de leer reglas + lista de tickets

## Ventajas vs prompt monolítico
- Cabe en zona de fidelidad total (0-5K tokens)
- Sobrevive /compact sin paraphrase loss
- Specs se cargan frescos en contexto de cada subagente
- Agregar tickets no infla el prompt
- Reglas actualizables sin regenerar prompt

## Estrategia de contexto (3 capas)
1. SUBAGENTES: contexto fresco por ticket. Reporte lean para resultados.
2. ESTADO EN DISCO: .ai/runs/results.tsv persiste entre auto-compact y /clear.
3. CHECKPOINT DINÁMICO: Evaluar degradación post-ticket (re-lecturas, pérdida
   de track). Solo pedir /clear si hay evidencia de degradación.

## Limitaciones
- Claude Code NO puede ejecutar /clear programáticamente
- Los subagentes no pueden crear sub-subagentes (constraint de plataforma)
- Auto-compact maneja la mayoría de casos; el orquestador NUNCA pide /compact manualmente
- Máximo 5 subagentes concurrentes por codebase

## Estimación de contexto por ticket

| Complejidad | Contexto subagente | Contexto orquestador |
|-------------|-------------------|---------------------|
| Simple | ~20k tokens | ~2k tokens |
| Media | ~50k tokens | ~3k tokens |
| Alta | ~100k tokens | ~5k tokens |

Con ~200k tokens para el orquestador, zona segura de fidelidad total:
~12-15 simples, ~8-10 medios, ~5-6 altos. Los números anteriores (10-12 / 6-8 / 4-5)
se calibraron con modelos más viejos. Opus 4.7 sostiene fidelidad de
instrucciones hasta ~120k tokens de contexto del orquestador antes de
mostrar degradación medible (antes era ~100k / 50% capacidad).

## Cuándo sacar un ticket del prompt
Si complejidad Alta Y 4+ subtareas de 5+ archivos cada una → ejecutar como ticket independiente en contexto principal.
