#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${1:-$(pwd)/data}"
IN_HTML="${DATA_DIR}/faculty.html"
OUT_TXT="${DATA_DIR}/names.txt"

if [[ ! -f "${IN_HTML}" ]]; then
  echo "[ERROR] faculty.html not found at ${IN_HTML}. Run web-scraper.sh first."
  exit 1
fi

# Debugging to ensure all faculty & staff are listed
# RAW_COUNT=$(grep -c '<h4><strong>' "${IN_HTML}")
# echo "[DEBUG] Found $RAW_COUNT raw <h4><strong> blocks"

grep -o '<h4><strong>[^<]*' "${IN_HTML}" \
  | sed -E 's/<h4><strong>//g; s/<br>//gi' \
  | sed -E 's/&nbsp;/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//' \
  | sed -E 's/,.*//g' \
  | sed -E 's/\b(Dr|Mr|Mrs|Ms|Prof|Professor)\b//gi' \
  | sed -E 's/[ ]+/ /g' \
  > "${OUT_TXT}"

COUNT=$(wc -l < "${OUT_TXT}")
echo "[OK] Extracted $COUNT faculty/staff names in page order → ${OUT_TXT}"
