#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and catch pipe failures
set -euo pipefail

echo "=== Checking RISC-V Log Analyzer Environment ==="

# List of required tools
REQUIRED_TOOLS=("bash" "grep" "awk" "sed" "make")
MISSING_TOOLS=0

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "[PASS] Found required tool: $tool"
    else
        echo "[FAIL] Missing required tool: $tool"
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    fi
done

echo "==============================================="

if [ "$MISSING_TOOLS" -eq 0 ]; then
    echo "Environment check passed successfully! All tools are installed."
    exit 0
else
    echo "Environment check failed: $MISSING_TOOLS required tool(s) missing."
    exit 1
fi
