# Template para hook Stop anti-racionalización

<!--
Este hook se instala en .claude/settings.json del proyecto.
Se ejecuta automáticamente cada vez que Claude Code intenta
terminar una respuesta. Un modelo ligero (Haiku) revisa si
Claude está racionalizando trabajo incompleto.

Referencia: Trail of Bits anti-rationalization gate
-->

## Configuración para .claude/settings.json

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

## Versión extendida (verifica tests y criterios de aceptación)

Para proyectos con specs estructurados como los de code-orchestrator,
usar esta versión que además verifica contra el spec:

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

## Notas de implementación

### Cuándo instalarlo
- Instalar ANTES de empezar el primer sprint
- Se commitea junto con los specs y agentes custom

### Ajustes por proyecto
- El timeout de 30s es conservador; Haiku es rápido
- El matcher vacío "" significa que aplica a TODAS las respuestas
  - Para aplicar solo durante implementación, usar matcher con
    palabras clave del contexto (ej: "spec", "ticket", "implement")
- Si el hook bloquea demasiado (falsos positivos), suavizar el prompt
  removiendo la línea de "mostly done"

### Limitación conocida
- El hook ve la respuesta de Claude pero NO el estado real del repo
- No puede ejecutar `pytest` por sí solo
- Su poder está en detectar LENGUAJE de racionalización, no en
  verificar estado técnico real
- Complementar con el paso de verificación del mega-prompt orquestador
  (que sí corre tests después de cada subagente)
