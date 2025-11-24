#The automated user script
#!/usr/bin/env bash
# ============================================
# User Creation Engine
# source with: source automated-user.sh
# run with: main "First_Name" "Last_Name"
# ============================================

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

# -------------------------
# Generates username
# -------------------------
generate_username() {
    FIRST="$1"
    LAST="$2"

    # Make lowercase
    CLEAN_FIRST=$(echo "$FIRST" | tr '[:upper:]' '[:lower:]')
    CLEAN_LAST=$(echo "$LAST" | tr '[:upper:]' '[:lower:]')

    echo "${CLEAN_FIRST}.${CLEAN_LAST}"
}

# -------------------------
# Generates password
# -------------------------
generate_password() {
    FIRST="$1"
    LAST="$2"

    CLEAN_FIRST=$(echo "$FIRST" | tr '[:upper:]' '[:lower:]')
    CLEAN_LAST=$(echo "$LAST" | tr '[:upper:]' '[:lower:]')

    echo "${CLEAN_FIRST}${CLEAN_LAST}DEELTECH"
}

# -------------------------
# Checks if user exists
# -------------------------
user_exists() {
    if id "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# -------------------------
# Main function, creates user
# -------------------------
main() {
    FIRST_NAME=$1
    LAST_NAME=$2

    # Make sure there is a first and last name
    if [[ -z "$FIRST_NAME" || -z "$LAST_NAME" ]]; then
        echo "Error: First and last name required."
        return 3
    fi

    USERNAME=$(generate_username "$FIRST_NAME" "$LAST_NAME")
    PASSWORD=$(generate_password "$FIRST_NAME" "$LAST_NAME")

    # Check if user exists
    if user_exists "$USERNAME"; then
        echo "User '$USERNAME' already exists."
        return 1
    fi

    # Create account
    if sudo useradd -m "$USERNAME"; then
        echo "${USERNAME}:${PASSWORD}" | sudo chpasswd
        echo "Created user '$USERNAME'"
        return 0
    else
        echo "Failed to create user '$USERNAME'"
        return 2
    fi
}

# Make sure main runs ONLY when executed, not when file is sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    require_license
    main "$@"
fi