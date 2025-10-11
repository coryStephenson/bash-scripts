#!/usr/bin/env bash

# Script to format a block device with GPT partition table and ntfs filesystem
# Usage: ./format_disk.sh /dev/sdX [label]

set -e  # Exit on error

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root" 
   exit 1
fi

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <device> [filesystem-label]"
    echo "Example: $0 /dev/sdb MyDisk"
    exit 1
fi

DEVICE=$1
LABEL=${2:-""}

# Validate device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device"
    exit 1
fi

# Warning prompt
echo "WARNING: This will DESTROY all data on $DEVICE"
echo -n "Are you sure you want to continue? (yes/no): "
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo "Starting disk formatting process..."

# Unmount any mounted partitions on this device
echo "Unmounting any mounted partitions..."
umount ${DEVICE}* 2>/dev/null || true

# Wipe existing partition table and filesystem signatures
    echo "Wiping existing signatures..."
    wipefs -a "$DEVICE"

echo "1) Create GPT partition table"
echo "2) Create MBR partition table"
read -p "Choose an option (1 or 2): " choice


if [[ $choice -eq 1 ]]; then
    # Create GPT partition table
    parted -s "$DEVICE" mklabel gpt

elif [[ $choice -eq 2 ]]; then
     # Create MBR partition table
    parted -s "$DEVICE" mklabel msdos
else
    echo "Invalid choice."
fi


# Wait for kernel to update partition table
sleep 2
partprobe "$DEVICE"
sleep 1

# Partition SSD
# Parameters: mkpart <name> <fs-type> <start> <end>
parted -s "$DEVICE" mklabel gpt
parted -s "$DEVICE" mkpart primary ntfs 1MiB 100%
parted -s "$DEVICE" align-check optimal 1

# Determine the partition device name
if [[ "$DEVICE" =~ nvme|mmcblk ]]; then
    PARTITION="${DEVICE}p1"
else
    PARTITION="${DEVICE}1"
fi

# Create ntfs filesystem
echo "Creating ntfs filesystem on ${PARTITION}..."
if [ -n "$LABEL" ]; then
    mkfs.ntfs -f -L "$LABEL" "$PARTITION"
else
    mkfs.ntfs -f "$PARTITION"
fi

# Wait for kernel to update partition table
sleep 2
partprobe "$DEVICE"
sleep 1

echo "Done! Disk formatted successfully."
echo "Partition: $PARTITION"
echo "Filesystem: ntfs"
[ -n "$LABEL" ] && echo "Label: $LABEL"

# Display partition information
echo ""
echo "Partition table:"
sfdisk -l "$DEVICE"
