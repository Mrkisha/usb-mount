#!/bin/bash
set -e

DEVICE="$1"
PART_NAME=$(basename "$DEVICE")
MOUNTPOINT="/media/$PART_NAME"

if mountpoint -q "$MOUNTPOINT"; then
    umount "$MOUNTPOINT"
    rmdir "$MOUNTPOINT"
    logger "[usb-umount] Unmounted $DEVICE from $MOUNTPOINT"
fi
