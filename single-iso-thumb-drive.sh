#!/bin/bash

# Specify the path to the .iso file and the thumb drive device name
ISO_FILE_PATH="/path/to/security-onion.iso"
THUMB_DRIVE="/dev/sdX"

# Unmount the thumb drive if it is already mounted
umount "$THUMB_DRIVE"* 2>/dev/null

# Write the .iso file onto the thumb drive
dd if="$ISO_FILE_PATH" of="$THUMB_DRIVE" bs=4M status=progress

# Create an ext4 filesystem on the thumb drive
mkfs.ext4 "$THUMB_DRIVE"1

# Mount the thumb drive
mount "$THUMB_DRIVE"1 /mnt

# Add an entry to /etc/fstab to mount the thumb drive at boot
echo "$THUMB_DRIVE"1 /mnt ext4 defaults 0 0 >> /etc/fstab

# Change ownership of the mounted thumb drive to the current user
chown -R $(whoami):$(whoami) /mnt

# Unmount the thumb drive
umount /mnt

echo "Security Onion .iso image has been successfully written to the thumb drive with an ext4 filesystem."
