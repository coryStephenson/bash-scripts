#! /usr/bin/env bash
set -euo pipefail
set -o errtrace

echo -e "\n\n*******************************************************************************************************\n
Name of Script: $0\n
Author: Cory Stephenson\n
View script for further description of tasks\n
Tasks:\n
1) Partition disk\n
2) Format disk\n
3) Run diagnostics on disk\n
4) Pad disk with data stream\n
5) Erase disk\n
6) Backup disk\n
7) Clone disk\n
8) Restore disk from backup\n
9) Display disk's free space info\n
10) Display disk's used space info\n
*******************************************************************************************************************\n\n"

#5) Erase disk by overwriting a disk with zeros
sudo dd if=/dev/zero of=/dev/sdX bs=1M status=progress

#5) Erase disk securely
sudo dd if=/dev/urandom of=/dev/sdX bs=4M status=progress

#6) Full backup of disk using rsync
# Source directory to be backed up
source_dir="/path/to/source"

# Destination directory to store the backup
backup_dir="/path/to/backup"

# Perform full backup
echo "Performing Full Backup..."
rsync -avz --delete "$source_dir/" "$backup_dir/"
echo "Full Backup completed!"
