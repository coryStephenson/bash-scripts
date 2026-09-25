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
if [[ $# -ne 0 ]]; then
   echo "Error: This script must be run with no arguments"
   exit 1
fi

DEVICE="/dev/sdb"
LABEL="storage"

# Invoke wiper function
wiper

# Call parted.sh (partitions disk)
./parted.sh -d /dev/sdb -l gpt -f ntfs -n "storage"

# Validate device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device"
    exit 1
fi

# Check if partition satisfies the alignment constraint of type.  type must be "minimal" or "optimal".
parted -s "$DEVICE" align-check optimal 1

# Wait for kernel to update partition table
sleep 2
partprobe "$DEVICE"     # informs the OS of partition table changes
sleep 1

# Prints fields like: partition number:start:end:size:filesystem:name:flags;
$(parted -m -s "$DEVICE" print | awk)

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
