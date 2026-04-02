# Templates de hooks para Claude Code

<!--
Los hooks se instalan en .claude/settings.json del proyecto.
Se ejecutan automáticamente en eventos del ciclo de vida del agente.

TAXONOMÍA DE HOOKS (4 tipos):
| Tipo    | Latencia    | Determinismo | Usar para                          |
|---------|-------------|--------------|-------------------------------------|
| command | 50-100ms    | Alto         | Guards destructivos, validación rápida |
| prompt  | ~tokens     | Medio        | Juicio semántico, anti-racionalización |
| agent   | Round-trip  | Alto         | Validación multi-paso, alta criticidad |
| http    | Red         | Variable     | Orquestación externa, audit trail    |

EXIT CODES (aplica a hooks tipo command):
- 0 = Aprobado, continuar ejecución
- 1 = Warning, continuar pero informar al agente
- 2 = Hard block, cancelar la acción irrevocablemente

EVENTOS DEL CICLO DE VIDA:
- PreToolUse  — antes de ejecutar una herramienta (prevención)
- PostToolUse — después de ejecutar (validación de resultado)
- Stop        — antes de terminar respuesta (anti-racionalización)
- SessionStart — al iniciar sesión (recovery/inicialización)

JERARQUÍA DE CAPAS DE PROTECCIÓN:
Los hooks son capa SECUNDARIA de apoyo. El núcleo del harness son los
gates del orquestador. La jerarquía de confianza es:

CAPA PRIMARIA (gates duros del orquestador — siempre activos):
  1. Preflight (Paso 3.5)    — valida specs antes de ejecutar
  2. Scope fence + diff audit (Regla 2b) — bloquea archivos prohibidos
  3. Tests (Regla 2)          — verifica implementación correcta
  4. Completitud (Regla 2c)   — verifica criterios de aceptación
  5. Ledger (.ai/runs/results.tsv) — registra todo para aprendizaje

CAPA SECUNDARIA (hooks — apoyo, pueden no estar instalados):
  1. PreToolUse guard         — previene comandos destructivos
  2. Stop anti-racionalización — detecta victoria prematura

Los hooks COMPLEMENTAN al orquestador, no lo reemplazan.
El sistema debe funcionar correctamente sin hooks instalados.
Si un hook no está instalado, el orquestador compensa:
  - Sin guard destructivo → las reglas de scope igual bloquean
  - Sin anti-racionalización → Regla 2c detecta incomplete

No invertir más esfuerzo en hooks que en los gates primarios.
-->

---

## Hook 1: Guard de comandos destructivos (PreToolUse)

Bloquea comandos que pueden destruir estado irrecuperablemente.
Tipo `command` para máxima velocidad (~50ms) y determinismo.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c \"CMD=$(cat | jq -r '.command // empty'); case \\\"$CMD\\\" in *'rm -rf /'*|*'rm -rf ~'*|*'git push --force'*|*'git push -f '*|*'git clean -fd'*) echo 'BLOCKED: comando destructivo detectado' >&2; exit 2;; *) exit 0;; esac\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

<!--
NOTA IMPORTANTE sobre `git reset --hard`:
NO bloquear `git reset --hard` porque el orquestador lo usa
intencionalmente en la Regla 2 (rollback de tickets fallidos).
Solo bloquear los comandos que NUNCA son seguros en contexto autónomo.

Para proyectos que quieran ser más restrictivos, agregar más
patrones al case statement. Ejemplos adicionales:
- *"DROP TABLE"*|*"DROP DATABASE"*  → SQL destructivo
- *"kubectl delete"*                → Kubernetes destructivo
- *"docker system prune"*           → Docker destructivo
-->

### Cuándo instalarlo
- Instalar ANTES del primer sprint
- Es el hook con menor costo (command = 50ms) y mayor beneficio
- Complementa a la Regla 2 del orquestador que usa `git reset --hard`
  de forma controlada — este guard protege contra usos accidentales

---

## Hook 2: Anti-racionalización (Stop)

