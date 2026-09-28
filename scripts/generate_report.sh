#!/usr/bin/env bash

# Exit immediately on error, treat unset variables as errors, and catch pipe failures
set -euo pipefail

OUTPUT_DIR="output"
TEST_DATA_DIR="test_data"
ANALYZER="./scripts/analyze.sh"

mkdir -p "$OUTPUT_DIR"

echo "=== Generating RISC-V Log Analysis Reports (Text, CSV, HTML) ==="

if [[ ! -x "$ANALYZER" ]]; then
    echo "Error: Analyzer script '$ANALYZER' not found or not executable." >&2
    exit 1
fi

for log in "$TEST_DATA_DIR"/*.log; do
    if [[ -f "$log" ]]; then
        filename=$(basename "$log" .log)
        report_path="$OUTPUT_DIR/${filename}_report.txt"
        csv_path="$OUTPUT_DIR/${filename}_report.csv"
        html_path="$OUTPUT_DIR/${filename}_report.html"

        echo "Processing $log..."
        
        # 1. Generate text report
        "$ANALYZER" "$log" --output "$report_path" || true
        
        # 2. Generate CSV report
        "$ANALYZER" "$log" --format csv --output "$csv_path" || true
        
        # 3. Generate HTML report
        cat << HTML > "$html_path"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>RISC-V Log Analysis - $filename</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f7f6; color: #333; }
        .container { background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #004080; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; border: 1px solid #ddd; text-align: left; }
        th { background: #004080; color: white; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
    </style>
</head>
<body>
<div class="container">
    <h1>RISC-V Simulation Log Analysis</h1>
    <p><strong>Log File:</strong> $log</p>
    <p><strong>Generated on:</strong> $(date)</p>
    <h2>Summary Metrics</h2>
    <table>
        <tr><th>Metric</th><th>Value</th></tr>
HTML

        # Parse CSV to populate HTML table rows
        tail -n +2 "$csv_path" | while IFS=',' read -r metric val; do
            echo "        <tr><td>$metric</td><td>$val</td></tr>" >> "$html_path"
        done

        cat << HTML >> "$html_path"
    </table>
</div>
</body>
</html>
HTML

        echo "  -> Created: $report_path"
        echo "  -> Created: $csv_path"
        echo "  -> Created: $html_path"
    fi
done

echo "==============================================================="
echo "All reports (Text, CSV, HTML) generated successfully in '$OUTPUT_DIR/'."
EOF
