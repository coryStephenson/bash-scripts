#!/usr/bin/env bash

# Prompt user for device path
read -p "Enter the device path (e.g., /dev/sdb1): " DEVICE

# Validate input is not empty
if [ -z "$DEVICE" ]; then
    echo "Error: No device path provided."
    exit 1
fi

# Extract the basename (e.g., sdb1 from /dev/sdb1)
BASE=$(basename "$DEVICE")

# Check if the partition exists in lsblk output
if lsblk -no NAME,TYPE | awk -v dev="$BASE" '$1==dev && $2=="part"{found=1; exit} END{exit !found}'; then
    echo "Partition found: $DEVICE"
    echo "Device name: $BASE"

    # Get additional info about the partition
    echo -e "\nPartition details:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep "^$BASE"
else
    echo "Error: $DEVICE is not a valid partition or does not exist."
    exit 1
fi

# Save to variable for later use
PARTITION="$DEVICE"
echo -e "\nSaved to variable PARTITION: $PARTITION"




