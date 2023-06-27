#!/bin/bash

# Define the thumb drive path
thumb_drive="/dev/sdX" # Change this to the actual path of your thumb drive

# Define the partitions
partitions=(
  "ubuntu"     # Ubuntu distribution
  "fedora"     # Fedora distribution
  "archlinux"  # Arch Linux distribution
)

# Loop through the partitions and create them
for partition in "${partitions[@]}"; do
  echo "Creating partition for $partition..."
  sudo parted "$thumb_drive" mkpart primary fat32 0% 100%
  sudo mkfs.vfat -F 32 "$thumb_drive""$partition"1
done

# Create mount points for the partitions
sudo mkdir /mnt/ubuntu
sudo mkdir /mnt/fedora
sudo mkdir /mnt/archlinux

# Mount the partitions
sudo mount "$thumb_drive"ubuntu1 /mnt/ubuntu
sudo mount "$thumb_drive"fedora1 /mnt/fedora
sudo mount "$thumb_drive"archlinux1 /mnt/archlinux

# Download and extract Ubuntu distribution
echo "Downloading Ubuntu distribution..."
sudo curl -L -o /tmp/ubuntu.iso "https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-desktop-amd64.iso"
echo "Extracting Ubuntu distribution..."
sudo bsdtar -xf /tmp/ubuntu.iso -C /mnt/ubuntu/

# Download and extract Fedora distribution
echo "Downloading Fedora distribution..."
sudo curl -L -o /tmp/fedora.iso "https://download.fedoraproject.org/pub/fedora/linux/releases/35/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-35-1.3.iso"
echo "Extracting Fedora distribution..."
sudo bsdtar -xf /tmp/fedora.iso -C /mnt/fedora/

# Download and extract Arch Linux distribution
echo "Downloading Arch Linux distribution..."
sudo curl -L -o /tmp/archlinux.tar.gz "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-bootstrap-2022.04.01-x86_64.tar.gz"
echo "Extracting Arch Linux distribution..."
sudo tar -xzf /tmp/archlinux.tar.gz -C /mnt/archlinux/

# Unmount the partitions
sudo umount /mnt/ubuntu
sudo umount /mnt/fedora
sudo umount /mnt/archlinux

echo "Multi-boot, multi-partition thumb drive creation completed!"
