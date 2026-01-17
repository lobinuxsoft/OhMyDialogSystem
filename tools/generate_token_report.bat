@echo off
setlocal enabledelayedexpansion
:: Generate Token Report - Creates HTML report of .claude/ token consumption
:: Output: docs\Technical\token-report.html

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "CLAUDE_DIR=%ROOT_DIR%\.claude"
set "OUTPUT_FILE=%ROOT_DIR%\docs\Technical\token-report.html"

:: Initialize counters
set "TOTAL_CHARS=0"
set "FILE_COUNT=0"
set "CONTEXT_LIMIT=200000"
set "SYSTEM_OVERHEAD=14000"

:: Create temp file for file data
set "TEMP_DATA=%TEMP%\token_report_data.tmp"
if exist "%TEMP_DATA%" del "%TEMP_DATA%"

:: Process all .md files in .claude/
for /r "%CLAUDE_DIR%" %%F in (*.md) do (
    set "filepath=%%F"
    set "relpath=!filepath:%CLAUDE_DIR%\=!"

    :: Get file size (characters)
    for %%A in ("%%F") do set "chars=%%~zA"

    :: Estimate tokens (chars / 4)
    set /a "tokens=!chars! / 4"
    set /a "TOTAL_CHARS+=!chars!"
    set /a "FILE_COUNT+=1"

    :: Save to temp
    echo !relpath!^|!chars!^|!tokens!>> "%TEMP_DATA%"
)

:: Calculate totals
set /a "TOTAL_TOKENS=%TOTAL_CHARS% / 4"
set /a "TOTAL_USED=%SYSTEM_OVERHEAD% + %TOTAL_TOKENS%"
set /a "AVAILABLE=%CONTEXT_LIMIT% - %TOTAL_USED%"
set /a "PERCENT_INT=%TOTAL_USED% * 100 / %CONTEXT_LIMIT%"

:: Get timestamp
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "DATESTAMP=%%c-%%b-%%a"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "TIMESTAMP=%%a:%%b"
set "FULL_TIMESTAMP=%DATESTAMP% %TIMESTAMP%"

:: Determine progress bar class
if %PERCENT_INT% LSS 60 (
    set "PROGRESS_CLASS=progress-safe"
) else if %PERCENT_INT% LSS 80 (
    set "PROGRESS_CLASS=progress-warn"
) else (
    set "PROGRESS_CLASS=progress-danger"
)

