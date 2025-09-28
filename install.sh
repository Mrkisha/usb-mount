#!/bin/bash
set -e

MOUNT_USER="${MOUNT_USER:-1000}"
MOUNT_GROUP="${MOUNT_GROUP:-1000}"

# Update and install required packages
echo "Updating package lists and installing dependencies..."
sudo apt update
sudo apt install -y exfat-fuse exfatprogs ntfs-3g

echo "Installing USB auto-mount..."

# Copy scripts to /usr/local/bin
echo "Copying usb-mount.sh to /usr/local/bin/"
sudo install -m 755 usb-mount.sh /usr/local/bin/usb-mount.sh

echo "Copying usb-umount.sh to /usr/local/bin/"
sudo install -m 755 usb-umount.sh /usr/local/bin/usb-umount.sh

# Copy systemd service files
echo "Copying usb-mount@.service to /etc/systemd/system/"
sudo install -m 644 usb-mount@.service /etc/systemd/system/usb-mount@.service

echo "Copying usb-umount@.service to /etc/systemd/system/"
sudo install -m 644 usb-umount@.service /etc/systemd/system/usb-umount@.service

# Copy udev rules
echo "Copying 99-usb-mount.rules to /etc/udev/rules.d/99-usb-mount.rules"
sudo install -m 644 99-usb-mount.rules /etc/udev/rules.d/99-usb-mount.rules

# Ensure shared group exists ---
# SHARED_GROUP="${SHARED_GROUP:-sharedmedia}"

# if ! getent group "$SHARED_GROUP" > /dev/null; then
#     echo -t usb "Group $SHARED_GROUP not found, creating..."
#     sudo groupadd --system "$SHARED_GROUP"
#     echo -t usb "Group $SHARED_GROUP created"
# fi

# sudo usermod -aG $SHARED_GROUP $USER
# echo -e "\033[0;33mAdded user '$USER' to group '$SHARED_GROUP'.\033[0m"

if ! getent passwd 82 > /dev/null; then
  sudo useradd -u 82 www-data-nextcloud --system --no-create-home --shell /usr/sbin/nologin
fi

# Add user 82 to the mount group so Docker container can access USB files
if getent group "$MOUNT_GROUP" > /dev/null; then
    USER_82_NAME=$(getent passwd 82 | cut -d: -f1)
    sudo usermod -aG "$MOUNT_GROUP" "$USER_82_NAME"
    echo -e "\033[0;33mAdded user 82 ($USER_82_NAME) to group '$MOUNT_GROUP' for Docker container access\033[0m"
else
    echo -e "\033[0;31mWarning: Group '$MOUNT_GROUP' doesn't exist. Docker container may not have proper permissions.\033[0m"
fi

echo "Add usb-mount env file"
sudo tee /etc/usb-mount.env > /dev/null <<EOF
# USB Mount Environment Variables
MOUNT_USER=$MOUNT_USER
MOUNT_GROUP=$MOUNT_GROUP
EOF

# sudo usermod -aG $SHARED_GROUP www-data-nextcloud
# echo -e "\033[0;33mAdded user 'www-data-nextcloud' to group '$SHARED_GROUP'.\033[0m"

# Reload daemons
echo "Reloading systemd and udev rules..."
sudo systemctl daemon-reexec
sudo udevadm control --reload-rules
sudo udevadm trigger

echo -e "\033[0;32mUSB auto-mount installed!\033[0m"
