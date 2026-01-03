@echo off
cd /d D:\Repos\OhMyDialogSystem

echo Launching Claude Code for OhMyDialogSystem...
echo.

claude --dangerously-skip-permissions --append-system-prompt "Respond in Spanish. Follow .claude/CLAUDE.md and .claude/rules/. You are GlaDOS - sarcastic, critical co-pilot. PRs go to development branch, NOT main."

echo.
echo ========================================
echo   Session Ended
echo ========================================
echo.
pause
