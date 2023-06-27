#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Update package list
pacman -Syu --noconfirm

# Install required dependencies
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm blackarch-keyring

# Add BlackArch repository
echo "[blackarch]" >> /etc/pacman.conf
echo "Server = https://mirror.math.princeton.edu/pub/blackarch/\$repo/os/\$arch" >> /etc/pacman.conf

# Update package list again
pacman -Sy --noconfirm

# Install BlackArch base package group
pacman -S --noconfirm blackarch

# Install BlackArch categories (optional)
# Uncomment the categories you want to install

# pacstrap /path/to/chroot blackarch-anti-forensic
# pacstrap /path/to/chroot blackarch-automation
# pacstrap /path/to/chroot blackarch-backdoor
# pacstrap /path/to/chroot blackarch-binary
# pacstrap /path/to/chroot blackarch-bluetooth
# pacstrap /path/to/chroot blackarch-code-audit
# pacstrap /path/to/chroot blackarch-cracker
# pacstrap /path/to/chroot blackarch-crypto
# pacstrap /path/to/chroot blackarch-database
# pacstrap /path/to/chroot blackarch-debugger
# pacstrap /path/to/chroot blackarch-decompiler
# pacstrap /path/to/chroot blackarch-defensive
# pacstrap /path/to/chroot blackarch-disassembler
# pacstrap /path/to/chroot blackarch-dos
# pacstrap /path/to/chroot blackarch-drone
# pacstrap /path/to/chroot blackarch-fingerprint
# pacstrap /path/to/chroot blackarch-firewall
# pacstrap /path/to/chroot blackarch-firmware
# pacstrap /path/to/chroot blackarch-forensic
# pacstrap /path/to/chroot blackarch-fuzzer
# pacstrap /path/to/chroot blackarch-hardware
# pacstrap /path/to/chroot blackarch-honeypot
# pacstrap /path/to/chroot blackarch-ids
# pacstrap /path/to/chroot blackarch-impersonation
# pacstrap /path/to/chroot blackarch-ios
# pacstrap /path/to/chroot blackarch-keylogger
# pacstrap /path/to/chroot blackarch-malware
# pacstrap /path/to/chroot blackarch-misc
# pacstrap /path/to/chroot blackarch-mobile
# pacstrap /path/to/chroot blackarch-networking
# pacstrap /path/to/chroot blackarch-nfc
# pacstrap /path/to/chroot blackarch-orchestration
# pacstrap /path/to/chroot blackarch-osint
# pacstrap /path/to/chroot blackarch-packaging
# pacstrap /path/to/chroot blackarch-proxy
# pacstrap /path/to/chroot blackarch-radio
# pacstrap /path/to/chroot blackarch-recon
# pacstrap /path/to/chroot black
