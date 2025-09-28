#!/bin/bash
set -e

echo "Uninstalling USB auto-mount..."

# Remove files
echo "Removing /usr/local/bin/usb-mount.sh"
rm -f /usr/local/bin/usb-mount.sh

echo "Removing /usr/local/bin/usb-umount.sh"
rm -f /usr/local/bin/usb-umount.sh

echo "Removing /etc/systemd/system/usb-mount@.service"
rm -f /etc/systemd/system/usb-mount@.service

echo "Removing /etc/systemd/system/usb-umount@.service"
rm -f /etc/systemd/system/usb-umount@.service

echo "Removing /etc/udev/rules.d/99-usb-mount.rules"
rm -f /etc/udev/rules.d/99-usb-mount.rules

echo "Removing /etc/usb-mount.env"
rm -f /etc/usb-mount.env

# Reload daemons
echo "Reloading systemd and udev rules..."
systemctl daemon-reexec
udevadm control --reload-rules
udevadm trigger

echo -e "\033[0;32mUSB auto-mount uninstalled!\033[0m"
