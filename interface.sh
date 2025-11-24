#!/usr/bin/env bash
# interface.sh — main menu for Person 1 (scrape + parse only)

#source file for the user creation API
source automated-user.sh

set -euo pipefail

# ---------------- License Configuration ----------------
LICENSE_DIR="/etc/csc_user_mgmt"
LICENSE_FILE_PATH="${LICENSE_DIR}/license.dat"
SALT_B64_A="Y3NjX3NhbHQ="
SALT_B64_B="X3NlY3JldA=="
SALT_B64_C="XzIwMjU="
VALID_KEY_HASH="bc9f90fd5628862d3e460074c431f552cc11c1f57e3d645fb9c437ae4ce56153"

# ---------------- License Functions ----------------
_get_salt() {
    local a b c
    if command -v base64 >/dev/null 2>&1; then
        a="$(printf "%s" "${SALT_B64_A}" | base64 --decode 2>/dev/null || printf "")"
        b="$(printf "%s" "${SALT_B64_B}" | base64 --decode 2>/dev/null || printf "")"
        c="$(printf "%s" "${SALT_B64_C}" | base64 --decode 2>/dev/null || printf "")"
    else
        a="$(printf "%s" "${SALT_B64_A}" | openssl enc -base64 -d 2>/dev/null || printf "")"
        b="$(printf "%s" "${SALT_B64_B}" | openssl enc -base64 -d 2>/dev/null || printf "")"
        c="$(printf "%s" "${SALT_B64_C}" | openssl enc -base64 -d 2>/dev/null || printf "")"
    fi
    printf "%s" "${a}${b}${c}"
}

ensure_license_dir() { [ ! -d "${LICENSE_DIR}" ] && mkdir -p "${LICENSE_DIR}" && chmod 755 "${LICENSE_DIR}" || true; }
find_license_file() { [ -f "${LICENSE_FILE_PATH}" ] && echo "${LICENSE_FILE_PATH}" || echo ""; }

create_license_file() {
    local key="$1";
    ensure_license_dir;
    local salt derived;
    salt="$(_get_salt)";
    derived=$(printf "%s%s" "${salt}" "${key}" | sha256sum | awk '{print $1}');
    
    printf '{"v":1,"h":"%s","t":%d}' "${derived}" "$(date +%s)" > "${LICENSE_FILE_PATH}";
    chmod 644 "${LICENSE_FILE_PATH}" || true;
    echo "${LICENSE_FILE_PATH}";
}

verify_license_key() { local key="$1"; [[ "${key}" =~ ^[0-9]{16}$ ]] && [ "$(printf "%s%s" "$(_get_salt)" "$key" | sha256sum | awk '{print $1}')" = "${VALID_KEY_HASH}" ]; }
verify_license_file() { local f="$1"; [ -f "${f}" ] && [ "$(grep -o '"h":"[^"]*"' "${f}" | cut -d'"' -f4)" = "${VALID_KEY_HASH}" ]; }

require_license() {
    local f
    f="$(find_license_file)"
    if [ -z "$f" ]; then
        echo "Enter your 16-digit license key:"
        read -r key
        verify_license_key "${key}" || { echo "Invalid license key"; exit 1; }
        create_license_file "${key}" >/dev/null
    else
        verify_license_file "${f}" || { echo "License verification failed"; exit 1; }
    fi
}

APP_NAME="DeelTech Faculty Portal"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${BASE_DIR}/data"

SCRAPER="${BASE_DIR}/web-scraper.sh"
PARSER="${BASE_DIR}/parse.sh"
MANUAL_USER="${BASE_DIR}/manual-user.sh"

mkdir -p "${DATA_DIR}"

menu() {
  echo "==== ${APP_NAME} ===="
  echo "1) Scrape + Parse (default)"
  echo "2) Scrape only"
  echo "3) Parse only"
  echo "4) Create users from names list"
  echo "5) Manually create a user"
  echo "6) Exit"
  read -r -p "Choice: " choice
  case "$choice" in
    1|"") bash "${SCRAPER}" "${DATA_DIR}" && bash "${PARSER}" "${DATA_DIR}" \
          && echo "[OK] Names saved to ${DATA_DIR}/names.txt"
          echo ""
          echo "Press Enter to return to menu..."
          read -r ;;
    2) bash "${SCRAPER}" "${DATA_DIR}"
       echo ""
       echo "Press Enter to return to menu..."
       read -r ;;
    3) bash "${PARSER}" "${DATA_DIR}" && echo "[OK] Names saved to ${DATA_DIR}/names.txt"
       echo ""
       echo "Press Enter to return to menu..."
       read -r ;;
    4) automate_user_creation
       echo ""
       echo "Press Enter to return to menu..."
       read -r ;;
    5) bash "${MANUAL_USER}"
       echo ""
       echo "Press Enter to return to menu..."
       read -r ;;
    6) echo "Exiting..."
       exit 0 ;;
    *) echo "Invalid choice"
       echo ""
       echo "Press Enter to return to menu..."
       read -r ;;
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
    main "$FIRST" "$LAST" || true  # Continue even if user exists or creation fails
  done < "$NAMES_FILE"

  echo "Automated account creation complete."
}

require_license
while true; do
  menu
done