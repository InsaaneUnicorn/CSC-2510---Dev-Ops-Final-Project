#The automated user script
#!/usr/bin/env bash
# ============================================
# User Creation Engine
# source with: source automated-user.sh
# run with: main "First_Name" "Last_Name"
# ============================================

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
    # use /dev/urandom to generate the random string
    # each character is a random letter, digit, or special character
    tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 12
    echo
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

    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DATA_DIR="${BASE_DIR}/data"
    OUTPUT="${DATA_DIR}/logins.txt"

    # Make sure there is a first and last name
    if [[ -z "$FIRST_NAME" || -z "$LAST_NAME" ]]; then
        echo "Error: First and last name required."
        return 3
    fi

    USERNAME=$(generate_username "$FIRST_NAME" "$LAST_NAME")
    PASSWORD=$(generate_password)

    # Check if user exists
    if user_exists "$USERNAME"; then
        echo "User '$USERNAME' already exists."
        return 1
    fi

    # Create account
    if sudo useradd -m "$USERNAME"; then
        echo "${USERNAME}:${PASSWORD}" | sudo chpasswd
        echo "Created user '$USERNAME'"

        echo "Username: $USERNAME, Password: $PASSWORD" >> "$OUTPUT"

        return 0
    else
        echo "Failed to create user '$USERNAME'"
        return 2
    fi
}

# Make sure main runs ONLY when excuted, not when file is sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi