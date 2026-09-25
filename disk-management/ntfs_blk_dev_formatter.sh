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
PART_TABLE="gpt"
FS_TYPE="ntfs"
NAME="storage"
ALIGNMENT="optimal"

wiper() {

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
}

# Invoke wiper function
wiper

# Call parted.sh (partitions disk)
./parted.sh -d "$DEVICE" -l "$PART_TABLE" -f "$FS_TYPE" -n "$NAME"

# Validate device exists
if [ ! -b "$DEVICE" ]; then
    echo "Error: $DEVICE is not a valid block device"
    exit 1
fi

# Check if partition satisfies the alignment constraint of type.  type must be "minimal" or "optimal".
parted -s "$DEVICE" align-check "$ALIGNMENT" 1

# Wait for kernel to update partition table
sleep 2
partprobe "$DEVICE"     # informs the OS of partition table changes
sleep 1

# Lines 70-75 parse the output of the parted command on line 70 into separate variables
PART_LINE=$(parted -m -s "$DEVICE" print | awk -F: '$1 ~ /^[0-9]+$/ {line=$0} END{print line}')

IFS=: read -r NEW_PART_NUM NEW_PART_START NEW_PART_END NEW_PART_SIZE NEW_PART_FS NEW_PART_NAME NEW_PART_FLAGS <<< "$PART_LINE"

# Strip the trailing semicolon from the flags field
NEW_PART_FLAGS="${NEW_PART_FLAGS%;}"

echo "Done! Disk formatted successfully."
echo "Partition: $NEW_PART_NUM"
echo "Start: $NEW_PART_START"
echo "End: $NEW_PART_END"
echo "Size of partition: $NEW_PART_SIZE"
echo "Filesystem: $NEW_PART_FS"
[ -n "$NEW_PART_NAME" ] && echo "Name: $NEW_PART_NAME"
echo "Flags: $NEW_PART_FLAGS"

# Display partition information
echo ""
echo "Partition table:"
sfdisk -l "$DEVICE"
