#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log errors and exit
log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Update SSH configuration
echo "[INFO] Updating SSH configuration..."
sed -i 's/^#*\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config || log_error "Failed to update SSH configuration."
systemctl restart ssh || log_error "Failed to restart SSH service."

# Set password for root
ROOT_PASSWORD="\$C0nV0x\$"
echo "[INFO] Setting password for root user"
echo "root:$ROOT_PASSWORD" | chpasswd || log_error "Failed to set password for root user."

# Create a new user
USERNAMELIST=("ccadmin" "convox")
COMMENT="convox admin"
USER_PASSWORD=""

for USERNAME in "${USERNAMELIST[@]}"; do
    if ! id $USERNAME &>/dev/null; then
        echo "[INFO] Adding new user: $USERNAME"
        useradd -m -k /etc/skel  -s /bin/bash  -c "$COMMENT" -G sudo "$USERNAME" || log_error "Failed to create user $USERNAME."

        # Set password for the new user
        echo "[INFO] Setting password for user: $USERNAME"
        echo "$USERNAME:$USER_PASSWORD" | chpasswd || log_error "Failed to set password for user $USERNAME."

        # Configure sudo privileges
        echo "[INFO] Configuring sudo privileges for $USERNAME"
        echo "$USERNAME   ALL=(ALL)  NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME" || log_error "Failed to configure sudo privileges for $USERNAME."
        chmod 440 "/etc/sudoers.d/$USERNAME" || log_error "Failed to set permissions on /etc/sudoers.d/$USERNAME."
    else
        # change password for the existing user
        echo "[INFO] Setting password for user: $USERNAME"
        echo "$USERNAME:$USER_PASSWORD" | chpasswd || log_error "Failed to set password for user $USERNAME."

        # Configure sudo privileges
        echo "[INFO] Configuring sudo privileges for $USERNAME"
        echo "$USERNAME   ALL=(ALL)  NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME" || log_error "Failed to configure sudo privileges for $USERNAME."
        chmod 440 "/etc/sudoers.d/$USERNAME" || log_error "Failed to set permissions on /etc/sudoers.d/$USERNAME."
    fi
done

# Add a restricted user "bpouser" with limited privileges

if ! id "bpouser" &>/dev/null; then
    echo "[INFO] Adding new user: bpouser"
    useradd -m -k /etc/skel  -s /bin/bash  -c "bpouser" "bpouser" || echo "[ERROR] Failed to create user $USERNAME."
    echo "bpouser:bpouser" | chpasswd || echo "[ERROR] Failed to set password for user $USERNAME."
    chage -d 0 "bpouser" || log_error "Failed to set password for user $USERNAME."
    echo "bpouser ALL=(ALL) NOPASSWD: /sbin/shutdown" > /etc/sudoers.d/bpouser || echo "[ERROR] Failed to set password for user $USERNAME."
fi

# Delete the script itself
SCRIPT_NAME="$0"
echo "[INFO] Deleting the script: $SCRIPT_NAME"
rm -- "$SCRIPT_NAME" || log_error "Failed to delete the script."

echo "[INFO] Script executed and deleted successfully."
