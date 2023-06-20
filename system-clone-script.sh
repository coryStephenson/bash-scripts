#!/bin/bash

# Source disk or partition to be cloned
source_disk="/dev/sda"

# Target disk or partition to create the clone
target_disk="/dev/sdb"

# Confirm source and target disks
echo "Source disk: $source_disk"
echo "Target disk: $target_disk"
read -p "Do you want to continue? (y/n): " choice
if [[ ! "$choice" =~ ^[Yy]$ ]]; then
  echo "Aborted by user."
  exit 1
fi

# Perform system clone
echo "Performing system clone..."

# Create a partition table on the target disk (optional)
# Uncomment the following line if the target disk needs a partition table
# parted $target_disk mklabel gpt

# Create an image of the source disk or partition
dd if=$source_disk of=system_clone.img bs=4M status=progress

# Restore the image to the target disk or partition
dd if=system_clone.img of=$target_disk bs=4M status=progress

# Update the target disk's partition table (optional)
# Uncomment the following line if the target disk's partition table needs updating
# partprobe $target_disk

# Clean up the image file
rm system_clone.img

echo "System clone completed!"
