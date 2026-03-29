# /preflight — Validación pre-ejecución de specs

Validá los specs del sprint antes de ejecutar. $ARGUMENTS

<!--
Este comando usa la MISMA lógica que el Paso 3.5 del skill.
Un solo motor de validación, dos puntos de entrada:
- Cowork lo corre como Paso 3.5 al generar el paquete
- El usuario lo corre como /preflight antes de ejecutar en Claude Code
-->

## Instrucciones

Leé todos los archivos en `specs/` y para cada uno, validá los siguientes campos.
Si se pasó un argumento (ej: `/preflight ticket-3`), validar solo ese spec.

### Campos obligatorios (FAIL si falta)

| Campo | Dónde verificar | Qué buscar |
|-------|----------------|------------|
| **Objetivo** | `## Objetivo` | 1-2 frases, no vacío |
| **Modo de ejecución** | `## Modo de ejecución` | "Subagente" o "Sesión principal" |
| **Scope fence** | `## Scope fence` | Al menos 1 archivo en "permitidos" Y al menos 1 en "prohibidos" |
| **Archivos a modificar/crear** | `## Archivos a modificar` o `## Archivos a crear` | Al menos 1 archivo con ruta exacta |
| **Tests** | `## Tests que deben pasar` | Comando exacto + al menos 1 test descrito |
| **Criterios de aceptación** | `## Criterios de aceptación` | Al menos 1 criterio observable |
| **Commit message** | Dentro de Subtareas o Pasos | Formato `"[tipo]: [descripción]"` |

### Campos warning (WARN si falta, no bloquea)

| Campo | Dónde verificar | Qué buscar |
|-------|----------------|------------|
| **Restricciones** | `## NO hacer` | Al menos 1 restricción en forma imperativa |
| **Dependencias** | `## Dependencias` | Que no diga "Requiere: [Ticket X]" donde X no tenga spec |
| **Complejidad** | `## Complejidad` | Simple, Media, o Alta (no vacío) |
| **Pasos concretos** | Subtareas | Sin pasos vagos como "investigar", "explorar", "revisar" |

### Validaciones cruzadas

1. **Scope fence vs archivos**: Todo archivo en "Archivos a modificar/crear"
   debe estar en la allowlist del scope fence. Si no → FAIL.

2. **Dependencias rotas**: Si el spec dice "Requiere: Ticket X completado",
   verificar que `specs/ticket-X.md` existe. Si no → WARN.

3. **Restricciones excesivas**: Contar total de restricciones en `## NO hacer`.
   Si >10 → WARN ("más de 10 constraints causa omisiones").

## Formato de salida

Para cada spec, reportar:

```
## specs/ticket-[N].md — [PASS | PASS WITH WARNINGS | FAIL]

✅ Objetivo: presente
✅ Scope fence: 4 permitidos, 2 prohibidos
❌ Tests: falta comando exacto
⚠️ Restricciones: 12 (recomendado ≤10)
...
```

### Resumen final

```
Sprint preflight:
  PASS: [N] specs
  WARN: [N] specs (ejecutables pero revisar)
  FAIL: [N] specs (NO ejecutar hasta corregir)

Specs que DEBEN corregirse antes de ejecutar:
- specs/ticket-[N].md: [campos faltantes]
```

## Severidad

- **FAIL**: El spec no puede ejecutarse de forma confiable. Corregir antes de lanzar.
- **PASS WITH WARNINGS**: Ejecutable pero con riesgo. Revisar los warnings.
- **PASS**: Todos los campos obligatorios presentes y consistentes.

NO ejecutar un sprint si hay specs con FAIL. El orquestador va a tener
problemas de precisión o va a producir resultados incorrectos.

$ARGUMENTS