:: Generate HTML
(
echo ^<!DOCTYPE html^>
echo ^<html lang="es"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>Token Report - Claude Config^</title^>
echo     ^<style^>
echo         :root {
echo             --bg-primary: #0a0d12;
echo             --bg-secondary: #0f1419;
echo             --bg-tertiary: #161b22;
echo             --border: #21262d;
echo             --text-primary: #e6edf3;
echo             --text-secondary: #8b949e;
echo             --start: #10b981;
echo             --end: #ef4444;
echo             --ai: #3b82f6;
echo             --static: #6b7280;
echo             --choice: #eab308;
echo             --cond: #f97316;
echo             --event: #a855f7;
echo             --var: #06b6d4;
echo         }
echo         * { box-sizing: border-box; margin: 0; padding: 0; }
echo         body {
echo             font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
echo             background: var(--bg-primary^);
echo             color: var(--text-primary^);
echo             min-height: 100vh;
echo             padding: 2rem;
echo         }
echo         .container { max-width: 900px; margin: 0 auto; }
echo         h1 {
echo             font-size: 2rem;
echo             margin-bottom: 0.5rem;
echo             background: linear-gradient(135deg, var(--var^), var(--event^)^);
echo             -webkit-background-clip: text;
echo             -webkit-text-fill-color: transparent;
echo             background-clip: text;
echo         }
echo         .subtitle { color: var(--text-secondary^); margin-bottom: 2rem; font-size: 0.9rem; }
echo         .card {
echo             background: var(--bg-secondary^);
echo             border: 1px solid var(--border^);
echo             border-radius: 12px;
echo             padding: 1.5rem;
echo             margin-bottom: 1.5rem;
echo         }
echo         .card-title {
echo             font-size: 1.1rem;
echo             color: var(--var^);
echo             margin-bottom: 1rem;
echo             display: flex;
echo             align-items: center;
echo             gap: 0.5rem;
echo         }
echo         .progress-container {
echo             background: var(--bg-tertiary^);
echo             border-radius: 8px;
echo             height: 32px;
echo             overflow: hidden;
echo             position: relative;
echo             margin: 1rem 0;
echo         }
echo         .progress-bar { height: 100%%; border-radius: 8px; transition: width 0.5s ease; }
echo         .progress-safe { background: linear-gradient(90deg, var(--start^), var(--ai^)^); }
echo         .progress-warn { background: linear-gradient(90deg, var(--choice^), var(--cond^)^); }
echo         .progress-danger { background: linear-gradient(90deg, var(--cond^), var(--end^)^); }
echo         .progress-label {
echo             position: absolute;
echo             top: 50%%;
echo             left: 50%%;
echo             transform: translate(-50%%, -50%%^);
echo             font-weight: 600;
echo             font-size: 0.85rem;
echo             text-shadow: 0 1px 2px rgba(0,0,0,0.8^);
echo         }
echo         .stats-grid {
echo             display: grid;
echo             grid-template-columns: repeat(auto-fit, minmax(180px, 1fr^)^);
echo             gap: 1rem;
echo             margin-top: 1rem;
echo         }
echo         .stat-box {
echo             background: var(--bg-tertiary^);
echo             border-radius: 8px;
echo             padding: 1rem;
echo             text-align: center;
echo         }
echo         .stat-value { font-size: 1.8rem; font-weight: 700; }
echo         .stat-value.tokens { color: var(--event^); }
echo         .stat-value.system { color: var(--ai^); }
echo         .stat-value.available { color: var(--start^); }
echo         .stat-value.percent { color: var(--var^); }
echo         .stat-label { font-size: 0.8rem; color: var(--text-secondary^); margin-top: 0.25rem; }
echo         table { width: 100%%; border-collapse: collapse; margin-top: 1rem; }
echo         th, td { padding: 0.75rem; text-align: left; border-bottom: 1px solid var(--border^); }
echo         th { color: var(--text-secondary^); font-weight: 500; font-size: 0.85rem; }
echo         td.file { color: var(--var^); font-family: monospace; }
echo         td.tokens { color: var(--event^); text-align: right; }
echo         td.chars { color: var(--text-secondary^); text-align: right; }
echo         .zone-indicator { display: flex; justify-content: space-between; margin-top: 0.5rem; font-size: 0.75rem; }
echo         .zone { padding: 0.25rem 0.5rem; border-radius: 4px; }
echo         .zone-safe { background: rgba(16, 185, 129, 0.2^); color: var(--start^); }
echo         .zone-warn { background: rgba(234, 179, 8, 0.2^); color: var(--choice^); }
echo         .zone-danger { background: rgba(239, 68, 68, 0.2^); color: var(--end^); }
echo         .timestamp {
echo             text-align: center;
echo             color: var(--text-secondary^);
echo             font-size: 0.8rem;
echo             margin-top: 2rem;
echo             padding-top: 1rem;
echo             border-top: 1px solid var(--border^);
echo         }
echo         .note {
echo             background: rgba(6, 182, 212, 0.1^);
echo             border-left: 3px solid var(--var^);
echo             padding: 1rem;
echo             margin-top: 1rem;
echo             border-radius: 0 8px 8px 0;
echo             font-size: 0.9rem;
echo         }
echo     ^</style^>
echo ^</head^>
echo ^<body^>
echo     ^<div class="container"^>
echo         ^<h1^>📊 Reporte de Tokens^</h1^>
echo         ^<p class="subtitle"^>Consumo de contexto de configuración Claude (.claude/^)^</p^>
echo         ^<div class="card"^>
echo             ^<div class="card-title"^>⚡ Resumen de Consumo^</div^>
echo             ^<div class="progress-container"^>
echo                 ^<div class="progress-bar !PROGRESS_CLASS!" style="width: !PERCENT_INT!%%"^>^</div^>
echo                 ^<span class="progress-label"^>!PERCENT_INT!%% usado^</span^>
echo             ^</div^>
echo             ^<div class="zone-indicator"^>
echo                 ^<span class="zone zone-safe"^>0-60%% Seguro^</span^>
echo                 ^<span class="zone zone-warn"^>60-80%% Precaución^</span^>
echo                 ^<span class="zone zone-danger"^>^>80%% Riesgo^</span^>
echo             ^</div^>
echo             ^<div class="stats-grid"^>
echo                 ^<div class="stat-box"^>
echo                     ^<div class="stat-value tokens"^>!TOTAL_TOKENS!^</div^>
echo                     ^<div class="stat-label"^>Tokens Reglas^</div^>
echo                 ^</div^>
echo                 ^<div class="stat-box"^>
echo                     ^<div class="stat-value system"^>~!SYSTEM_OVERHEAD!^</div^>
echo                     ^<div class="stat-label"^>Sistema Base^</div^>
echo                 ^</div^>
echo                 ^<div class="stat-box"^>
echo                     ^<div class="stat-value available"^>~!AVAILABLE!^</div^>
echo                     ^<div class="stat-label"^>Disponible^</div^>
echo                 ^</div^>
echo                 ^<div class="stat-box"^>
echo                     ^<div class="stat-value percent"^>200K^</div^>
echo                     ^<div class="stat-label"^>Límite Contexto^</div^>
echo                 ^</div^>
echo             ^</div^>
echo         ^</div^>
echo         ^<div class="card"^>
echo             ^<div class="card-title"^>📁 Desglose por Archivo^</div^>
echo             ^<table^>
echo                 ^<thead^>
echo                     ^<tr^>
echo                         ^<th^>Archivo^</th^>
echo                         ^<th style="text-align:right"^>Caracteres^</th^>
echo                         ^<th style="text-align:right"^>Tokens (est.^)^</th^>
echo                     ^</tr^>
echo                 ^</thead^>
echo                 ^<tbody^>
) > "%OUTPUT_FILE%"

:: Add file rows from temp data
if exist "%TEMP_DATA%" (
    for /f "tokens=1-3 delims=|" %%a in (%TEMP_DATA%) do (
        echo                     ^<tr^>>> "%OUTPUT_FILE%"
        echo                         ^<td class="file"^>%%a^</td^>>> "%OUTPUT_FILE%"
        echo                         ^<td class="chars"^>%%b^</td^>>> "%OUTPUT_FILE%"
        echo                         ^<td class="tokens"^>%%c^</td^>>> "%OUTPUT_FILE%"
        echo                     ^</tr^>>> "%OUTPUT_FILE%"
    )
    del "%TEMP_DATA%"
)

:: Close HTML
(
echo                 ^</tbody^>
echo             ^</table^>
echo             ^<div class="note"^>
echo                 ^<strong^>Nota:^</strong^> Estimación basada en ~4 caracteres por token.
echo                 Los tokens reales pueden variar según el tokenizer de Claude.
echo                 Los skills (.claude/skills/^) solo se cargan bajo demanda.
echo             ^</div^>
echo         ^</div^>
echo         ^<div class="timestamp"^>
echo             Generado: %FULL_TIMESTAMP%
echo         ^</div^>
echo     ^</div^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT_FILE%"

echo ✓ Token report generated: %OUTPUT_FILE%
endlocal
