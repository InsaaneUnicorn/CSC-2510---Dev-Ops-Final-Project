#!/usr/bin/env bash
# interface.sh — main menu for Person 1 (scrape + parse only)

#source file for the user creation API
source automated-user.sh

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
  echo "4) Create users from names list"
  echo "5) Exit"
  read -r -p "Choice: " choice
  case "$choice" in
    1|"") bash "${SCRAPER}" "${DATA_DIR}" && bash "${PARSER}" "${DATA_DIR}" \
          && echo "[OK] Names saved to ${DATA_DIR}/names.txt" ;;
    2) bash "${SCRAPER}" "${DATA_DIR}" ;;
    3) bash "${PARSER}" "${DATA_DIR}" && echo "[OK] Names saved to ${DATA_DIR}/names.txt" ;;
    4) automate_user_creation ;;
    5) exit 0 ;;
    *) echo "Invalid choice" ;;
  esac
}

# -------------------------
# Loops through through names.txt and makes users out of names
# Needs scrape + parse to be ran first
# -------------------------
automate_user_creation() {
  NAMES_FILE="${DATA_DIR}/names.txt"

  if [[ ! -f "$NAMES_FILE" ]]; then
    echo "No names.txt found. Run scrape+parse first."
    return 1
  fi

  echo "Creating users from names.txt..."

  # This should grab a line and take the
  # first word of the line as the first name
  # and the last word as the last name
  while read -r line; do
    FIRST=$(echo "$line" | awk '{print $1}')
    LAST=$(echo "$line" | awk '{print $NF}')
    echo "Creating account for $FIRST $LAST..."
    main "$FIRST" "$LAST"
  done < "$NAMES_FILE"

  echo "Automated account creation complete."
}

menu