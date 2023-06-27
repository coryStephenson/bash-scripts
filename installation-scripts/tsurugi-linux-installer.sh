#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Download Tsurugi Linux ISO
wget https://tsurugi-linux.org/downloads/tsurugi-2021.1-amd64.iso

# Verify checksum
wget https://tsurugi-linux.org/downloads/tsurugi-2021.1-amd64.iso.sha256
sha256sum -c tsurugi-2021.1-amd64.iso.sha256

# Mount ISO
mkdir /mnt/tsurugi
mount -o loop tsurugi-2021.1-amd64.iso /mnt/tsurugi

# Install Tsurugi Linux
/mnt/tsurugi/install.sh

# Clean up
umount /mnt/tsurugi
rm -rf tsurugi-2021.1-amd64.iso tsurugi-2021.1-amd64.iso.sha256
