# USB Mount

This project provides scripts and configuration to automatically mount and unmount USB drives on Debian-like systems, including Raspberry Pi OS. It is intended for headless systems.

## Features

- Automatically mounts USB drives to `/media` when inserted.
- Automatically unmounts and cleans up when drives are removed.
- Skips mounting for system/boot partitions and swap.
- Sets mount permissions to the current user (UID 1000).
- Uses systemd and udev for robust, event-driven operation.

## Installation

Run the provided install script with root privileges:

```bash
sudo MOUNT_USER=<yourusername> MOUNT_GROUP=<yourgroupname> ./install.sh

# e.g. MOUNT_USER will be 1000 by default
sudo MOUNT_GROUP=www-data-nextcloud ./install.sh
```

This will:
- Install required packages (`exfat-fuse`, `exfat-utils`, `ntfs-3g`)
- Copy scripts to `/usr/local/bin`
- Install systemd service files
- Install udev rules
- Reload systemd and udev

## Uninstallation

To remove all installed files and rules, run:

```bash
sudo ./uninstall.sh
```

## How it works

- `usb-mount.sh` and `usb-umount.sh`: Handle mounting and unmounting logic.
- `usb-mount@.service` and `usb-umount@.service`: systemd service templates triggered by udev.
- `99-usb-mount.rules`: udev rules to start the appropriate service on USB add/remove.

## Debug

Check logs for USB events and mount actions:

```bash
journalctl -t usb -n 20 --no-pager
```

## Tested

Tested with Raspberry Pi OS.

Inspired by [usbmount](https://github.com/rbrito/usbmount/blob/master/usbmount).
