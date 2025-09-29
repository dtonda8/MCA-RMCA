#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <results_dir>"
    exit 1
fi

RESULTS_DIR="$1"
COMBINED="$RESULTS_DIR/combined.csv"

files=("$RESULTS_DIR"/*.csv)
total=${#files[@]}

if [[ $total -eq 0 ]]; then
    echo "No CSV files found in $RESULTS_DIR"
    exit 1
fi

echo "Found $total CSV files. Combining..."

# Simply concatenate all files
cat "${files[@]}" > "$COMBINED"

echo "✅ All files combined into: $COMBINED"