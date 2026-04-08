#!/usr/bin/env bash
# Guard de comandos destructivos para Claude Code
# Se ejecuta como PreToolUse hook antes de cada llamada a Bash.
# Exit 0 = OK, Exit 2 = BLOCK

# Leer el JSON del tool input desde stdin
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Si no hay comando, dejar pasar
if [ -z "$CMD" ]; then
  exit 0
fi

# Patrones destructivos a bloquear
case "$CMD" in
  *'rm -rf /'*|*'rm -rf ~'*)
    echo "BLOCKED: rm -rf en ruta protegida" >&2
    exit 2
    ;;
  *'git push --force'*|*'git push -f '*)
    echo "BLOCKED: force push" >&2
    exit 2
    ;;
  *'git clean -fd'*)
    echo "BLOCKED: git clean destructivo" >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
