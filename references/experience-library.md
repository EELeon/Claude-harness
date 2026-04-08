# Experience Library — Biblioteca de experiencia acumulada

## Propósito

La experience library acumula insights destilados de ejecuciones exitosas y fallidas.
Evoluciona el registro narrativo de `done-tasks.md` en un sistema de conocimiento
consultable que mejora las decisiones del orquestador entre sprints.

**Jerarquía de conocimiento:**
- `.ai/done-tasks.md` — registro narrativo cronológico (todas las observaciones)
- `.ai/experience/` — conocimiento destilado (solo insights que pasaron sustracción causal)
- `references/recovery-matrix.md` — acciones estándar ante situaciones de error (NO duplicar acá)

---

## Estructura de la library

```
.ai/experience/
├── orchestration.md      # Insights sobre orquestación (orden, paralelismo, compactación)
├── implementation.md     # Insights sobre implementación (patrones de código, errores comunes)
├── testing.md            # Insights sobre testing (qué tests fallan, por qué)
└── recovery.md           # Insights sobre recovery (complementa recovery-matrix.md)
```

NUNCA crear estos archivos manualmente — se crean con el primer `/learn` que genere un insight para esa categoría.

---

## Formato de cada insight

```markdown
### [ID]: [Título descriptivo]
- **Perfil:** [Tipo de ticket/situación donde aplica]
- **Insight:** [Qué se aprendió — 1-2 líneas]
- **Utilidad:** [N/M aplicaciones exitosas] (ej: 5/6 = aplicado 5 de 6 veces con éxito)
- **Acción:** [Qué hacer cuando se detecta este perfil]
- **Origen:** [batch, ticket, fecha]
- **Última actualización:** [fecha]
```

**Convención de IDs:** `[categoría]-[número secuencial]` (ej: `orch-001`, `impl-003`, `test-002`, `recv-001`).

---

## Operaciones de consolidación

Inspiradas en HERA (Hierarchical Experience Retrieval and Accumulation).

### ADD — Insertar insight nuevo

**Cuándo aplicar:**
- El insight pasó el test de sustracción causal ("si no existiera este insight, qué error concreto ocurriría?")
- No existe un insight semánticamente similar en la misma categoría
- No duplica contenido de `references/recovery-matrix.md`

**Procedimiento:**
1. Asignar ID siguiendo la convención `[categoría]-[NNN]`
2. Llenar todos los campos del formato
3. Inicializar utilidad en `1/1`
4. Crear el archivo de categoría si no existe

### MERGE — Combinar insights similares

**Cuándo aplicar:**
- Dos o más insights aplican al mismo perfil de ticket/situación
- La combinación es más general sin perder precisión
- Los insights tienen acciones compatibles (no contradictorias)

**Procedimiento:**
1. Crear un insight nuevo con el perfil ampliado
2. Sumar los contadores de utilidad de ambos (ej: 3/4 + 2/3 = 5/7)
3. Mantener el ID del insight más antiguo
4. Eliminar el insight absorbido
5. Actualizar la fecha de última actualización

### PRUNE — Eliminar insight obsoleto

**Cuándo aplicar:**
- Utilidad <30% después de 5+ aplicaciones (falló más veces de las que ayudó)
- Referencia archivos, APIs, o herramientas que ya no existen en el proyecto
- Contradice un insight más reciente con mayor utilidad

**Procedimiento:**
1. Registrar en `done-tasks.md`: "PRUNE: [ID] eliminado — [razón]"
2. Eliminar el insight del archivo de categoría
3. Si el archivo queda vacío, eliminarlo

### KEEP — Sin cambios

**Cuándo aplicar:**
- Ninguna de las condiciones de ADD, MERGE, o PRUNE aplica
- El insight sigue siendo válido y útil
- La utilidad es >=30% o tiene <5 aplicaciones

**Procedimiento:**
- No hacer nada. KEEP es la operación por defecto.

---

## Ciclo de vida

| Momento | Disparador | Operaciones esperadas |
|---------|-----------|----------------------|
| `/learn` por ticket | Después de cada ticket completado | ADD o MERGE (insights puntuales) |
| `/learn` de sprint completo | Al terminar todos los tickets del batch | MERGE + PRUNE (consolidación) |
| `/retrospective` | Auditoría profunda entre sprints | PRUNE agresivo + detección de patrones |

---

## Consulta por el orquestador

Al inicio de cada sprint, el orquestador:
1. Lee los archivos en `.ai/experience/` (si existen)
2. Busca insights cuyo **Perfil** coincida con los tickets del sprint
3. Tiene en cuenta los insights relevantes al verificar resultados de subagentes

**Restricciones de consulta:**
- NUNCA dejar que la experience library modifique los specs — los specs son la fuente de verdad
- La consulta es condicional: "si existen archivos en `.ai/experience/`" — NO es obligatoria
- Los insights informan verificación, NO ejecución

---

## Criterios de calidad

Un insight de alta calidad cumple:
1. **Especificidad:** describe un perfil concreto, no una generalidad
2. **Accionabilidad:** la acción es ejecutable sin ambigüedad
3. **Verificabilidad:** se puede medir si el insight ayudó o no (contador de utilidad)
4. **No-redundancia:** no duplica recovery-matrix.md, CLAUDE.md, ni otro insight
5. **Sustracción causal:** sin el insight, un error concreto ocurriría
