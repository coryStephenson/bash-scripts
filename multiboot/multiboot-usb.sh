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

# Install GRUB on USB stick to make it bootable
mkdir -p /media/MULTIBOOT/boot

# MBR booting
grub-install --target=i386-pc --boot-directory=/media/MULTIBOOT/boot "$DEVICE"

# Create a GRUB configuration file to boot the distros on your hard drive
grub-mkconfig -o /media/MULTIBOOT/boot/grub/grub.cfg

# Remove everythin after the line that says ### END/etc/grub.d/00_header ###
sed '/### END/etc/grub.d/00_header ###/ q' /media/MULTIBOOT/boot/grub/grub.cfg

cat /media/MULTIBOOT/boot/grub/grub.cfg
sleep 10

FILE="/media/MULTIBOOT/boot/grub/grub.cfg"
cat <<EOL >> "$FILE"
submenu "Ubuntu 16.04" {
set isofile=/Ubuntu/ubuntu-1.04-desktop-amd64.iso
loopback loop $isofile
menuentry "Try Ubuntu 16.04 without installing" {
linux (loop)/casper/vmlinuz.efi file=/cdrom/preseed/
ubuntu.seed boot=casper iso-scan/filename=$isofile quiet
splash ---
initrd (loop)/casper/initrd.lz
}
menuentry "Install Ubuntu 16.04" {
linux (loop)/casper/vmlinuz.efi file=/cdrom/preseed/
ubuntu.seed boot=casper iso-scan/filename=$isofile only-
ubiquity quiet splash ---
  initrd (loop)/casper/initrd.lz
 }
}
EOL


# Create the Ubuntu directory on the drive and copy over the ISO file.
# Then unmount the drive and reboot from the stick. You should see a GRUB menu 
# with one entry for Ubuntu that opens up to reveal boot and install options.


# I have opted to download an .iso file directly to a specific directory on the stick instead
# Download .iso image

# 1) Read user input for directory variable DESTINATION
echo "Desired .iso download directory? (Please enter absolute path) "

read -r DESTINATION

# 2) Test directory variable non-existence && mkdir -p /media/MULTIBOOT/Ubuntu

if [[ ! -d "${DESTINATION}" ]]; then

echo -e "\n\n${DESTINATION} not found. Making directory ${DESTINATION}..."
mkdir -p /media/MULTIBOOT/Ubuntu

else 

echo -e "\n\n${DESTINATION} already exists. The file will be placed in ${DESTINATION}."

fi

catch() {
  exit_code="${1}"
  line_number="${2}"
  iso_name="${ISO_NAME}"
  echo -e "SIGINT: Exit code ${exit_code} at about line number ${line_number}.\n"
  echo -e "Removing ${iso_name}...\n"
  rm -rf "${ISO_NAME}"*
  echo -e "Exit code for .iso removal: $?"
}




