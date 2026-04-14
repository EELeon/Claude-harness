# Taxonomía de failure modes

## Propósito

Este documento define las categorías de fallo reconocidas por el harness
y el formato en que se registran en proyectos target.

## Categorías de fallo

### Fallos de ejecución
| Código | Nombre | Descripción | Señal típica |
|--------|--------|-------------|-------------|
| EXEC-01 | no_commit | Subagente no hizo commit atómico | Hash pre/post idénticos |
| EXEC-02 | scope_violation | Tocó archivos en denylist | diff --name-only vs denied_paths |
| EXEC-03 | test_failure | Tests fallan después de 2 intentos | Exit code ≠ 0 persistente |
| EXEC-04 | crash | Error sistémico impide ejecución | Subagente no devuelve resultado |

### Fallos de cierre (falso cierre)
| Código | Nombre | Descripción | Señal típica |
|--------|--------|-------------|-------------|
| CLOSE-01 | incomplete | Criterios de aceptación no cumplidos | <80% criterios verificados |
| CLOSE-02 | rationalization | Subagente declara victoria sin evidencia | diff vacío o no coincide con spec |
| CLOSE-03 | spec_ambiguity | Spec ambiguo causó implementación incorrecta | Resultado no corresponde a objetivo |
| CLOSE-04 | verification_failed | Checks determinísticos de cierre fallan | Artefacto faltante, tipo incorrecto |

### Fallos de spec (prevenibles en preflight)
| Código | Nombre | Descripción | Señal típica |
|--------|--------|-------------|-------------|
| SPEC-01 | scope_too_broad | Ticket debía partirse | ≥2 señales de descomposición activas |
| SPEC-02 | missing_context | Spec no autocontenido | Subagente tuvo que explorar |
| SPEC-03 | vague_criteria | Criterios no verificables | Auditor no puede confirmar cierre |

## Patrones de falso cierre conocidos

Estos patrones se inyectan en el prompt del auditor como checklist.

1. **"Todo funciona" sin tests** — subagente reporta éxito pero no corrió tests
2. **Commit parcial** — commit existe pero no incluye todos los archivos del spec
3. **Scope creep disfrazado** — tocó archivos fuera de allowlist "porque era necesario"
4. **Doc sin código** — ticket pedía implementación + docs, solo entregó docs
5. **Refactor en vez de feature** — mejoró código existente sin implementar lo pedido

## Formato del archivo de failure modes en proyecto target

El orquestador genera `.ai/failure-modes.md` en el proyecto target.
`/learn` lo actualiza cuando un ticket tiene status `discard`.

```
# Failure Modes — [nombre-proyecto]

## Registro de fallos

| Fecha | Ticket | Código | Categoría | Descripción | Acción preventiva |
|-------|--------|--------|-----------|-------------|------------------|
| 2026-04-14 | T-5 | EXEC-03 | test_failure | Tests de integración fallan por DB no mockeada | Agregar setup de DB al spec |

## Patrones recurrentes

<!-- Se actualiza cuando el mismo código aparece 3+ veces -->

| Patrón | Frecuencia | Última vez | Acción sistémica |
|--------|-----------|------------|-----------------|
| EXEC-03 en tickets con DB | 4 veces | 2026-04-14 | Agregar "verificar setup de DB" al preflight |
```
