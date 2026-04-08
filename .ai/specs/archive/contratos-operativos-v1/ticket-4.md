# Ticket 4 — Recovery Matrix (matriz de recuperación de errores)

## Objetivo

Crear un protocolo documentado de recuperación para las situaciones operacionales más comunes que rompen sesiones del orquestador. Esto reemplaza intuición ad-hoc con acciones estándar consultables, reduciendo dependencia del juicio del usuario en momentos de estrés.

## Complejidad: Simple

## Dependencias

- Requiere: Ninguna
- Bloquea: Ninguno

## Modo de ejecución: Subagente

---

## Scope fence (alcance permitido)

### Archivos permitidos
- `references/recovery-matrix.md`
- `templates/orchestrator-prompt.md`

### Archivos prohibidos
- `CLAUDE.md` — se actualiza solo via /learn
- `templates/spec-template.md` — lo toca T-2
- `.claude/settings.json` — configuración de hooks, fuera de scope
- `references/output-budgets.md` — lo crea T-1

---

## Archivos a crear

| Archivo | Contenido |
|---------|-----------|
| `references/recovery-matrix.md` | Documento de referencia con tabla de situaciones, acciones estándar, y protocolo de recuperación |

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `templates/orchestrator-prompt.md` | Agregar referencia a la recovery matrix en la sección de reglas, para que el orquestador la consulte ante errores |

---

## Subtareas

### Implementación directa

**Pasos:**
1. Crear `references/recovery-matrix.md` con:
   - Tabla principal con 9 situaciones y sus acciones:

     | Situación | Señal de detección | Acción | Detalle |
     |---|---|---|---|
     | Contexto pesado (>80%) | Orquestador reporta lentitud o paraphrase loss | `shrink` | Microcompact + /compact |
     | Subagente tangencial | Heat Shield muestra archivos fuera de scope | `rollback` | git reset --hard + re-spec |
     | Test suite lenta | Tests tardan >5min sin terminar | `split` | Separar tests lentos, marcar como known-slow |
     | Comando no disponible | Error de herramienta o permiso | `retry` | Fallback documentado por tipo |
     | CI falla post-PR | Pipeline falla después de crear PR | `escalate` | Sesión principal con diagnóstico |
     | Sesión cortada | Claude Code se desconecta | `continue` | Leer .ai/runs/results.tsv + retomar |
     | Spec ambiguo | Subagente reporta "asumí" o "interpreté" | `split ticket` | Dividir + re-spec con usuario |
     | Output demasiado grande | Salida excede límites de result budgeting | `archive artifact` | Truncar + persistir a disco |
     | Batch con colisión | Dos subagentes tocaron mismo archivo | `rollback` | Reclasificar execution_class |

   - Para cada situación: descripción expandida, señales de detección, pasos exactos de la acción, y ejemplo concreto
   - Sección "Cómo usar este documento": el orquestador lo consulta cuando detecta una anomalía; el usuario lo consulta cuando una ejecución falla

2. Leer `templates/orchestrator-prompt.md` y agregar al final de la sección de notas para el skill (antes de `---`):
   - Una referencia: "Cuando detectes una anomalía durante la ejecución, consultá `references/recovery-matrix.md` para la acción estándar. No improvisar recuperaciones — seguir el protocolo documentado."

3. Verificar que las 9 situaciones están documentadas con acción y detalle
4. Commit: `"feat(T-4): agregar recovery matrix con 9 situaciones y acciones estándar"`

## Tests que deben pasar

```bash
# Verificar que el archivo existe y tiene contenido
test -s references/recovery-matrix.md && echo "PASS" || echo "FAIL"
# Verificar que contiene las 9 situaciones
SITUATIONS=$(grep -c "^|" references/recovery-matrix.md)
test "$SITUATIONS" -ge 9 && echo "PASS: $SITUATIONS rows" || echo "FAIL: $SITUATIONS rows (need ≥9)"
# Verificar referencia en orchestrator-prompt
grep -q "recovery-matrix" templates/orchestrator-prompt.md && echo "PASS" || echo "FAIL"
```

- [ ] `test_file_exists`: El archivo `references/recovery-matrix.md` existe y no está vacío
- [ ] `test_situations_count`: El archivo contiene al menos 9 situaciones con acciones
- [ ] `test_reference_in_prompt`: `templates/orchestrator-prompt.md` referencia `references/recovery-matrix.md`

## Criterios de aceptación

- [ ] Existe `references/recovery-matrix.md` con tabla de 9 situaciones
- [ ] Cada situación tiene: señal de detección, acción estándar, y detalle/pasos
- [ ] Al menos 3 situaciones tienen un ejemplo concreto
- [ ] `templates/orchestrator-prompt.md` referencia la recovery matrix
- [ ] El documento incluye sección de "Cómo usar" dirigida al orquestador y al usuario

## NO hacer

- NUNCA inventar situaciones hipotéticas que no ocurran en el flujo actual — las 9 listadas cubren los casos reales documentados
- NUNCA crear lógica automática de recovery — este documento es una referencia consultable, no un motor de decisión
- NUNCA duplicar las reglas de rollback que ya están en `templates/orchestrator-prompt.md` (Regla 2) — referenciarlas
- NUNCA modificar la sección Heat Shield del prompt — eso es scope de T-1

---

## Checklist de autocontención

- [x] ¿Tiene scope fence (archivos permitidos + prohibidos)?
- [x] ¿Tiene rutas EXACTAS de archivos a modificar/crear?
- [x] ¿Tiene pasos concretos (no "investigar" o "explorar")?
- [x] ¿Tiene comando exacto de tests?
- [x] ¿Tiene commit message definido?
- [x] ¿Tiene criterios de aceptación observables?
- [x] ¿Tiene restricciones claras en forma imperativa (NUNCA/SIEMPRE)?
- [x] ¿Tiene ≤10 restricciones totales?
- [x] ¿No depende de contexto que solo existe en la conversación?
