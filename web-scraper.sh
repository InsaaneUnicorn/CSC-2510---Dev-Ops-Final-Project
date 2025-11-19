#!/usr/bin/env bash
# web-scraper.sh — downloads TNTech CS faculty page
# Usage: web-scraper.sh [DATA_DIR]

set -euo pipefail

DATA_DIR="${1:-$(pwd)/data}"
URL="https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php"
OUT_HTML="${DATA_DIR}/faculty.html"

mkdir -p "${DATA_DIR}"

echo "[INFO] Fetching ${URL}"
curl -sSL "${URL}" -o "${OUT_HTML}"