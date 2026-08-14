#!/bin/bash
# Generate Token Report - Creates HTML report of .claude/ token consumption
# Output: docs/Technical/token-report.html

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$ROOT_DIR/.claude"
OUTPUT_FILE="$ROOT_DIR/docs/Technical/token-report.html"

# Token estimation: ~4 characters per token (conservative)
estimate_tokens() {
    local chars=$1
    echo $((chars / 4))
}

# Count characters in a file
count_chars() {
    wc -c < "$1" | tr -d ' '
}

# Escape HTML entities
escape_html() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' | sed "s/'/\&#39;/g"
}

# Get file list and stats
declare -A FILE_TOKENS
declare -A FILE_CHARS
declare -A FILE_CONTENT
TOTAL_CHARS=0

# Process all files in .claude/
while IFS= read -r -d '' file; do
    rel_path="${file#$CLAUDE_DIR/}"
    chars=$(count_chars "$file")
    tokens=$(estimate_tokens "$chars")
    FILE_TOKENS["$rel_path"]=$tokens
    FILE_CHARS["$rel_path"]=$chars
    FILE_CONTENT["$rel_path"]=$(cat "$file" | escape_html)
    TOTAL_CHARS=$((TOTAL_CHARS + chars))
done < <(find "$CLAUDE_DIR" -type f -name "*.md" -print0)

TOTAL_TOKENS=$(estimate_tokens $TOTAL_CHARS)
CONTEXT_LIMIT=200000
SYSTEM_OVERHEAD=14000
AVAILABLE=$((CONTEXT_LIMIT - SYSTEM_OVERHEAD - TOTAL_TOKENS))
PERCENT_USED=$(awk "BEGIN {printf \"%.2f\", ($SYSTEM_OVERHEAD + $TOTAL_TOKENS) / $CONTEXT_LIMIT * 100}")
PERCENT_INT=$(awk "BEGIN {printf \"%.0f\", ($SYSTEM_OVERHEAD + $TOTAL_TOKENS) / $CONTEXT_LIMIT * 100}")

# Determine status color class
if (( $(echo "$PERCENT_USED < 60" | bc -l) )); then
    STATUS_CLASS="bg-ai-green"
    STATUS_TEXT="Seguro"
elif (( $(echo "$PERCENT_USED < 80" | bc -l) )); then
    STATUS_CLASS="bg-warning"
    STATUS_TEXT="Precaución"
else
    STATUS_CLASS="bg-error"
    STATUS_TEXT="Riesgo"
fi

# Generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Get last commit info for .claude/ files
cd "$ROOT_DIR"
LAST_COMMIT_HASH=$(git log -1 --format="%h" -- .claude/ 2>/dev/null || echo "N/A")
LAST_COMMIT_MSG=$(git log -1 --format="%s" -- .claude/ 2>/dev/null || echo "N/A")
LAST_COMMIT_AUTHOR=$(git log -1 --format="%an" -- .claude/ 2>/dev/null || echo "N/A")
LAST_COMMIT_DATE=$(git log -1 --format="%ci" -- .claude/ 2>/dev/null | cut -d' ' -f1 || echo "N/A")

# Detect if commit was made via Claude (conventional commit pattern)
VIA_CLAUDE="No"
VIA_CLAUDE_CLASS="text-gray-400"
if echo "$LAST_COMMIT_MSG" | grep -qE "^(feat|fix|docs|refactor|chore|style|test|perf|ci|build|revert)\(.+\):"; then
    VIA_CLAUDE="Sí (Conventional Commit)"
    VIA_CLAUDE_CLASS="text-ai-green"
fi