Detecta cuando Claude declara victoria con trabajo incompleto.
Tipo `prompt` porque requiere juicio semántico.

### Versión básica

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Sos un verificador de calidad. Revisá la respuesta de Claude y determiná si el trabajo está realmente completo.\n\nBuscá señales de racionalización:\n- Frases como 'pre-existing issue', 'out of scope', 'should work', 'minor issue'\n- Declarar victoria sin mostrar que los tests pasaron\n- Decir 'listo' sin haber tocado todos los archivos del spec\n- Mencionar TODO o FIXME como aceptable\n- Sugerir que el usuario revise manualmente algo que debería estar automatizado\n\nSi detectás racionalización o trabajo incompleto:\n{\"decision\": \"block\", \"reason\": \"[explicación específica de qué falta]\"}\n\nSi el trabajo parece genuinamente completo:\n{\"decision\": \"approve\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Versión extendida (verifica tests y criterios de aceptación)

Para proyectos con specs estructurados como los de code-orchestrator:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Sos un verificador de calidad para el proyecto.\n\nRevisá la respuesta de Claude considerando:\n\n1. RACIONALIZACIÓN: ¿Está declarando victoria prematura? Buscá frases como 'pre-existing issue', 'out of scope', 'should work', 'minor issue', 'mostly done'.\n\n2. TESTS: Si Claude dijo que corrió tests, ¿el output muestra que pasaron? Si no corrió tests y el spec los requiere, eso es trabajo incompleto.\n\n3. COMMITS: Si el spec pide commit atómico, ¿se hizo? ¿El mensaje sigue el formato del spec?\n\n4. ARCHIVOS: Si el spec lista archivos a modificar, ¿se tocaron todos?\n\nResponde SOLO con JSON:\n- Si todo está bien: {\"decision\": \"approve\"}\n- Si algo falta: {\"decision\": \"block\", \"reason\": \"[qué falta específicamente]\"}\n\nSé estricto. Es mejor bloquear y pedir que termine que dejar pasar trabajo incompleto.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## Combinación recomendada (ambos hooks juntos)

Para instalar ambos hooks en un solo settings.json:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c \"CMD=$(cat | jq -r '.command // empty'); case \\\"$CMD\\\" in *'rm -rf /'*|*'rm -rf ~'*|*'git push --force'*|*'git push -f '*|*'git clean -fd'*) echo 'BLOCKED: comando destructivo detectado' >&2; exit 2;; *) exit 0;; esac\"",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Sos un verificador de calidad. Revisá si el trabajo está realmente completo. Buscá señales de racionalización: 'pre-existing issue', 'out of scope', 'should work', 'minor issue', 'mostly done'. Si detectás trabajo incompleto: {\"decision\": \"block\", \"reason\": \"[qué falta]\"}. Si está completo: {\"decision\": \"approve\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## Notas de implementación

### Estrategia de instalación progresiva
1. **Sprint 1**: Instalar guard destructivo (PreToolUse) — costo mínimo, protección máxima
2. **Si /learn detecta victoria prematura**: Agregar anti-racionalización (Stop)
3. **Para proyectos críticos**: Instalar ambos desde el inicio

### Ajustes por proyecto
- El timeout de 30s para Stop es conservador; el modelo verificador es rápido
- El timeout de 5s para el guard es más que suficiente (tarda ~50ms)
- El matcher vacío "" en Stop aplica a TODAS las respuestas
  - Para aplicar solo durante implementación, usar matcher con
    palabras clave (ej: "spec", "ticket", "implement")
- Si el hook Stop bloquea demasiado, suavizar removiendo "mostly done"

### Limitaciones
- El hook Stop ve la respuesta pero NO el estado real del repo
- El guard PreToolUse ve el comando pero no su intención
- Ningún hook puede ejecutar tests por sí solo
- Complementar con la Regla 2 del orquestador (.ai/rules.md)
  que sí corre tests después de cada subagente
- La resiliencia viene de las 3 capas juntas, no de una sola
