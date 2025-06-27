#!/bin/bash
set -e

DEVICE="$1"
PART_NAME=$(basename "$DEVICE")
MOUNTPOINT="/media/$PART_NAME"
SHARED_GROUP="${SHARED_GROUP:-sharedmedia}"

SHARED_GID=$(getent group "$SHARED_GROUP" | cut -d: -f3)

# Get partition type GUID (GPT)
PART_TYPE=$(lsblk -no PARTTYPE "$DEVICE" 2>/dev/null || echo "")
logger -t usb "Usb PART_TYPE: $PART_TYPE"

PART_TYPE_LOWER=$(echo "$PART_TYPE" | tr 'A-Z' 'a-z')
logger -t usb "Usb PART_TYPE_LOWER: $PART_TYPE_LOWER"

# Get filesystem type
FSTYPE=$(blkid -s TYPE -o value "$DEVICE" || echo "")

logger -t usb "Usb FSTYPE: $FSTYPE"

# Get label
LABEL=$(blkid -s LABEL -o value "$DEVICE" || echo "")

logger -t usb "Usb LABEL: $LABEL"

# List of partition types to skip (common boot/system partitions)
SKIP_TYPES=(
  "c12a7328-f81f-11d2-ba4b-00a0c93ec93b"  # EFI System Partition
  "e3c9e316-0b5c-4db8-817d-f92df00215ae"  # Microsoft Reserved Partition
  "de94bba4-06d1-4d40-a16a-bfd50179d6ac"  # Windows Recovery Environment
  "21686148-6449-6e6f-744e-656564454649"  # BIOS Boot Partition
)

# Filesystem types to skip
SKIP_FS=(
  "swap"
  "crypto_LUKS"
)

# Labels to skip
SKIP_LABELS=(
  "bootfs"
  "system-boot"
)

# Skip by partition type
for skip in "${SKIP_TYPES[@]}"; do
  if [[ "$PART_TYPE_LOWER" == "$skip" ]]; then
    logger -t usb "Skipping partition $DEVICE due to partition type $PART_TYPE"
    exit 0
  fi
done

# Skip by filesystem type
for skipfs in "${SKIP_FS[@]}"; do
  if [[ "$FSTYPE" == "$skipfs" ]]; then
    logger -t usb "Skipping partition $DEVICE due to filesystem $FSTYPE"
    exit 0
  fi
done

# Skip by label
for skiplabel in "${SKIP_LABELS[@]}"; do
  if [[ "$LABEL" == "$skiplabel" ]]; then
    logger -t usb "Skipping partition $DEVICE due to label $LABEL"
    exit 0
  fi
done

mkdir -p "$MOUNTPOINT"

# Mount with group access
mount -o uid=1000,gid="$SHARED_GID",umask=0002 "$DEVICE" "$MOUNTPOINT"
logger -t usb "Mounted $DEVICE to $MOUNTPOINT"

# Set group and permissions
chgrp -R "$SHARED_GROUP" "$MOUNTPOINT"
chmod -R 2775 "$MOUNTPOINT"
logger -t usb "Set group ownership to $SHARED_GROUP and permissions on $MOUNTPOINT"
