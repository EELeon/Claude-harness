# Reglas de división en subtareas y sizing de subagentes

## Contexto técnico

Un subagente de Claude Code:
- Tiene su propia ventana de contexto (~200k tokens), separada del agente principal
- No puede crear otros subagentes (sin anidación)
- Devuelve solo su resultado final al agente padre (no el contexto intermedio)
- Puede correr en paralelo con otros subagentes
- Tiene acceso restringido a herramientas según su configuración
- **Máximo 5 subagentes concurrentes** por codebase — más de 5 causa
  fallos de coordinación y degradación sistémica (confirmado empíricamente)
- Empieza con **contexto en blanco** — NO hereda la conversación del padre.
  Todo lo que necesita saber debe ir en el prompt de delegación

## Cuándo dividir un ticket en subtareas con subagentes

### NO dividir (ejecución directa)

El ticket se ejecuta directo en el contexto principal cuando:
- Toca ≤ 3 archivos
- Tiene ≤ 3 pasos lógicos secuenciales
- No requiere exploración del codebase
- Es principalmente CRUD o configuración
- Ejemplo: agregar una nueva tabla de configuración — crear modelo, parser, validador

### Dividir en 2-3 subtareas

Cuando el ticket:
- Toca 4-8 archivos
- Tiene pasos que pueden paralelizarse
- Mezcla exploración con implementación
- Ejemplo: implementar un nuevo módulo de cálculo
  - Subtarea 1: Modificar config/UI para soportar nuevos campos
  - Subtarea 2: Implementar lógica de cálculo principal
  - Subtarea 3: Conectar output con el pipeline existente

### Dividir en 3-5 subtareas

Cuando el ticket:
- Toca 9+ archivos
- Tiene lógica algorítmica compleja
- Requiere investigación previa del codebase
- Tiene múltiples dominios internos
- Ejemplo: reescribir un motor de procesamiento con múltiples subsistemas
  - Subtarea 1 (Explore): Investigar estructura actual del módulo
  - Subtarea 2: Implementar agrupación por subsistema
  - Subtarea 3: Implementar detección de relaciones entre entidades
  - Subtarea 4: Implementar lógica de transformación por cambio de tipo
  - Subtarea 5: Conectar con output final y validar contra catálogo

## Reglas para definir subtareas bien formadas

### Cada subtarea DEBE ser autocontenida

Un subagente recibe SOLO:
1. El prompt que le pasa el agente padre
2. Su system prompt (si es un agente custom)
3. Acceso a leer/escribir archivos del repo

NO recibe:
- El contexto de la conversación principal
- Los resultados de otros subagentes (a menos que se escriban a disco)

Por lo tanto, cada subtarea debe incluir:
- Rutas exactas de archivos a tocar
- Qué hace cada archivo relevante (1 línea)
- Instrucciones paso a paso
- Criterio de "terminé" claro

### Patrón de comunicación entre subtareas

Si la subtarea 2 necesita el resultado de la subtarea 1:
1. Subtarea 1 escribe su output a un archivo conocido
2. Subtarea 2 lee ese archivo como input
3. El spec documenta esta dependencia explícitamente

Si las subtareas son independientes, marcarlas para ejecución paralela.

### Prompt template para delegar a subagente

En el spec, cada subtarea marcada como subagente incluye el prompt listo:

```
Implementa [nombre de subtarea] para [proyecto].

Archivos a modificar:
- `ruta/archivo1.py` — [qué contiene actualmente, qué cambiar]
- `ruta/archivo2.py` — [ídem]

Pasos:
1. [Paso concreto]
2. [Paso concreto]
3. Correr tests: `pytest tests/test_X.py -v`

Commit cuando termines con mensaje: "[tipo]: [descripción]"

NO hagas:
- [Restricción relevante]
```

## Sizing por tipo de subagente built-in

| Tipo | Herramientas | Usar para |
|------|-------------|-----------|
| **Explore** | Read, Grep, Glob (solo lectura) | Investigar codebase antes de implementar |
| **Plan** | Read, Grep, Glob (solo lectura) | Diseñar arquitectura de un cambio complejo |
| **General-purpose** | Read, Write, Edit, Bash, Glob, Grep | Implementación completa de una subtarea |

## Sizing por complejidad del proyecto

### Proyecto pequeño (<50 archivos, <5k LOC)
- Rara vez necesita subagentes
- Los specs pueden ser más concisos
- 1 sesión puede cubrir 3-5 tickets simples con /clear

### Proyecto mediano (50-200 archivos, 5-20k LOC)
- Subagentes para tickets de complejidad media y alta
- Specs deben incluir rutas exactas
- 1 sesión puede cubrir 2-3 tickets con /clear

### Proyecto grande (200+ archivos, 20k+ LOC)
- Subagentes casi obligatorios
- Specs deben incluir contexto de arquitectura
- 1 ticket complejo puede consumir 1 sesión entera

## Patrón Heat Shield (retorno de subagentes)

El subagente NO debe devolver datos crudos al orquestador. El orquestador
necesita mantener su contexto lean para seguir orquestando.

**El subagente devuelve:**
- Resumen de qué se hizo (1-3 líneas)
- Hash del commit
- Estado de tests (passed/failed)
- Archivos tocados (lista)
- Estado de criterios de aceptación (sí/no/parcial por cada uno)

**El subagente NO devuelve:**
- Logs completos de ejecución
- Contenido de archivos leídos
- Output completo de tests (solo pass/fail + nombre del test que falló)

Este patrón protege al orquestador de acumular contexto innecesario
que acelera la degradación de la ventana.

## Errores comunes al dividir

1. **Subtareas demasiado granulares** — Si una subtarea es "agregar un campo a un dict", no necesita subagente. Agrupá cambios relacionados.

2. **Dependencias circulares** — Si A necesita el output de B y B necesita el de A, no son subtareas separables. Refactorizá la división.

3. **Subagente sin contexto suficiente** — Si el prompt no incluye qué hace el archivo que va a modificar, el subagente va a tener que explorarlo y gasta contexto innecesariamente. Incluir siempre: rutas exactas, qué hace cada archivo (1 línea), y el "por qué" estratégico.

4. **Olvidar el commit atómico** — Cada subtarea debe terminar con commit. Sin commit, si falla la siguiente subtarea, se pierde todo.

5. **Demasiados constraints en el prompt** — Máximo 10 restricciones por delegación. Más de 10 causa omisiones críticas del modelo.

6. **Más de 5 subagentes concurrentes** — Causa degradación sistémica por sobrecarga de coordinación. Si un ticket necesita más de 5 subtareas paralelas, serializar en grupos de ≤5.
