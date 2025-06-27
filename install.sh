#!/bin/bash
set -e

# Update and install required packages
echo "Updating package lists and installing dependencies..."
sudo apt update
sudo apt install -y exfat-fuse exfatprogs ntfs-3g

echo "Installing USB auto-mount..."

# Copy scripts to /usr/local/bin
echo "Copying usb-mount.sh to /usr/local/bin/"
install -m 755 usb-mount.sh /usr/local/bin/usb-mount.sh

echo "Copying usb-umount.sh to /usr/local/bin/"
install -m 755 usb-umount.sh /usr/local/bin/usb-umount.sh

# Copy systemd service files
echo "Copying usb-mount@.service to /etc/systemd/system/"
install -m 644 usb-mount@.service /etc/systemd/system/usb-mount@.service

echo "Copying usb-umount@.service to /etc/systemd/system/"
install -m 644 usb-umount@.service /etc/systemd/system/usb-umount@.service

# Copy udev rules
echo "Copying 99-usb-mount.rules to /etc/udev/rules.d/99-usb-mount.rules"
install -m 644 99-usb-mount.rules /etc/udev/rules.d/99-usb-mount.rules

# Reload daemons
echo "Reloading systemd and udev rules..."
systemctl daemon-reexec
udevadm control --reload-rules
udevadm trigger

echo -e "\033[0;32mUSB auto-mount installed!\033[0m"
