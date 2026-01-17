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

# Generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Generate HTML
cat > "$OUTPUT_FILE" << 'HTMLHEADER'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Token Report - Claude Config</title>
    <style>
        :root {
            --bg-primary: #0a0d12;
            --bg-secondary: #0f1419;
            --bg-tertiary: #161b22;
            --border: #21262d;
            --text-primary: #e6edf3;
            --text-secondary: #8b949e;
            --start: #10b981;
            --end: #ef4444;
            --ai: #3b82f6;
            --static: #6b7280;
            --choice: #eab308;
            --cond: #f97316;
            --event: #a855f7;
            --var: #06b6d4;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            padding: 2rem;
        }

        .container {
            max-width: 900px;
            margin: 0 auto;
        }

        h1 {
            font-size: 2rem;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, var(--var), var(--event));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .subtitle {
            color: var(--text-secondary);
            margin-bottom: 2rem;
            font-size: 0.9rem;
        }

        .card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }

        .card-title {
            font-size: 1.1rem;
            color: var(--var);
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .progress-container {
            background: var(--bg-tertiary);
            border-radius: 8px;
            height: 32px;
            overflow: hidden;
            position: relative;
            margin: 1rem 0;
        }

        .progress-bar {
            height: 100%;
            border-radius: 8px;
            transition: width 0.5s ease;
        }

        .progress-safe { background: linear-gradient(90deg, var(--start), var(--ai)); }
        .progress-warn { background: linear-gradient(90deg, var(--choice), var(--cond)); }
        .progress-danger { background: linear-gradient(90deg, var(--cond), var(--end)); }

        .progress-label {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-weight: 600;
            font-size: 0.85rem;
            text-shadow: 0 1px 2px rgba(0,0,0,0.8);
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 1rem;
            margin-top: 1rem;
        }

        .stat-box {
            background: var(--bg-tertiary);
            border-radius: 8px;
            padding: 1rem;
            text-align: center;
        }

        .stat-value {
            font-size: 1.8rem;
            font-weight: 700;
        }

        .stat-value.tokens { color: var(--event); }
        .stat-value.system { color: var(--ai); }
        .stat-value.available { color: var(--start); }
        .stat-value.percent { color: var(--var); }

        .stat-label {
            font-size: 0.8rem;
            color: var(--text-secondary);
            margin-top: 0.25rem;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }

        th, td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }

        th {
            color: var(--text-secondary);
            font-weight: 500;
            font-size: 0.85rem;
        }

        td.file { color: var(--var); font-family: monospace; }
        td.tokens { color: var(--event); text-align: right; }
        td.chars { color: var(--text-secondary); text-align: right; }

        .zone-indicator {
            display: flex;
            justify-content: space-between;
            margin-top: 0.5rem;
            font-size: 0.75rem;
        }

        .zone { padding: 0.25rem 0.5rem; border-radius: 4px; }
        .zone-safe { background: rgba(16, 185, 129, 0.2); color: var(--start); }
        .zone-warn { background: rgba(234, 179, 8, 0.2); color: var(--choice); }
        .zone-danger { background: rgba(239, 68, 68, 0.2); color: var(--end); }

        .timestamp {
            text-align: center;
            color: var(--text-secondary);
            font-size: 0.8rem;
            margin-top: 2rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border);
        }

        .note {
            background: rgba(6, 182, 212, 0.1);
            border-left: 3px solid var(--var);
            padding: 1rem;
            margin-top: 1rem;
            border-radius: 0 8px 8px 0;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Reporte de Tokens</h1>
        <p class="subtitle">Consumo de contexto de configuración Claude (.claude/)</p>
HTMLHEADER

# Add summary card
cat >> "$OUTPUT_FILE" << EOF
        <div class="card">
            <div class="card-title">⚡ Resumen de Consumo</div>
            <div class="progress-container">
                <div class="progress-bar $([ $(echo "$PERCENT_USED < 60" | bc -l) -eq 1 ] && echo "progress-safe" || ([ $(echo "$PERCENT_USED < 80" | bc -l) -eq 1 ] && echo "progress-warn" || echo "progress-danger"))" style="width: ${PERCENT_USED}%"></div>
                <span class="progress-label">${PERCENT_USED}% usado</span>
            </div>
            <div class="zone-indicator">
                <span class="zone zone-safe">0-60% Seguro</span>
                <span class="zone zone-warn">60-80% Precaución</span>
                <span class="zone zone-danger">>80% Riesgo</span>
            </div>
            <div class="stats-grid">
                <div class="stat-box">
                    <div class="stat-value tokens">${TOTAL_TOKENS}</div>
                    <div class="stat-label">Tokens Reglas</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value system">~${SYSTEM_OVERHEAD}</div>
                    <div class="stat-label">Sistema Base</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value available">~${AVAILABLE}</div>
                    <div class="stat-label">Disponible</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value percent">200K</div>
                    <div class="stat-label">Límite Contexto</div>
                </div>
            </div>
        </div>
EOF

# Add files table
cat >> "$OUTPUT_FILE" << 'EOF'
        <div class="card">
            <div class="card-title">📁 Desglose por Archivo</div>
            <table>
                <thead>
                    <tr>
                        <th>Archivo</th>
                        <th style="text-align:right">Caracteres</th>
                        <th style="text-align:right">Tokens (est.)</th>
                    </tr>
                </thead>
                <tbody>
EOF

# Sort files and add rows
for file in $(echo "${!FILE_TOKENS[@]}" | tr ' ' '\n' | sort); do
    cat >> "$OUTPUT_FILE" << EOF
                    <tr>
                        <td class="file">${file}</td>
                        <td class="chars">${FILE_CHARS[$file]}</td>
                        <td class="tokens">${FILE_TOKENS[$file]}</td>
                    </tr>
EOF
done

# Close table and add footer
cat >> "$OUTPUT_FILE" << EOF
                </tbody>
            </table>
            <div class="note">
                <strong>Nota:</strong> Estimación basada en ~4 caracteres por token.
                Los tokens reales pueden variar según el tokenizer de Claude.
                Los skills (.claude/skills/) solo se cargan bajo demanda.
            </div>
        </div>

        <div class="timestamp">
            Generado: ${TIMESTAMP}
        </div>
    </div>
</body>
</html>
EOF

echo "✓ Token report generated: $OUTPUT_FILE"
