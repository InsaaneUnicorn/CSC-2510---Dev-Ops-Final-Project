#!/usr/bin/env bash
# interface.sh — main menu for Person 1 (scrape + parse only)

set -euo pipefail

APP_NAME="DeelTech Faculty Portal"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${BASE_DIR}/data"

SCRAPER="${BASE_DIR}/web-scraper.sh"
PARSER="${BASE_DIR}/parse.sh"

mkdir -p "${DATA_DIR}"

menu() {
  echo "==== ${APP_NAME} ===="
  echo "1) Scrape + Parse (default)"
  echo "2) Scrape only"
  echo "3) Parse only"
  echo "4) Exit"
  read -r -p "Choice: " choice
  case "$choice" in
    1|"") bash "${SCRAPER}" "${DATA_DIR}" && bash "${PARSER}" "${DATA_DIR}" \
          && echo "[OK] Names saved to ${DATA_DIR}/names.txt" ;;
    2) bash "${SCRAPER}" "${DATA_DIR}" ;;
    3) bash "${PARSER}" "${DATA_DIR}" && echo "[OK] Names saved to ${DATA_DIR}/names.txt" ;;
    4) exit 0 ;;
    *) echo "Invalid choice" ;;
  esac
}

menu