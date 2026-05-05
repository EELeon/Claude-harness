# Result Budgeting — Presupuesto de salidas

## Principio

> No toda salida merece entrar al contexto.

Los outputs grandes contaminan el contexto del orquestador, degradan la fidelidad de instrucciones posteriores, y dificultan la reanudacion despues de /compact o /clear. Este documento define limites formales por tipo de salida para mantener el contexto lean.

---

## Limites por tipo de salida

| Tipo de salida | Clave | Limite (chars) | Contexto tipico |
|----------------|-------|----------------|-----------------|
| Resumen de subagente | `summary_max_chars` | 500 | Reporte lean: 1-3 lineas de que se hizo |
| Output de tests | `test_output_max_chars` | 1000 | Resultado de correr la suite de tests del ticket |
| Extracto de diff | `diff_excerpt_max_chars` | 2000 | Diff para auditorias de scope o completitud |
| Preview de logs | `log_preview_max_chars` | 500 | Logs de build, CI, o errores de ejecucion |

Cada limite es un valor numerico concreto en caracteres. NO usar rangos ni valores ambiguos.

---

## Regla de truncamiento

Si una salida excede el limite definido para su tipo:

1. **Persistir** el output completo en `.ai/artifacts/[tipo]/[ticket]-[timestamp].txt`
2. **Retornar al contexto** SOLO:
   - Resumen del contenido (maximo 3 lineas)
   - Tamano original (ej: "2847 chars")
   - Ruta del archivo persistido (ej: `.ai/artifacts/test-outputs/T-3-20260407.txt`)
   - Primeras N lineas del output original (hasta alcanzar el limite del tipo)

**Formato de retorno truncado:**
```
[TRUNCADO] Output de tests (2847 chars) → .ai/artifacts/test-outputs/T-3-20260407.txt
Primeras lineas:
  PASS test_file_exists
  PASS test_reference_in_prompt
  FAIL test_integration (expected 200, got 404)
  ... (ver archivo completo en ruta indicada)
```

---

## Estructura de carpetas para artifacts

```
.ai/artifacts/
  test-outputs/    # Outputs completos de suites de tests
  diffs/           # Diffs extensos de auditorias de scope
  logs/            # Logs de build, CI, errores de ejecucion
```

NUNCA crear estos directorios de antemano. Se crean bajo demanda cuando haya un output real que exceda el limite.

---

## Ejemplo: antes y despues

### Antes (sin budgeting)
El subagente devuelve el output completo de tests al orquestador:

```
PASS test_file_exists (0.01s)
PASS test_reference_in_prompt (0.02s)
PASS test_limits_defined (0.01s)
PASS test_integration_module_a (0.15s)
PASS test_integration_module_b (0.22s)
FAIL test_integration_module_c (0.18s)
  AssertionError: expected status 200 but got 404
  at TestIntegration.test_module_c (test_integration.py:45)
  at Runner.run_single (runner.py:112)
PASS test_regression_1 (0.05s)
PASS test_regression_2 (0.03s)
... (40 lineas mas de output)
```

Esto consume ~1500+ chars del contexto del orquestador sin aportar valor incremental.

### Despues (con budgeting)
El subagente aplica el limite `test_output_max_chars: 1000`:

```
[TRUNCADO] Output de tests (1847 chars) → .ai/artifacts/test-outputs/T-5-20260407.txt
Primeras lineas:
  5 passed, 1 failed
  FAIL test_integration_module_c: expected 200, got 404
  (ver archivo completo en ruta indicada)
```

El orquestador recibe solo lo necesario para decidir keep/discard. Si necesita el detalle, lee el archivo de disco.
