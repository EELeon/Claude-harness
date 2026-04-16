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
1. SUBAGENTES: contexto fresco por ticket. Heat Shield para resultados.
2. ESTADO EN DISCO: .ai/runs/results.tsv persiste entre /compact y /clear.
3. CHECKPOINT DINÁMICO: Evaluar contexto post-ticket. >70% sugerir compact, >85% reset.

## Limitaciones
- Claude Code NO puede ejecutar /clear programáticamente
- Los subagentes no pueden crear sub-subagentes
- Auto-compact maneja la mayoría de casos; el orquestador no necesita pedir /compact manualmente
- Máximo 5 subagentes concurrentes por codebase

## Estimación de contexto por ticket

| Complejidad | Contexto subagente | Contexto orquestador |
|-------------|-------------------|---------------------|
| Simple | ~20k tokens | ~2k tokens |
| Media | ~50k tokens | ~3k tokens |
| Alta | ~100k tokens | ~5k tokens |

Con ~200k tokens para el orquestador: ~10-12 simples, ~6-8 medios, ~4-5 altos.

## Cuándo sacar un ticket del prompt
Si complejidad Alta Y 4+ subtareas de 5+ archivos cada una → ejecutar como ticket independiente en contexto principal.
