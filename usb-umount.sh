#!/bin/bash
set -e

DEVICE="$1"
PART_NAME=$(basename "$DEVICE")

STATE_DIR="${USB_MOUNT_STATE_DIR:-/run/usb-mount}"
HOOK_DIR="${USB_UMOUNT_HOOK_DIR:-/etc/usb-mount/pre-umount.d}"
STATE_FILE="$STATE_DIR/$PART_NAME.env"

MOUNTPOINT=""
UUID=""
LABEL=""
FSTYPE=""

# Preferred source of truth is the state file written at mount time: on removal
# the device node /dev/$PART_NAME is already gone and cannot be queried.
if [ -f "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    . "$STATE_FILE"
fi

# Fallback 1: the (usually still-present) stale entry in /proc/mounts.
if [ -z "$MOUNTPOINT" ]; then
    MOUNTPOINT=$(awk -v dev="$DEVICE" '$1 == dev {print $2}' /proc/mounts | head -n1)
fi

# Fallback 2: the legacy device-name mountpoint.
[ -z "$MOUNTPOINT" ] && MOUNTPOINT="/media/$PART_NAME"

# Run pre-umount hooks BEFORE unmounting, while the mountpoint still resolves
# (e.g. deregister the drive from Nextcloud external storage). Hooks must never
# block the unmount, so their errors are logged and ignored.
if [ -d "$HOOK_DIR" ]; then
    for hook in "$HOOK_DIR"/*; do
        [ -x "$hook" ] || continue
        logger -t usb "Running pre-umount hook $hook"
        DEVICE="$DEVICE" PART_NAME="$PART_NAME" MOUNTPOINT="$MOUNTPOINT" \
            UUID="$UUID" LABEL="$LABEL" FSTYPE="$FSTYPE" \
            "$hook" >/dev/null 2>&1 \
            || logger -t usb "Pre-umount hook $hook failed (ignored)"
    done
fi

# Lazy unmount so a busy filesystem (open handles) still detaches.
if mountpoint -q "$MOUNTPOINT"; then
    umount -l "$MOUNTPOINT" 2>/dev/null || umount -f "$MOUNTPOINT" 2>/dev/null || true
    logger -t usb "[usb-umount] Unmounted $DEVICE from $MOUNTPOINT"
fi

# Remove the now-empty mountpoint directory so a re-plug cannot land on a new
# name (the original bug: leftover /media/sda1 forced the next disk to sdb1).
if [ -d "$MOUNTPOINT" ]; then
    rmdir "$MOUNTPOINT" 2>/dev/null \
        && logger -t usb "[usb-umount] Removed mountpoint $MOUNTPOINT" \
        || logger -t usb "[usb-umount] Could not remove $MOUNTPOINT (not empty?)"
fi

rm -f "$STATE_FILE"