# Generate HTML with Tailwind
cat > "$OUTPUT_FILE" << 'HTMLHEADER'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Token Report - Claude Config</title>

    <!-- Tailwind CSS Play CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="../tailwind.config.js"></script>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">

    <!-- Base styles -->
    <link rel="stylesheet" href="../base.css">

    <style>
        body {
            font-family: 'Inter', system-ui, sans-serif;
            background-color: #0a0d12;
            color: #e6edf3;
        }
        .lightbox {
            display: none;
            position: fixed;
            inset: 0;
            z-index: 100;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(4px);
        }
        .lightbox.active {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .lightbox-content {
            background: #0f1419;
            border: 1px solid #21262d;
            border-radius: 12px;
            max-width: 800px;
            max-height: 80vh;
            width: 90%;
            display: flex;
            flex-direction: column;
            box-shadow: 0 0 40px rgba(0, 212, 255, 0.2);
        }
        .lightbox-header {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid #21262d;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .lightbox-body {
            padding: 1.5rem;
            overflow-y: auto;
            flex: 1;
        }
        .lightbox-body pre {
            white-space: pre-wrap;
            word-wrap: break-word;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.85rem;
            line-height: 1.6;
            color: #e6edf3;
        }
        .file-link {
            cursor: pointer;
            transition: all 0.2s;
        }
        .file-link:hover {
            text-decoration: underline;
            filter: brightness(1.2);
        }
        .copy-btn {
            transition: all 0.2s;
        }
        .copy-btn:hover {
            transform: scale(1.05);
        }
        .copy-btn.copied {
            background: #10b981 !important;
        }
    </style>
</head>
<body class="min-h-screen p-8">
    <!-- Lightbox Modal -->
    <div id="lightbox" class="lightbox" onclick="if(event.target === this) closeLightbox()">
        <div class="lightbox-content">
            <div class="lightbox-header">
                <h3 id="lightbox-title" class="text-lg font-semibold text-ai-cyan font-mono"></h3>
                <div class="flex gap-2">
                    <button onclick="copyContent()" id="copy-btn" class="copy-btn px-3 py-1.5 text-sm bg-ai-purple hover:bg-ai-purple-dim rounded-lg flex items-center gap-2">
                        <span id="copy-icon">📋</span>
                        <span id="copy-text">Copiar</span>
                    </button>
                    <button onclick="closeLightbox()" class="px-3 py-1.5 text-sm bg-gray-700 hover:bg-gray-600 rounded-lg">✕ Cerrar</button>
                </div>
            </div>
            <div class="lightbox-body">
                <pre id="lightbox-content"></pre>
            </div>
        </div>
    </div>

    <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="mb-8">
            <h1 class="text-3xl font-bold mb-2">
                <span class="text-gradient-cyan-purple">Reporte de Tokens</span>
            </h1>
            <p class="text-gray-400">Consumo de contexto de configuración Claude (<code class="text-ai-cyan">.claude/</code>)</p>
        </div>
HTMLHEADER

# Add summary card
cat >> "$OUTPUT_FILE" << EOF
        <!-- Summary Card -->
        <div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6">
            <h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2">
                <span>⚡</span> Resumen de Consumo
            </h2>

            <!-- Progress Bar -->
            <div class="bg-bg-tertiary rounded-lg h-8 overflow-hidden relative mb-2">
                <div class="${STATUS_CLASS} h-full rounded-lg transition-all duration-500" style="width: ${PERCENT_USED}%"></div>
                <span class="absolute inset-0 flex items-center justify-center text-sm font-semibold">${PERCENT_USED}% usado</span>
            </div>

            <!-- Zone Indicators -->
            <div class="flex justify-between text-xs mb-6">
                <span class="px-2 py-1 rounded bg-ai-green/20 text-ai-green">0-60% Seguro</span>
                <span class="px-2 py-1 rounded bg-warning/20 text-warning">60-80% Precaución</span>
                <span class="px-2 py-1 rounded bg-error/20 text-error">&gt;80% Riesgo</span>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-bg-tertiary rounded-lg p-4 text-center">
                    <div class="text-2xl font-bold text-ai-purple">${TOTAL_TOKENS}</div>
                    <div class="text-xs text-gray-400 mt-1">Tokens Reglas</div>
                </div>
                <div class="bg-bg-tertiary rounded-lg p-4 text-center">
                    <div class="text-2xl font-bold text-ai-cyan">~${SYSTEM_OVERHEAD}</div>
                    <div class="text-xs text-gray-400 mt-1">Sistema Base</div>
                </div>
                <div class="bg-bg-tertiary rounded-lg p-4 text-center">
                    <div class="text-2xl font-bold text-ai-green">~${AVAILABLE}</div>
                    <div class="text-xs text-gray-400 mt-1">Disponible</div>
                </div>
                <div class="bg-bg-tertiary rounded-lg p-4 text-center">
                    <div class="text-2xl font-bold text-ai-orange">200K</div>
                    <div class="text-xs text-gray-400 mt-1">Límite Contexto</div>
                </div>
            </div>
        </div>

        <!-- Last Commit Card -->
        <div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6">
            <h2 class="text-lg font-semibold text-ai-purple mb-4 flex items-center gap-2">
                <span>🔄</span> Último Cambio en .claude/
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                    <span class="text-gray-500">Commit:</span>
                    <span class="font-mono text-ai-cyan ml-2">${LAST_COMMIT_HASH}</span>
                </div>
                <div>
                    <span class="text-gray-500">Fecha:</span>
                    <span class="text-gray-300 ml-2">${LAST_COMMIT_DATE}</span>
                </div>
                <div>
                    <span class="text-gray-500">Autor:</span>
                    <span class="text-gray-300 ml-2">${LAST_COMMIT_AUTHOR}</span>
                </div>
                <div>
                    <span class="text-gray-500">Via Claude:</span>
                    <span class="ml-2 ${VIA_CLAUDE_CLASS}">${VIA_CLAUDE}</span>
                </div>
            </div>
            <div class="mt-3 p-3 bg-bg-tertiary rounded-lg">
                <span class="text-gray-500 text-xs">Mensaje:</span>
                <p class="text-gray-300 font-mono text-sm mt-1">${LAST_COMMIT_MSG}</p>
            </div>
        </div>

        <!-- Files Table -->
        <div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6">
            <h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2">
                <span>📁</span> Desglose por Archivo
                <span class="text-xs text-gray-500 font-normal ml-2">(click para ver contenido)</span>
            </h2>

            <div class="overflow-x-auto">
                <table class="w-full">
                    <thead>
                        <tr class="text-left text-sm text-gray-400 border-b border-border-default">
                            <th class="pb-3">Archivo</th>
                            <th class="pb-3 text-right">Caracteres</th>
                            <th class="pb-3 text-right">Tokens (est.)</th>
                        </tr>
                    </thead>
                    <tbody class="text-sm">
EOF

# Sort files and add rows with data attributes for lightbox
for file in $(echo "${!FILE_TOKENS[@]}" | tr ' ' '\n' | sort); do
    # Create a safe ID from filename
    SAFE_ID=$(echo "$file" | sed 's/[^a-zA-Z0-9]/_/g')
    cat >> "$OUTPUT_FILE" << EOF
                        <tr class="border-b border-border-default/50">
                            <td class="py-3 font-mono text-ai-cyan file-link" onclick="openLightbox('${file}', '${SAFE_ID}')">${file}</td>
                            <td class="py-3 text-right text-gray-400">${FILE_CHARS[$file]}</td>
                            <td class="py-3 text-right text-ai-purple">${FILE_TOKENS[$file]}</td>
                        </tr>
EOF
done

# Close table
cat >> "$OUTPUT_FILE" << 'EOF'
                    </tbody>
                </table>
            </div>

            <!-- Note -->
            <div class="mt-4 p-4 bg-ai-cyan/5 border-l-2 border-ai-cyan rounded-r-lg text-sm text-gray-300">
                <strong class="text-ai-cyan">Nota:</strong> Estimación basada en ~4 caracteres por token.
                Los tokens reales pueden variar según el tokenizer de Claude.
                Los skills (<code class="text-ai-purple">.claude/skills/</code>) solo se cargan bajo demanda.
            </div>
        </div>
EOF

# Add file contents as hidden data
cat >> "$OUTPUT_FILE" << 'EOF'
        <!-- Hidden file contents for lightbox -->
        <div id="file-contents" style="display:none;">
EOF

for file in $(echo "${!FILE_TOKENS[@]}" | tr ' ' '\n' | sort); do
    SAFE_ID=$(echo "$file" | sed 's/[^a-zA-Z0-9]/_/g')
    cat >> "$OUTPUT_FILE" << EOF
            <div id="content-${SAFE_ID}">${FILE_CONTENT[$file]}</div>
EOF
done

# Close hidden contents and add footer with scripts
cat >> "$OUTPUT_FILE" << EOF
        </div>

        <!-- Timestamp -->
        <div class="text-center text-sm text-gray-500 pt-4 border-t border-border-default">
            Generado: ${TIMESTAMP}
        </div>

        <!-- Back Link -->
        <div class="text-center mt-4">
            <a href="index.html" class="text-ai-cyan hover:text-ai-purple transition-colors text-sm">
                ← Volver a Technical
            </a>
        </div>
    </div>

    <script>
        let currentContent = '';

        function openLightbox(filename, safeId) {
            const content = document.getElementById('content-' + safeId).innerHTML;
            currentContent = content.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'");

            document.getElementById('lightbox-title').textContent = filename;
            document.getElementById('lightbox-content').innerHTML = content;
            document.getElementById('lightbox').classList.add('active');
            document.body.style.overflow = 'hidden';

            // Reset copy button
            resetCopyBtn();
        }

        function closeLightbox() {
            document.getElementById('lightbox').classList.remove('active');
            document.body.style.overflow = '';
        }

        function copyContent() {
            navigator.clipboard.writeText(currentContent).then(() => {
                const btn = document.getElementById('copy-btn');
                const icon = document.getElementById('copy-icon');
                const text = document.getElementById('copy-text');

                btn.classList.add('copied');
                icon.textContent = '✓';
                text.textContent = 'Copiado!';

                setTimeout(resetCopyBtn, 2000);
            });
        }

        function resetCopyBtn() {
            const btn = document.getElementById('copy-btn');
            const icon = document.getElementById('copy-icon');
            const text = document.getElementById('copy-text');

            btn.classList.remove('copied');
            icon.textContent = '📋';
            text.textContent = 'Copiar';
        }

        // Close on Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') closeLightbox();
        });
    </script>
</body>
</html>
EOF

echo "✓ Token report generated: $OUTPUT_FILE"
