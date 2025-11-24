#!/usr/bin/env bash

set -euo pipefail

# ---------------- Configuration ----------------
# These values MUST match the main script exactly
LICENSE_DIR="/etc/csc_user_mgmt"
LICENSE_PREFIX=".lic_"
# Obfuscated salt parts (base64 encoded) - MUST MATCH MAIN SCRIPT
SALT_B64_A="Y3NjX3NhbHQ="      # base64("csc_salt")
SALT_B64_B="X3NlY3JldA=="      # base64("_secret")
SALT_B64_C="XzIwMjU="          # base64("_2025")
# Valid license key hash - MUST MATCH MAIN SCRIPT
VALID_KEY_HASH="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"
# ------------------------------------------------

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

ensure_license_dir() {
  if [ ! -d "${LICENSE_DIR}" ]; then
    mkdir -p "${LICENSE_DIR}"
    chmod 755 "${LICENSE_DIR}" || true
  fi
}

random_license_file() {
  printf "%s/%s%s.dat" "${LICENSE_DIR}" "${LICENSE_PREFIX}" "$(openssl rand -hex 8)"
}

generate_license_key() {
  # Generate a random 16-digit number
  local key=""
  for i in {1..16}; do
    key="${key}$(shuf -i 0-9 -n 1)"
  done
  echo "${key}"
}

compute_hash() {
  local key="$1"
  local salt
  salt="$(_get_salt)"
  printf "%s%s" "${salt}" "${key}" | sha256sum | awk '{print $1}'
}

create_license_file() {
  local key="$1"
  ensure_license_dir
  local salt derived file
  salt="$(_get_salt)"
  derived=$(printf "%s%s" "${salt}" "${key}" | sha256sum | awk '{print $1}')
  file="$(random_license_file)"
  printf '{"v":1,"h":"%s","t":%d}' "${derived}" "$(date +%s)" > "${file}"
  chmod 644 "${file}" || true
  echo "${file}"
}

show_current_valid_key() {
  echo "============================================"
  echo "CURRENT VALID LICENSE KEY"
  echo "============================================"
  echo
  echo "The current valid license key that matches"
  echo "the hardcoded hash in the main script is:"
  echo
  echo "  1234567890123456"
  echo
  echo "This is the key that should be given to the customer"
  echo "============================================"
}

generate_new_key_config() {
  echo
  echo "============================================"
  echo "GENERATE NEW LICENSE KEY CONFIGURATION"
  echo "============================================"
  echo
  echo "This will generate a NEW random 16-digit key"
  echo "and show you the hash value to update in both"
  echo "the main script and this generator script."
  echo
  read -p "Continue? (y/n): " confirm
  if [ "${confirm}" != "y" ]; then
    echo "Cancelled."
    return
  fi
  
  local new_key new_hash
  new_key=$(generate_license_key)
  new_hash=$(compute_hash "${new_key}")
  
  echo
  echo "New License Key: ${new_key}"
  echo "New Hash Value:  ${new_hash}"
  echo
  echo "TO UPDATE THE SCRIPTS:"
  echo "1. Edit the main script and this generator script"
  echo "2. Find the line: VALID_KEY_HASH=\"...\""
  echo "3. Replace the hash value with: ${new_hash}"
  echo "4. Save both scripts"
  echo "5. Email the new key to the customer: ${new_key}"
  echo
}

create_license_file_interactive() {
  echo
  echo "============================================"
  echo "CREATE LICENSE FILE"
  echo "============================================"
  echo
  echo "This will create a valid license file that"
  echo "can be distributed to students."
  echo
  read -p "Enter the 16-digit license key: " key
  
  if ! [[ "${key}" =~ ^[0-9]{16}$ ]]; then
    echo "Error: License key must be exactly 16 digits." >&2
    return 1
  fi
  
  local derived
  derived=$(compute_hash "${key}")
  
  if [ "${derived}" != "${VALID_KEY_HASH}" ]; then
    echo "Error: This key does not match the valid hash." >&2
    echo "Expected hash: ${VALID_KEY_HASH}"
    echo "Computed hash: ${derived}"
    return 1
  fi
  
  local file
  file=$(create_license_file "${key}")
  echo
  echo "Success! License file created: ${file}"
  echo
  echo "You can now distribute this file to students."
  echo "They should place it in: ${LICENSE_DIR}/"
  echo
}

show_menu() {
  echo
  echo "============================================"
  echo "LICENSE FILE GENERATOR - ADMIN TOOL"
  echo "============================================"
  echo
  echo "1. Show current valid license key"
  echo "2. Create license file for distribution"
  echo "3. Generate new key configuration (updates needed)"
  echo "4. Exit"
  echo
  read -p "Select option (1-4): " choice
  
  case "${choice}" in
    1) show_current_valid_key ;;
    2) create_license_file_interactive ;;
    3) generate_new_key_config ;;
    4) echo "Exiting."; exit 0 ;;
    *) echo "Invalid option."; return 1 ;;
  esac
}

# Main loop
if [ "$(id -u)" -ne 0 ]; then
  echo "Warning: Running as non-root. Creating license files may require sudo." >&2
fi

while true; do
  show_menu
  echo
  read -p "Press Enter to continue..."
done
