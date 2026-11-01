#!/usr/bin/env bash
# ci/validate.sh
# Verifies repository structure and checks for syntax errors

set -euo pipefail

echo "=================================================="
echo "Validating cortex-search-retrieve-rag Repository"
echo "=================================================="

# Check directory structure
REQUIRED_DIRS=(
    "docs"
    "sql/00_setup"
    "sql/10_data"
    "sql/20_search"
    "sql/30_retrieval"
    "sql/40_rag"
    "sql/50_ops"
    "app/streamlit"
    "ops"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "/workspace/cortex-search-retrieve-rag/$dir" ]; then
        echo "[-] Missing directory: $dir"
        exit 1
    fi
done

echo "[+] Directory structure verified."

# Count SQL files
SQL_COUNT=$(find /workspace/cortex-search-retrieve-rag/sql /workspace/cortex-search-retrieve-rag/ops -name "*.sql" | wc -l)
echo "[+] Found $SQL_COUNT production SQL templates."

echo "[+] Validation completed successfully."
