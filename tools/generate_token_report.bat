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

:: Create temp files
set "TEMP_DATA=%TEMP%\token_report_data.tmp"
set "TEMP_CONTENT=%TEMP%\token_report_content"
if exist "%TEMP_DATA%" del "%TEMP_DATA%"
if exist "%TEMP_CONTENT%_*" del "%TEMP_CONTENT%_*"

:: Process all .md files in .claude/
for /r "%CLAUDE_DIR%" %%F in (*.md) do (
    set "filepath=%%F"
    set "relpath=!filepath:%CLAUDE_DIR%\=!"
    set "safeid=!relpath!"
    set "safeid=!safeid:\=_!"
    set "safeid=!safeid:/=_!"
    set "safeid=!safeid:.=_!"

    :: Get file size (characters)
    for %%A in ("%%F") do set "chars=%%~zA"

    :: Estimate tokens (chars / 4)
    set /a "tokens=!chars! / 4"
    set /a "TOTAL_CHARS+=!chars!"
    set /a "FILE_COUNT+=1"

    :: Save to temp
    echo !relpath!^|!chars!^|!tokens!^|!safeid!>> "%TEMP_DATA%"

    :: Copy file content for lightbox (escape HTML later in powershell)
    copy "%%F" "%TEMP_CONTENT%_!safeid!.txt" >nul 2>&1
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

:: Get last commit info
cd /d "%ROOT_DIR%"
for /f "tokens=*" %%i in ('git log -1 --format^="%%h" -- .claude/ 2^>nul') do set "LAST_COMMIT_HASH=%%i"
for /f "tokens=*" %%i in ('git log -1 --format^="%%s" -- .claude/ 2^>nul') do set "LAST_COMMIT_MSG=%%i"
for /f "tokens=*" %%i in ('git log -1 --format^="%%an" -- .claude/ 2^>nul') do set "LAST_COMMIT_AUTHOR=%%i"
for /f "tokens=1" %%i in ('git log -1 --format^="%%ci" -- .claude/ 2^>nul') do set "LAST_COMMIT_DATE=%%i"

if not defined LAST_COMMIT_HASH set "LAST_COMMIT_HASH=N/A"
if not defined LAST_COMMIT_MSG set "LAST_COMMIT_MSG=N/A"
if not defined LAST_COMMIT_AUTHOR set "LAST_COMMIT_AUTHOR=N/A"
if not defined LAST_COMMIT_DATE set "LAST_COMMIT_DATE=N/A"

:: Detect conventional commit
set "VIA_CLAUDE=No"
set "VIA_CLAUDE_CLASS=text-gray-400"
echo %LAST_COMMIT_MSG% | findstr /r "^feat( ^fix( ^docs( ^refactor( ^chore(" >nul 2>&1
if not errorlevel 1 (
    set "VIA_CLAUDE=Si (Conventional Commit)"
    set "VIA_CLAUDE_CLASS=text-ai-green"
)

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
echo         .lightbox {
echo             display: none;
echo             position: fixed;
echo             inset: 0;
echo             z-index: 100;
echo             background: rgba(0, 0, 0, 0.85^);
echo             backdrop-filter: blur(4px^);
echo         }
echo         .lightbox.active {
echo             display: flex;
echo             align-items: center;
echo             justify-content: center;
echo         }
echo         .lightbox-content {
echo             background: #0f1419;
echo             border: 1px solid #21262d;
echo             border-radius: 12px;
echo             max-width: 800px;
echo             max-height: 80vh;
echo             width: 90%%;
echo             display: flex;
echo             flex-direction: column;
echo             box-shadow: 0 0 40px rgba(0, 212, 255, 0.2^);
echo         }
echo         .lightbox-header {
echo             padding: 1rem 1.5rem;
echo             border-bottom: 1px solid #21262d;
echo             display: flex;
echo             justify-content: space-between;
echo             align-items: center;
echo         }
echo         .lightbox-body {
echo             padding: 1.5rem;
echo             overflow-y: auto;
echo             flex: 1;
echo         }
echo         .lightbox-body pre {
echo             white-space: pre-wrap;
echo             word-wrap: break-word;
echo             font-family: 'JetBrains Mono', monospace;
echo             font-size: 0.85rem;
echo             line-height: 1.6;
echo             color: #e6edf3;
echo         }
echo         .file-link {
echo             cursor: pointer;
echo             transition: all 0.2s;
echo         }
echo         .file-link:hover {
echo             text-decoration: underline;
echo             filter: brightness(1.2^);
echo         }
echo         .copy-btn { transition: all 0.2s; }
echo         .copy-btn:hover { transform: scale(1.05^); }
echo         .copy-btn.copied { background: #10b981 !important; }
echo     ^</style^>
echo ^</head^>
echo ^<body class="min-h-screen p-8"^>
echo     ^<!-- Lightbox Modal --^>
echo     ^<div id="lightbox" class="lightbox" onclick="if(event.target === this^) closeLightbox(^)"^>
echo         ^<div class="lightbox-content"^>
echo             ^<div class="lightbox-header"^>
echo                 ^<h3 id="lightbox-title" class="text-lg font-semibold text-ai-cyan font-mono"^>^</h3^>
echo                 ^<div class="flex gap-2"^>
echo                     ^<button onclick="copyContent(^)" id="copy-btn" class="copy-btn px-3 py-1.5 text-sm bg-ai-purple hover:bg-ai-purple-dim rounded-lg flex items-center gap-2"^>
echo                         ^<span id="copy-icon"^>📋^</span^>
echo                         ^<span id="copy-text"^>Copiar^</span^>
echo                     ^</button^>
echo                     ^<button onclick="closeLightbox(^)" class="px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 rounded-lg"^>✕ Cerrar^</button^>
echo                 ^</div^>
echo             ^</div^>
echo             ^<div class="lightbox-body"^>
echo                 ^<pre id="lightbox-content"^>^</pre^>
echo             ^</div^>
echo         ^</div^>
echo     ^</div^>
echo.
echo     ^<div class="max-w-4xl mx-auto"^>
echo         ^<!-- Header --^>
echo         ^<div class="mb-8"^>
echo             ^<h1 class="text-3xl font-bold mb-2"^>
echo                 ^<span class="text-gradient-cyan-purple"^>Reporte de Tokens^</span^>
echo             ^</h1^>
echo             ^<p class="text-gray-400"^>Consumo de contexto de configuracion Claude (^<code class="text-ai-cyan"^>.claude/^</code^>)^</p^>
echo         ^</div^>
echo.
echo         ^<!-- Summary Card --^>
echo         ^<div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6"^>
echo             ^<h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2"^>
echo                 ^<span^>⚡^</span^> Resumen de Consumo
echo             ^</h2^>
echo             ^<div class="bg-bg-tertiary rounded-lg h-8 overflow-hidden relative mb-2"^>
echo                 ^<div class="!STATUS_CLASS! h-full rounded-lg transition-all duration-500" style="width: !PERCENT_INT!%%"^>^</div^>
echo                 ^<span class="absolute inset-0 flex items-center justify-center text-sm font-semibold"^>!PERCENT_INT!%% usado^</span^>
echo             ^</div^>
echo             ^<div class="flex justify-between text-xs mb-6"^>
echo                 ^<span class="px-2 py-1 rounded bg-ai-green/20 text-ai-green"^>0-60%% Seguro^</span^>
echo                 ^<span class="px-2 py-1 rounded bg-warning/20 text-warning"^>60-80%% Precaucion^</span^>
echo                 ^<span class="px-2 py-1 rounded bg-error/20 text-error"^>^>80%% Riesgo^</span^>
echo             ^</div^>
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
echo                     ^<div class="text-xs text-gray-400 mt-1"^>Limite Contexto^</div^>
echo                 ^</div^>
echo             ^</div^>
echo         ^</div^>
echo.
echo         ^<!-- Last Commit Card --^>
echo         ^<div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6"^>
echo             ^<h2 class="text-lg font-semibold text-ai-purple mb-4 flex items-center gap-2"^>
echo                 ^<span^>🔄^</span^> Ultimo Cambio en .claude/
echo             ^</h2^>
echo             ^<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm"^>
echo                 ^<div^>
echo                     ^<span class="text-gray-500"^>Commit:^</span^>
echo                     ^<span class="font-mono text-ai-cyan ml-2"^>!LAST_COMMIT_HASH!^</span^>
echo                 ^</div^>
echo                 ^<div^>
echo                     ^<span class="text-gray-500"^>Fecha:^</span^>
echo                     ^<span class="text-gray-300 ml-2"^>!LAST_COMMIT_DATE!^</span^>
echo                 ^</div^>
echo                 ^<div^>
echo                     ^<span class="text-gray-500"^>Autor:^</span^>
echo                     ^<span class="text-gray-300 ml-2"^>!LAST_COMMIT_AUTHOR!^</span^>
echo                 ^</div^>
echo                 ^<div^>
echo                     ^<span class="text-gray-500"^>Via Claude:^</span^>
echo                     ^<span class="ml-2 !VIA_CLAUDE_CLASS!"^>!VIA_CLAUDE!^</span^>
echo                 ^</div^>
echo             ^</div^>
echo             ^<div class="mt-3 p-3 bg-bg-tertiary rounded-lg"^>
echo                 ^<span class="text-gray-500 text-xs"^>Mensaje:^</span^>
echo                 ^<p class="text-gray-300 font-mono text-sm mt-1"^>!LAST_COMMIT_MSG!^</p^>
echo             ^</div^>
echo         ^</div^>
echo.
echo         ^<!-- Files Table --^>
echo         ^<div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6"^>
echo             ^<h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2"^>
echo                 ^<span^>📁^</span^> Desglose por Archivo
echo                 ^<span class="text-xs text-gray-500 font-normal ml-2"^>(click para ver contenido^)^</span^>
echo             ^</h2^>
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
    for /f "tokens=1-4 delims=|" %%a in (%TEMP_DATA%) do (
        echo                         ^<tr class="border-b border-border-default/50"^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 font-mono text-ai-cyan file-link" onclick="openLightbox('%%a', '%%d'^)"^>%%a^</td^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 text-right text-gray-400"^>%%b^</td^>>> "%OUTPUT_FILE%"
        echo                             ^<td class="py-3 text-right text-ai-purple"^>%%c^</td^>>> "%OUTPUT_FILE%"
        echo                         ^</tr^>>> "%OUTPUT_FILE%"
    )
)

:: Close table and add note
(
echo                     ^</tbody^>
echo                 ^</table^>
echo             ^</div^>
echo             ^<div class="mt-4 p-4 bg-ai-cyan/5 border-l-2 border-ai-cyan rounded-r-lg text-sm text-gray-300"^>
echo                 ^<strong class="text-ai-cyan"^>Nota:^</strong^> Estimacion basada en ~4 caracteres por token.
echo                 Los tokens reales pueden variar segun el tokenizer de Claude.
echo                 Los skills (^<code class="text-ai-purple"^>.claude/skills/^</code^>) solo se cargan bajo demanda.
echo             ^</div^>
echo         ^</div^>
echo.
echo         ^<!-- Hidden file contents for lightbox --^>
echo         ^<div id="file-contents" style="display:none;"^>
) >> "%OUTPUT_FILE%"

:: Add file contents (escaped)
if exist "%TEMP_DATA%" (
    for /f "tokens=1-4 delims=|" %%a in (%TEMP_DATA%) do (
        echo             ^<div id="content-%%d"^>>> "%OUTPUT_FILE%"
        if exist "%TEMP_CONTENT%_%%d.txt" (
            :: Use PowerShell to escape HTML entities
            powershell -Command "(Get-Content -Raw '%TEMP_CONTENT%_%%d.txt') -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '\"','&quot;'" >> "%OUTPUT_FILE%"
            del "%TEMP_CONTENT%_%%d.txt"
        )
        echo ^</div^>>> "%OUTPUT_FILE%"
    )
    del "%TEMP_DATA%"
)

:: Close HTML and add scripts
(
echo         ^</div^>
echo.
echo         ^<!-- Timestamp --^>
echo         ^<div class="text-center text-sm text-gray-500 pt-4 border-t border-border-default"^>
echo             Generado: %FULL_TIMESTAMP%
echo         ^</div^>
echo.
echo         ^<!-- Back Link --^>
echo         ^<div class="text-center mt-4"^>
echo             ^<a href="index.html" class="text-ai-cyan hover:text-ai-purple transition-colors text-sm"^>
echo                 ← Volver a Technical
echo             ^</a^>
echo         ^</div^>
echo     ^</div^>
echo.
echo     ^<script^>
echo         let currentContent = '';
echo.
echo         function openLightbox(filename, safeId^) {
echo             const content = document.getElementById('content-' + safeId^).innerHTML;
echo             currentContent = content.replace(/^&lt;/g, '^<'^).replace(/^&gt;/g, '^>'^).replace(/^&amp;/g, '^&'^).replace(/^&quot;/g, '"'^);
echo.
echo             document.getElementById('lightbox-title'^).textContent = filename;
echo             document.getElementById('lightbox-content'^).innerHTML = content;
echo             document.getElementById('lightbox'^).classList.add('active'^);
echo             document.body.style.overflow = 'hidden';
echo             resetCopyBtn(^);
echo         }
echo.
echo         function closeLightbox(^) {
echo             document.getElementById('lightbox'^).classList.remove('active'^);
echo             document.body.style.overflow = '';
echo         }
echo.
echo         function copyContent(^) {
echo             navigator.clipboard.writeText(currentContent^).then((^) =^> {
echo                 const btn = document.getElementById('copy-btn'^);
echo                 const icon = document.getElementById('copy-icon'^);
echo                 const text = document.getElementById('copy-text'^);
echo                 btn.classList.add('copied'^);
echo                 icon.textContent = '✓';
echo                 text.textContent = 'Copiado!';
echo                 setTimeout(resetCopyBtn, 2000^);
echo             }^);
echo         }
echo.
echo         function resetCopyBtn(^) {
echo             const btn = document.getElementById('copy-btn'^);
echo             const icon = document.getElementById('copy-icon'^);
echo             const text = document.getElementById('copy-text'^);
echo             btn.classList.remove('copied'^);
echo             icon.textContent = '📋';
echo             text.textContent = 'Copiar';
echo         }
echo.
echo         document.addEventListener('keydown', (e^) =^> {
echo             if (e.key === 'Escape'^) closeLightbox(^);
echo         }^);
echo     ^</script^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT_FILE%"

echo ✓ Token report generated: %OUTPUT_FILE%
endlocal
