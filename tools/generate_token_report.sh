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

# Get file list and stats
declare -A FILE_TOKENS
declare -A FILE_CHARS
TOTAL_CHARS=0

# Process all files in .claude/
while IFS= read -r -d '' file; do
    rel_path="${file#$CLAUDE_DIR/}"
    chars=$(count_chars "$file")
    tokens=$(estimate_tokens "$chars")
    FILE_TOKENS["$rel_path"]=$tokens
    FILE_CHARS["$rel_path"]=$chars
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
    </style>
</head>
<body class="min-h-screen p-8">
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

        <!-- Files Table -->
        <div class="bg-bg-card border border-border-default rounded-xl p-6 mb-6">
            <h2 class="text-lg font-semibold text-ai-cyan mb-4 flex items-center gap-2">
                <span>📁</span> Desglose por Archivo
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

# Sort files and add rows
for file in $(echo "${!FILE_TOKENS[@]}" | tr ' ' '\n' | sort); do
    cat >> "$OUTPUT_FILE" << EOF
                        <tr class="border-b border-border-default/50">
                            <td class="py-3 font-mono text-ai-cyan">${file}</td>
                            <td class="py-3 text-right text-gray-400">${FILE_CHARS[$file]}</td>
                            <td class="py-3 text-right text-ai-purple">${FILE_TOKENS[$file]}</td>
                        </tr>
EOF
done

# Close table and add footer
cat >> "$OUTPUT_FILE" << EOF
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

        <!-- Timestamp -->
        <div class="text-center text-sm text-gray-500 pt-4 border-t border-border-default">
            Generado: ${TIMESTAMP}
        </div>

        <!-- Back Link -->
        <div class="text-center mt-4">
            <a href="../home.html" class="text-ai-cyan hover:text-ai-purple transition-colors text-sm">
                ← Volver a la documentación
            </a>
        </div>
    </div>
</body>
</html>
EOF

echo "✓ Token report generated: $OUTPUT_FILE"
