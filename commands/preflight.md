# /preflight — Validación pre-ejecución de specs

Validá los specs del sprint antes de ejecutar. $ARGUMENTS

<!--
Este comando usa la MISMA lógica que el Paso 3.5 del skill.
Un solo motor de validación, dos puntos de entrada:
- Cowork lo corre como Paso 3.5 al generar el paquete
- El usuario lo corre como /preflight antes de ejecutar en Claude Code
-->

## Instrucciones

Leé todos los archivos en `.ai/specs/active/` y para cada uno, validá los siguientes campos.
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
   verificar que `.ai/specs/active/ticket-X.md` existe. Si no → WARN.

3. **Restricciones excesivas**: Contar total de restricciones en `## NO hacer`.
   Si >10 → WARN ("más de 10 constraints causa omisiones").

4. **Condiciones de archivos condicionales**: Para cada archivo en
   `### Archivos condicionales`, verificar que la condición describe un
   cambio observable en el diff (no frases vagas como "si es necesario").
   Si la condición es vaga o no verificable → WARN ("condición no verificable").

### Validaciones estructurales (deterministas)

Estas validaciones son mecánicas — no requieren interpretación semántica.
Ejecutarlas PRIMERO, antes de las validaciones de contenido.

**Nivel 0: Frontmatter YAML (FAIL si falta o inválido)**

El spec DEBE tener un bloque YAML frontmatter válido entre `---` markers.
Ejecutar PRIMERO — si no hay frontmatter, no continuar con otros niveles.

Validaciones:
1. El archivo empieza con `---` en la primera línea (después del H1 si hay)
   o tiene un bloque delimitado por `---` al inicio
2. El bloque YAML es parseable (no tiene errores de sintaxis)
3. Campos obligatorios presentes (FAIL si falta alguno):

| Campo | Tipo | Valores válidos |
|-------|------|-----------------|
| id | string | No vacío, formato `[prefix]-[seq]` |
| title | string | No vacío |
| goal | string | No vacío, 1-2 frases |
| complexity | enum | Simple, Media, Alta |
| execution_mode | enum | Subagente, Sesion_principal |
| execution_class | enum | read_only, isolated_write, shared_write, repo_wide |
| allowed_paths | list[str] | Al menos 1 entrada |
| denied_paths | list[str] | Al menos 1 entrada |
| closure_criteria | list[str] | Al menos 1 entrada |
| required_validations | list[str] | Al menos 1 entrada |
| max_attempts | int | > 0 |

4. Campos de iteración presentes si complexity != Simple:

| Campo | Tipo | Requerido si |
|-------|------|-------------|
| retry_only_if | list[str] | complexity = Media o Alta |
| escalate_if | list[str] | complexity = Media o Alta |
| blocked_if | list[str] | Siempre (puede ser vacío) |
| discard_if | list[str] | Siempre |

5. Campos de descomposición presentes si complexity != Simple:

| Campo | Tipo | Requerido si |
|-------|------|-------------|
| decomposition_signals | int | complexity = Media o Alta |
| decomposition_decision | enum | complexity = Media o Alta. Valores: unico, partido_en_N |

Si el frontmatter falta completamente → FAIL con "frontmatter YAML no encontrado".
Si un campo obligatorio falta → FAIL con "campo faltante: [nombre]".
Si un valor es inválido → FAIL con "valor inválido para [campo]: [valor]".

**Nivel 1: Existencia de headings (FAIL si falta)**

Verificar que el spec contiene EXACTAMENTE estos headings markdown:
```
## Objetivo
## Scope fence
### Archivos permitidos
### Archivos prohibidos
## Archivos a modificar
## Tests que deben pasar
## Criterios de aceptación
## NO hacer
```

Método: buscar la cadena exacta del heading. No interpretar sinónimos.
Si el heading falta o tiene otro nombre → FAIL con "heading faltante: [nombre]".

**Nivel 2: Contenido no vacío (FAIL si vacío)**

Para cada heading obligatorio, verificar que hay al menos 1 línea de
contenido entre ese heading y el siguiente heading (excluyendo comentarios
HTML `<!-- -->` y líneas en blanco).

Método: contar líneas de contenido. Si = 0 → FAIL con "[heading] está vacío".

**Nivel 3: Formato de datos (FAIL si no cumple)**

