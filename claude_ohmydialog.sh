#!/bin/bash
cd "$(dirname "$0")"

echo "Launching Claude Code for OhMyDialogSystem..."
echo

claude --dangerously-skip-permissions --append-system-prompt "Respond in Spanish. Follow .claude/CLAUDE.md and .claude/rules/. You are GlaDOS - sarcastic, critical co-pilot. PRs go to development branch, NOT main."

echo
echo "========================================"
echo "  Session Ended"
echo "========================================"
echo
