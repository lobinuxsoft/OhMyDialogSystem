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
    set "STATUS_CLASS=bg-ai-green"
) else if %PERCENT_INT% LSS 80 (
    set "STATUS_CLASS=bg-warning"
) else (
    set "STATUS_CLASS=bg-error"
)

:: Generate HTML with Tailwind
(
echo ^<!DOCTYPE html^>
echo ^<html lang="es"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>Token Report - Claude Config^</title^>
echo.
echo     ^<!-- Tailwind CSS Play CDN --^>
echo     ^<script src="https://cdn.tailwindcss.com"^>^</script^>
echo     ^<script src="../tailwind.config.js"^>^</script^>
echo.
echo     ^<!-- Google Fonts --^>
echo     ^<link rel="preconnect" href="https://fonts.googleapis.com"^>
echo     ^<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin^>
echo     ^<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700^&family=JetBrains+Mono:wght@400;500^&display=swap" rel="stylesheet"^>
echo.
echo     ^<!-- Base styles --^>
echo     ^<link rel="stylesheet" href="../base.css"^>
echo.
echo     ^<style^>
echo         body {
echo             font-family: 'Inter', system-ui, sans-serif;
echo             background-color: #0a0d12;
echo             color: #e6edf3;
echo         }
echo     ^</style^>
echo ^</head^>
echo ^<body class="min-h-screen p-8"^>
echo     ^<div class="max-w-4xl mx-auto"^>
echo         ^<!-- Header --^>
echo         ^<div class="mb-8"^>
echo             ^<h1 class="text-3xl font-bold mb-2"^>
echo                 ^<span class="text-gradient-cyan-purple"^>Reporte de Tokens^</span^>
echo             ^</h1^>
echo             ^<p class="text-gray-400"^>Consumo de contexto de configuración Claude (^<code class="text-ai-cyan"^>.claude/^</code^>)^</p^>
echo         ^</div^>
echo.
echo         ^<!-- Summary Card --^>
echo         ^<div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6"^>
echo             ^<h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2"^>
echo                 ^<span^>⚡^</span^> Resumen de Consumo
echo             ^</h2^>
echo.
echo             ^<!-- Progress Bar --^>
echo             ^<div class="bg-bg-tertiary rounded-lg h-8 overflow-hidden relative mb-2"^>
echo                 ^<div class="!STATUS_CLASS! h-full rounded-lg transition-all duration-500" style="width: !PERCENT_INT!%%"^>^</div^>
echo                 ^<span class="absolute inset-0 flex items-center justify-center text-sm font-semibold"^>!PERCENT_INT!%% usado^</span^>
echo             ^</div^>
echo.
echo             ^<!-- Zone Indicators --^>
echo             ^<div class="flex justify-between text-xs mb-6"^>
echo                 ^<span class="px-2 py-1 rounded bg-ai-green/20 text-ai-green"^>0-60%% Seguro^</span^>
echo                 ^<span class="px-2 py-1 rounded bg-warning/20 text-warning"^>60-80%% Precaución^</span^>
echo                 ^<span class="px-2 py-1 rounded bg-error/20 text-error"^>^>80%% Riesgo^</span^>
echo             ^</div^>
echo.
echo             ^<!-- Stats Grid --^>
echo             ^<div class="grid grid-cols-2 md:grid-cols-4 gap-4"^>
echo                 ^<div class="bg-bg-tertiary rounded-lg p-4 text-center"^>
echo                     ^<div class="text-2xl font-bold text-ai-purple"^>!TOTAL_TOKENS!^</div^>
echo                     ^<div class="text-xs text-gray-400 mt-1"^>Tokens Reglas^</div^>
echo                 ^</div^>
echo                 ^<div class="bg-bg-tertiary rounded-lg p-4 text-center"^>
echo                     ^<div class="text-2xl font-bold text-ai-cyan"^>~!SYSTEM_OVERHEAD!^</div^>
echo                     ^<div class="text-xs text-gray-400 mt-1"^>Sistema Base^</div^>
echo                 ^</div^>
echo                 ^<div class="bg-bg-tertiary rounded-lg p-4 text-center"^>
echo                     ^<div class="text-2xl font-bold text-ai-green"^>~!AVAILABLE!^</div^>
echo                     ^<div class="text-xs text-gray-400 mt-1"^>Disponible^</div^>
echo                 ^</div^>
echo                 ^<div class="bg-bg-tertiary rounded-lg p-4 text-center"^>
echo                     ^<div class="text-2xl font-bold text-ai-orange"^>200K^</div^>
echo                     ^<div class="text-xs text-gray-400 mt-1"^>Límite Contexto^</div^>
echo                 ^</div^>
echo             ^</div^>
echo         ^</div^>
echo.
echo         ^<!-- Files Table --^>
echo         ^<div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6"^>
echo             ^<h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2"^>
echo                 ^<span^>📁^</span^> Desglose por Archivo
echo             ^</h2^>
echo.
echo             ^<div class="overflow-x-auto"^>
echo                 ^<table class="w-full"^>
echo                     ^<thead^>
echo                         ^<tr class="text-left text-sm text-gray-400 border-b border-border-default"^>
echo                             ^<th class="pb-3"^>Archivo^</th^>
echo                             ^<th class="pb-3 text-right"^>Caracteres^</th^>
echo                             ^<th class="pb-3 text-right"^>Tokens (est.^)^</th^>
echo                         ^</tr^>
echo                     ^</thead^>
echo                     ^<tbody class="text-sm"^>
) > "%OUTPUT_FILE%"

:: Add file rows from temp data
if exist "%TEMP_DATA%" (
    for /f "tokens=1-3 delims=|" %%a in (%TEMP_DATA%) do (
        echo                         ^<tr class="border-b border-border-default/50"^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 font-mono text-ai-cyan"^>%%a^</td^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 text-right text-gray-400"^>%%b^</td^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 text-right text-ai-purple"^>%%c^</td^>>> "%OUTPUT_FILE%"
        echo                         ^</tr^>>> "%OUTPUT_FILE%"
    )
    del "%TEMP_DATA%"
)

:: Close HTML
(
echo                     ^</tbody^>
echo                 ^</table^>
echo             ^</div^>
echo.
echo             ^<!-- Note --^>
echo             ^<div class="mt-4 p-4 bg-ai-cyan/5 border-l-2 border-ai-cyan rounded-r-lg text-sm text-gray-300"^>
echo                 ^<strong class="text-ai-cyan"^>Nota:^</strong^> Estimación basada en ~4 caracteres por token.
echo                 Los tokens reales pueden variar según el tokenizer de Claude.
echo                 Los skills (^<code class="text-ai-purple"^>.claude/skills/^</code^>) solo se cargan bajo demanda.
echo             ^</div^>
echo         ^</div^>
echo.
echo         ^<!-- Timestamp --^>
echo         ^<div class="text-center text-sm text-gray-500 pt-4 border-t border-border-default"^>
echo             Generado: %FULL_TIMESTAMP%
echo         ^</div^>
echo.
echo         ^<!-- Back Link --^>
echo         ^<div class="text-center mt-4"^>
echo             ^<a href="../home.html" class="text-ai-cyan hover:text-ai-purple transition-colors text-sm"^>
echo                 ← Volver a la documentación
echo             ^</a^>
echo         ^</div^>
echo     ^</div^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT_FILE%"

echo ✓ Token report generated: %OUTPUT_FILE%
endlocal