| Check | Qué verificar | Regex / patrón |
|-------|--------------|----------------|
| Rutas de archivos | Cada archivo en allowlist/denylist tiene backtick | Línea contiene `` `[ruta]` `` |
| Commit message | Existe al menos 1 commit message con formato | `"[tipo]: [descripción]"` |
| Comando de tests | Existe bloque de código bash con comando | ` ```bash ` seguido de al menos 1 línea no vacía |
| Criterios checkbox | Cada criterio es un checkbox markdown | `- [ ]` al inicio de línea |
| Restricciones imperativas | Cada restricción empieza con NUNCA/SIEMPRE/NO | Primera palabra de la línea después de `- ` |

**Nivel 4: Cruces numéricos (WARN/FAIL)**

| Check | Cálculo | Resultado |
|-------|---------|-----------|
| Archivos permitidos ≥ archivos a modificar/crear | count(allowlist) ≥ count(archivos) | FAIL si archivos > allowlist |
| Archivos prohibidos > 0 | count(denylist) > 0 | FAIL si denylist vacía |
| Restricciones ≤ 10 | count(líneas en NO hacer) | WARN si > 10 |
| Criterios de aceptación ≥ 1 | count(checkboxes en Criterios) | FAIL si = 0 |
| Tests ≥ 1 | count(checkboxes en Tests) | FAIL si = 0 |

**Nivel 5: Validación de descomposición y triage previo (FAIL si incoherente)**

Solo para specs con complexity = Media o Alta.
Para specs Simple, saltar este nivel.

**5a. Verificar que el triage (Paso 1.5) ocurrió:**

Si el spec tiene decomposition_signals ≥ 2 Y decomposition_decision = "unico":
- FAIL con "ticket con ≥2 señales de complejidad debe partirse en sub-tickets.
  Esto debió detectarse en el Paso 1.5 (triage de tamaño). Volver al triage
  antes de continuar. Ver: references/flujo-principal.md → Paso 1.5"

Si el spec tiene complexity = Alta Y decomposition_decision = "unico":
- FAIL con "ticket de complejidad Alta no puede mantenerse como único sin
  justificación explícita en el triage. Volver al Paso 1.5"

**5b. Validaciones de descomposición (existentes):**

1. La sección `## Análisis de descomposición` existe y no está vacía
2. El campo `decomposition_signals` del frontmatter coincide con el
   conteo de señales marcadas como "sí" en la sección
3. Coherencia señales → decisión:
   - Si decomposition_signals ≥ 2 Y decomposition_decision = "unico" → FAIL
     (capturado en 5a, redundante pero explícito)
   - Si decomposition_signals < 2 Y decomposition_decision = "unico" → OK
   - Si decomposition_decision = "partido_en_N" → OK (ya se partió)
4. Verificación cruzada de señales contra datos del spec:
   - Señal "más de 8 archivos": contar allowed_paths del frontmatter.
     Si count > 8 y señal marcada "no" → WARN "posible señal no detectada"
   - Señal "más de 4 criterios independientes": contar closure_criteria.
     Si count > 4 y señal marcada "no" → WARN
   - Señal "más de 2 módulos": contar directorios únicos en allowed_paths.
     Si count > 2 y señal marcada "no" → WARN

**Orden de ejecución:**
0. Nivel 0 (frontmatter) — si falla, no continuar
1. Nivel 1 (headings) — si falla, no continuar con niveles 2-5
2. Nivel 2 (no vacío) — si falla, reportar pero continuar con nivel 3-5
3. Nivel 3 (formato) — reportar todo
4. Nivel 4 (cruces numéricos) — reportar todo
5. Nivel 5 (descomposición) — solo para Media/Alta
6. Validaciones semánticas (campos obligatorios + warnings + cruzadas)

Esto separa lo que se puede verificar mecánicamente (niveles 0-5) de lo
que requiere interpretación (campos semánticos). Los niveles 0-5 son
deterministas: el mismo spec siempre produce el mismo resultado.

## Formato de salida

Para cada spec, reportar:

```
## .ai/specs/active/ticket-[N].md — [PASS | PASS WITH WARNINGS | FAIL]

### Estructural (determinista)
✅ Frontmatter: 11/11 campos obligatorios, YAML válido
✅ Headings: 8/8 presentes
✅ Contenido no vacío: 8/8 secciones
❌ Formato: commit message sin formato "[tipo]: descripción"
✅ Cruces: 4 permitidos ≥ 3 archivos, 2 prohibidos, 2 criterios, 3 tests

### Descomposición (Nivel 5)
✅ Triage previo: ticket pasó Paso 1.5 con <2 señales
❌ Triage faltante: 3/6 señales activas, debió partirse en Paso 1.5
✅ Señales: 1/6 activas, decisión "unico" coherente
❌ Señales: 3/6 activas, decisión "unico" INCOHERENTE — debe partirse

### Semántico
✅ Objetivo: presente, 1 frase
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
- .ai/specs/active/ticket-[N].md: [campos faltantes]
```

## Severidad

- **FAIL**: El spec no puede ejecutarse de forma confiable. Corregir antes de lanzar.
- **PASS WITH WARNINGS**: Ejecutable pero con riesgo. Revisar los warnings.
- **PASS**: Todos los campos obligatorios presentes y consistentes.

NO ejecutar un sprint si hay specs con FAIL. El orquestador va a tener
problemas de precisión o va a producir resultados incorrectos.

$ARGUMENTS
