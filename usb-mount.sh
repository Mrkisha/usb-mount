#!/bin/bash
set -e

DEVICE="$1"
PART_NAME=$(basename "$DEVICE")

# Use environment variables with defaults
MOUNT_USER="${MOUNT_USER:-1000}"
MOUNT_GROUP="${MOUNT_GROUP:-1000}"

MOUNTPOINT_ROOT="${MOUNTPOINT_ROOT:-/media}"
MOUNTPOINT_ROOT_CHANGE_OWNERSHIP="${MOUNTPOINT_ROOT_CHANGE_OWNERSHIP:-false}"
MOUNTPOINT="$MOUNTPOINT_ROOT/$PART_NAME"

logger -t usb "Usb mounted user: $MOUNT_USER"
logger -t usb "Usb mounted group: $MOUNT_GROUP"

# Convert user/group names to IDs if needed
if [[ "$MOUNT_USER" =~ ^[0-9]+$ ]]; then
    MOUNT_UID="$MOUNT_USER"
else
    MOUNT_UID=$(id -u "$MOUNT_USER" 2>/dev/null) || {
        echo "Error: User '$MOUNT_USER' not found"
        exit 1
    }
fi

if [[ "$MOUNT_GROUP" =~ ^[0-9]+$ ]]; then
    MOUNT_GID="$MOUNT_GROUP"
else
    MOUNT_GID=$(getent group "$MOUNT_GROUP" | cut -d: -f3 2>/dev/null) || {
        echo "Error: Group '$MOUNT_GROUP' not found"
        exit 1
    }
fi

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

# ======
# Mount with group access
# mount -o uid=82,gid=82,fmask=0027,dmask=0027 "$DEVICE" "$MOUNTPOINT"
# logger -t usb "Mounted $DEVICE to $MOUNTPOINT"

# # Set group and permissions
# chown -R 82:82 "$MOUNTPOINT"
# ======

# Mount with user and group access
mount -o "uid=$MOUNT_UID,gid=$MOUNT_GID,fmask=0117,dmask=0007" "$DEVICE" "$MOUNTPOINT"
logger -t usb "Mounted $DEVICE to $MOUNTPOINT with uid=$MOUNT_UID, gid=$MOUNT_GID (user: $MOUNT_USER, group: $MOUNT_GROUP)"

# Set ownership
chown -R "$MOUNT_UID:$MOUNT_GID" "$MOUNTPOINT"
logger -t usb "Set ownership to $MOUNT_USER:$MOUNT_GROUP ($MOUNT_UID:$MOUNT_GID) on $MOUNTPOINT"

if [ "$MOUNTPOINT_ROOT_CHANGE_OWNERSHIP" = "true" ]; then
    chown -R "$MOUNT_UID:$MOUNT_GID" "$MOUNTPOINT_ROOT"
    logger -t usb "Set ownership to $MOUNT_USER:$MOUNT_GROUP ($MOUNT_UID:$MOUNT_GID) on $MOUNTPOINT_ROOT"
fi

# chgrp -R "$SHARED_GROUP" "$MOUNTPOINT"
# chmod -R 2775 "$MOUNTPOINT"
# logger -t usb "Set group ownership to $SHARED_GROUP and permissions on $MOUNTPOINT"
