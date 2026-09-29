#!/usr/bin/env bash

echo -e "\n\n****************************************************************************************\n
Name of Script: $0\n
Author: Cory Stephenson\n
Format block devices\n
Tasks:\n
1) Initialize variables with desired values\n
2) Unmount any mounted partitions on the device\n
3) Display partition information\n
4) If partition exists, remove it, and then partition device afterwards. Otherwise, partition the device\n
5) Wiper function, meant to remove existing partition table and filesystem signatures, remains unused.\n
6) Validate that device exists as expected following the partitioning process\n
7) Check if partition satisfies the alignment constraint of type (optimal).\n
8) Wait for kernel to update partition table (invoking partprobe). Maybe update /etc/fstab.\n
9) 3 LOCs parse the output of the parted command on ~line 103 into separate variables\n
10) Display info about new partition\n
11) Make the actual filesystem\n
********************************************************************************************\n\n"

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
FS_TYPE="ext4"
NAME="storage"
ALIGNMENT="optimal"

# Unmount any mounted partitions on the device
echo "Unmounting any mounted partitions..."
umount ${DEVICE}* 2>/dev/null || true

# Display partition information
echo ""
echo "Partition table:"
sfdisk -l "$DEVICE"

if [ $? -ne 0 ]; then
    # Call parted.sh (partitions disk)
    ./parted.sh -d "$DEVICE" -l "$PART_TABLE" -f "$FS_TYPE" -n "$NAME"
else
    # Remove partition
    parted -s "$DEVICE" rm 1

    # Call parted.sh (partitions disk)
    ./parted.sh -d "$DEVICE" -l "$PART_TABLE" -f "$FS_TYPE" -n "$NAME"
fi



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

# Invoke wiper function (not sure what this function does yet after first test)
#wiper

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

# The next 3 LOCs parse the output of the parted command on line 70 into separate variables
PART_LINE=$(parted -m -s "$DEVICE" print | awk -F: '$1 ~ /^[0-9]+$/ {line=$0} END{print line}')

IFS=: read -r NEW_PART_NUM NEW_PART_START NEW_PART_END NEW_PART_SIZE NEW_PART_FS NEW_PART_NAME NEW_PART_FLAGS <<< "$PART_LINE"

# Strip the trailing semicolon from the flags field
NEW_PART_FLAGS="${NEW_PART_FLAGS%;}"

echo -e "\n\nDone! Disk formatted successfully.\n\n"
echo "Partition: $NEW_PART_NUM"
echo "Start: $NEW_PART_START"
echo "End: $NEW_PART_END"
echo "Size of partition: $NEW_PART_SIZE"
echo "Filesystem: $NEW_PART_FS"
[ -n "$NEW_PART_NAME" ] && echo "Name: $NEW_PART_NAME"
echo -e "Flags: $NEW_PART_FLAGS\n\n"

# Source: https://wiki.archlinux.org/title/Parted
# fs-type is an identifier chosen among those listed by entering help mkpart as the 
# closest match to the file system that you will use. The mkpart command does not 
# actually create the file system: the fs-type parameter will simply be used by 
# parted to set partition type GUID for GPT partitions or partition type ID for MBR partitions. 

# The actual filesystem itself must still be made

# Concatenate DEVICE and NEW_PART_NUM into single variable using the append operator (+=)
DEVICE+="$NEW_PART_NUM"

# Make filesystem
echo "There are a few different options when it comes to making the filesystem."
echo -n "Is this device a thumb drive, or a more massive drive? "
read DRIVE

if [ "$DRIVE" != "massive" ]; then

    if [ "$FS_TYPE" = "ntfs" ]; then
        mkfs."$FS_TYPE" -f -L "$NAME" "$DEVICE"
    else
        mkfs."$FS_TYPE" -E nodiscard,lazy_itable_init=1,lazy_journal_init=1 "$DEVICE"
        exit 0
    fi

else

    if [ "$FS_TYPE" = "ntfs" ]; then
        mkfs."$FS_TYPE" -f -L "$NAME" "$DEVICE"
    else
        mkfs."$FS_TYPE" -E nodiscard -T largefile4 -m 0 "$DEVICE"
        exit 0

fi

mkfs."$FS_TYPE" -f -L "$NAME" "$DEVICE"
