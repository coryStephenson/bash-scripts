#!/usr/bin/env bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (use sudo)."
    exit 1
fi

# Check if a device argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 /dev/sdX"
    echo "Replace /dev/sdX with the actual device name (e.g., /dev/sda)"
    exit 1
fi

DEVICE="$1"

parted --script "$DEVICE" print | grep -oP '^\s*\d+' | while read PART_NUM; do
    parted --script "$DEVICE rm "$PART_NUM"
done

echo "All partitions have been deleted on $DEVICE."

# Confirm with the user before proceeding
echo "WARNING: This will delete all partitions on the device $DEVICE!"
read -p "Do you want to continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Run parted to create a new partition table and partition
parted --script "$DEVICE" mklabel msdos
parted --script "$DEVICE" mkpart primary fat32 1MiB 100%
parted --script "$DEVICE" name 1 MULTIBOOT

# Format the partition as FAT32
mkfs.fat -F 32 "${DEVICE}1"

# Done
echo "Partitioning and formatting complete. The partition has been named 'MULTIBOOT'."
