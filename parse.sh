#!/usr/bin/env bash
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

DATA_DIR="${1:-$(pwd)/data}"
IN_HTML="${DATA_DIR}/faculty.html"
OUT_TXT="${DATA_DIR}/names.txt"

require_license

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