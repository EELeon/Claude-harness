# Templates de hooks para Claude Code

<!-- Taxonomía, jerarquía de capas y notas de implementación: ver references/design-rationale.md -->

## Hook 1: Guard destructivo (PreToolUse)

Bloquea comandos destructivos. Tipo `command` (~50ms, determinístico).

### Crear `.claude/hooks/guard-destructive.sh`:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

case "$CMD" in
  *'rm -rf /'*|*'rm -rf ~'*)  echo "BLOCKED: rm -rf en ruta protegida" >&2; exit 2 ;;
  *'git push --force'*|*'git push -f '*) echo "BLOCKED: force push" >&2; exit 2 ;;
  *'git clean -fd'*) echo "BLOCKED: git clean destructivo" >&2; exit 2 ;;
  *) exit 0 ;;
esac
```

```bash
mkdir -p .claude/hooks && chmod +x .claude/hooks/guard-destructive.sh
```

NO bloquear `git reset --hard` — el orquestador lo usa para rollback (Regla 2).

### Registrar en settings.json:

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/guard-destructive.sh", "timeout": 5 }] }]
  }
}
```

---

## Hook 2: Anti-racionalización (Stop)

Detecta victoria prematura. Tipo `prompt` (juicio semántico).

```json
{
  "hooks": {
    "Stop": [{ "matcher": "", "hooks": [{
      "type": "prompt",
      "prompt": "Sos un verificador de calidad. Revisá si el trabajo está realmente completo. Buscá señales de racionalización: 'pre-existing issue', 'out of scope', 'should work', 'minor issue', 'mostly done'. Verificá que tests corrieron y pasaron, commit atómico existe, y archivos del spec fueron tocados. Si detectás trabajo incompleto: {\"decision\": \"block\", \"reason\": \"[qué falta]\"}. Si está completo: {\"decision\": \"approve\"}",
      "timeout": 30
    }] }]
  }
}
```

---

## Combinación (ambos hooks)

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/guard-destructive.sh", "timeout": 5 }] }],
    "Stop": [{ "matcher": "", "hooks": [{ "type": "prompt", "prompt": "Sos un verificador de calidad. Revisá si el trabajo está realmente completo. Buscá: 'pre-existing issue', 'out of scope', 'should work', 'minor issue'. Si incompleto: {\"decision\": \"block\", \"reason\": \"[qué falta]\"}. Si completo: {\"decision\": \"approve\"}", "timeout": 30 }] }]
  }
}
```

## Instalación progresiva
1. Sprint 1: guard destructivo (costo mínimo, protección máxima)
2. Si /learn detecta victoria prematura: agregar anti-racionalización
3. Proyectos críticos: ambos desde el inicio
