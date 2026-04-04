# Meta — [Nombre del sistema]

<!--
EL META es el documento de verdad contra el cual audita el loop recursivo.
Define QUÉ debe ser capaz de hacer el sistema completo, no CÓMO.

REGLAS:
- Cada capacidad tiene un ID único (DOMINIO-NN)
- Cada capacidad tiene un criterio verificable por un agente (observable, no subjetivo)
- El meta NO describe implementación — eso va en los specs
- El meta es DECLARATIVO y EXHAUSTIVO sobre el alcance funcional
- El meta lo escribe el usuario (con ayuda del skill) y solo el usuario lo modifica
- El loop recursivo NUNCA muta el meta — si detecta que está incompleto, lo reporta

GRANULARIDAD:
- Cada capacidad = una funcionalidad que un usuario/sistema puede ejercer
- NO mezclar niveles: "el usuario puede registrarse" y "el botón tiene border-radius 4px"
  son niveles diferentes. El meta trabaja al nivel de capacidades, no de diseño visual
- Si una capacidad es muy grande, dividirla en sub-capacidades con sufijo (.1, .2)

CRITERIOS VERIFICABLES:
Un criterio es verificable si un agente Explore puede confirmar su cumplimiento
leyendo código, corriendo un comando, o verificando un archivo. Ejemplos:
  ✅ "POST /auth/register retorna 201 + usuario creado en DB"
  ✅ "Existe archivo src/auth/register.ts con función exportada registerUser"
  ✅ "npm test -- --grep 'register' pasa sin errores"
  ❌ "El sistema es seguro" (no observable)
  ❌ "La UX es buena" (subjetivo)
  ❌ "Es rápido" (sin threshold medible)
-->

## Visión

[1-3 párrafos describiendo qué es el sistema, para quién, y qué problema resuelve.
 Esta sección es contexto para los agentes auditores — NO es auditable directamente.]

## Dominios

<!--
Listar los dominios funcionales del sistema. Cada dominio agrupa capacidades
relacionadas. Los IDs de capacidad usan el dominio como prefijo.
-->

- **[DOM1]** — [Nombre del dominio] — [Descripción en 1 línea]
- **[DOM2]** — [Nombre del dominio] — [Descripción en 1 línea]

---

## Capacidades

### [DOM1] — [Nombre del dominio]

| ID | Capacidad | Criterio verificable | Prioridad |
|----|-----------|---------------------|-----------|
| DOM1-01 | [Qué puede hacer un usuario/sistema] | [Cómo verificar que está implementado] | [Alta/Media/Baja] |
| DOM1-02 | [Capacidad] | [Criterio] | [Prioridad] |

### [DOM2] — [Nombre del dominio]

| ID | Capacidad | Criterio verificable | Prioridad |
|----|-----------|---------------------|-----------|
| DOM2-01 | [Capacidad] | [Criterio] | [Prioridad] |
| DOM2-02 | [Capacidad] | [Criterio] | [Prioridad] |

<!--
Repetir para cada dominio.

PRIORIDAD:
- Alta: sin esto el sistema no cumple su propósito básico
- Media: funcionalidad esperada pero no bloqueante
- Baja: nice-to-have, puede diferirse

El loop recursivo audita primero las de prioridad Alta,
luego Media, luego Baja. El threshold de "diminishing returns"
se evalúa por prioridad: si solo quedan gaps de prioridad Baja
y el threshold está activo, el loop para.
-->

---

## Restricciones transversales

<!--
Reglas que aplican a TODAS las capacidades. Son auditables:
el auditor verifica que ninguna implementación las viole.
-->

| ID | Restricción | Cómo verificar violación |
|----|-------------|------------------------|
| TX-01 | [Restricción transversal] | [Qué buscar en el código] |
| TX-02 | [Restricción transversal] | [Qué buscar] |

---

## Parámetros del loop recursivo

<!--
Configuración para el comando /recursive-audit.
El usuario ajusta estos valores según su proyecto.
-->

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| max_iterations | 3 | Máximo de ciclos audit→implement |
| coverage_threshold | 90% | % de capacidades cubiertas para considerar FIN |
| diminishing_returns | 2 | Si un ciclo cierra < N gaps → FIN |
| priority_cutoff | Media | Auditar capacidades hasta esta prioridad (Alta, Media, Baja) |
| audit_split | single | Cuántos auditores: "single" o "by_domain" (2 auditores paralelos) |
