# /retrospective — Análisis retroactivo de sesiones

Analiza el historial de conversaciones de Claude Code para encontrar
patrones de fricción y sugerir mejoras sistémicas.

$ARGUMENTS

<!--
Uso:
  /retrospective                    → analiza las últimas 5 sesiones
  /retrospective last 3 days        → sesiones de los últimos 3 días
  /retrospective sprint-a           → sesiones que mencionan "sprint-a"
-->

## Fase 1: Encontrar conversaciones

```bash
# Obtener el directorio del proyecto (buscar en las rutas codificadas)
ls ~/.claude/projects/

# Listar conversaciones recientes
# Ajustar -mtime según el argumento del usuario
ls -lt ~/.claude/projects/<encoded-path>/*.jsonl | head -20
```

Si el usuario especificó un rango de tiempo, filtrar por fecha.
Si especificó un término, filtrar por nombre o contenido.

## Fase 2: Análisis paralelo

Para cada archivo de conversación encontrado, lanzar un **subagente
general-purpose** que lo lea y extraiga:

1. **Objetivo:** ¿Qué intentaba hacer el usuario?
2. **Fricción:** Problemas que ocurrieron. Incluir citas textuales
   del usuario mostrando frustración o correcciones
3. **Victorias:** ¿Qué funcionó bien? ¿Qué patrones fueron efectivos?
4. **Patrones:** Ineficiencias repetidas, decisiones que Claude tomó
   mal, archivos que siempre resultan problemáticos

Priorizar archivos grandes (>500KB) — contienen las sesiones más sustanciosas.

Nota: Los archivos .jsonl pueden ser muy grandes. El subagente debe
buscar líneas con "role": "user" y "role": "assistant" para encontrar
los intercambios relevantes, y filtrar tool calls repetitivas.

## Fase 2b: Análisis de datos estructurados

Además de las conversaciones, analizar datos cuantitativos:

### .ai/runs/results.tsv
Leer `.ai/runs/results.tsv` (si existe) y calcular:
- **Total**: [N] keep / [N] discard / [N] crash
- **Por failure_category**: agrupar discards por categoría
  (scope_violation, test_failure, incomplete, rationalization, spec_ambiguity)
- **Tickets reincidentes**: tickets que aparecen >1 vez (descartados y reintentados)
- **Archivos conflictivos**: archivos que aparecen en tickets descartados

### .ai/done-tasks.md
Leer `.ai/done-tasks.md` (si existe) y extraer:
- Reglas agregadas/modificadas/eliminadas por ticket
- Infraestructura sugerida y si se implementó
- Patrones de "tiempo de contexto alto"

### Git history
```bash
git log --oneline --since="[fecha inicio]" | head -50
```
- Commits revertidos (señal de problemas)
- Frecuencia de commits por ticket (muchos = implementación difícil)

## Análisis de métricas operacionales

Si `.ai/runs/results.tsv` (o los archivados en `.ai/specs/archive/*/`) tienen columnas de métricas:

### Métricas de proceso (v2+: iterations, scope_warnings, complexity)
1. **Iteraciones por complejidad:** ¿Los tickets Media/Alta necesitan más intentos? ¿Hay un umbral donde la complejidad predice fallos?
2. **Scope warnings:** ¿Hay tickets que consistentemente tocan archivos fuera de scope? Esto sugiere scope fences demasiado estrictos o specs mal definidos.
3. **Ratio keep/discard por complejidad:** ¿Los tickets Alta fallan más? ¿Deberían subdividirse más agresivamente?
4. **Tendencias entre sprints:** ¿Las iteraciones promedio bajan con el tiempo? (señal de que /learn y experience library están funcionando)

### Métricas de topología (v3+: tokens_used, duration_s, rollback_count)
5. **Eficiencia por ticket:** tokens_used / complejidad. ¿Tickets Simple consumen proporcionalmente menos? Si un Simple consume tanto como un Alta, el spec probablemente está mal dimensionado.
6. **Velocidad de ejecución:** duration_s promedio por complejidad. Detectar outliers — un ticket Simple que tardó >5 min sugiere bloqueo o loops.
7. **Costo de rollbacks:** rollback_count total del sprint y correlación con failure_category. Muchos rollbacks por scope_violation = specs con scope fences ambiguos.
8. **Ratio tokens/rollback:** Si los tickets con rollbacks consumen >2x tokens que los limpios, considerar subdividir o mejorar los specs.
9. **Tendencia de eficiencia entre sprints:** ¿El tokens_used promedio por ticket baja entre sprints? (señal de que los prompts y specs están madurando)
10. **Top-3 tickets más caros:** Listar los 3 tickets con mayor tokens_used — analizar si la complejidad lo justifica o si hubo loops evitables.

Reportar hallazgos como insights candidatos para la experience library.

**Backward-compatibility:** El formato tiene 3 generaciones (v1=6 cols, v2=9 cols, v3=12 cols).
Detectar versión contando columnas. Omitir silenciosamente las secciones de métricas que
correspondan a columnas faltantes. NUNCA fallar por formato viejo.

## Fase 3: Sintetizar

Después de que todos los subagentes terminen, combinar hallazgos
de AMBAS fuentes (conversaciones + datos estructurados).

**Generalizar agresivamente.** No listar cada error individual sino
buscar el meta-patrón detrás de errores similares.

Agrupar por:
- **Patrones de fricción** — rankeados por frecuencia
  (ej: "Claude cambia archivos que el spec no menciona" × 4 sesiones)
- **Lo que funciona bien** — no perder esto
  (ej: "Los specs con rutas exactas siempre se ejecutan limpio")
- **Citas de frustración** — evidencia cruda del usuario
- **Categorías de fallo cuantitativas** — de .ai/runs/results.tsv
  (ej: "scope_violation: 5 ocurrencias, 80% en dominio eléctrico")

## Fase 4: Cross-reference contra configuración actual

Leer la configuración vigente:
- CLAUDE.md del proyecto
- CLAUDE.md del usuario (~/.claude/CLAUDE.md) si existe
- Skills en .claude/skills/ y ~/.claude/skills/
- Agentes custom en .claude/agents/
- Hooks en .claude/settings.json

Para cada patrón de fricción, clasificar:

| Clasificación | Qué significa | Acción |
|--------------|---------------|--------|
| **Ya arreglado** | Existe una regla que lo cubre | Anotar dónde. Si sigue ocurriendo, la regla no es efectiva |
| **Parcialmente cubierto** | Hay una regla pero no es suficiente | Sugerir cómo reforzarla |
| **No cubierto** | No hay nada que lo prevenga | Sugerir regla nueva |
| **Causado por la config** | La configuración actual CAUSA el problema | Sugerir corrección |

## Fase 5: Generar reporte

Crear `RETROSPECTIVE.md` con:

```markdown
# Retrospectiva — [fecha]

Basado en análisis de [N] conversaciones del [rango de fechas].

## Patrones de fricción (por frecuencia)

### 1. [Nombre del patrón] — [N] ocurrencias
**Problema:** [Descripción]
**Citas:** "[texto del usuario]"
**Estado:** [Ya arreglado en X | No cubierto | Parcialmente cubierto]
**Sugerencia:**
```markdown
[Texto propuesto para CLAUDE.md o agente o hook]
```

### 2. [Siguiente patrón]
...

## Lo que funciona bien (no tocar)

| Patrón | Por qué funciona | Dónde está |
|--------|-----------------|------------|
| ... | ... | ... |

## Infraestructura sugerida

| Tipo | Nombre | Propósito | Prioridad |
|------|--------|-----------|-----------|
| Regla CLAUDE.md | ... | ... | Alta |
| Agente custom | ... | ... | Media |
| Hook | ... | ... | Baja |
| Skill nuevo | ... | ... | Baja |

## Log crudo de fricción

- "[cita 1]" — sesión [fecha]
- "[cita 2]" — sesión [fecha]
```

**NO aplicar cambios automáticamente.** Crear el archivo para
revisión del usuario. La retrospectiva es diagnóstico, no tratamiento.

## Después del reporte

Preguntar al usuario:
"¿Querés que aplique alguna de estas sugerencias? Puedo actualizar
CLAUDE.md, crear agentes custom, o instalar hooks según lo que
te parezca útil."
