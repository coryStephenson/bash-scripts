#!/bin/bash

# Source directory to be backed up
source_dir="/path/to/source"

# Destination directory to store the backup
backup_dir="/path/to/backup"

# Perform mirror backup
echo "Performing Mirror Backup..."

# Use rsync to create an exact replica of the source directory in the backup directory
rsync -avz --delete "$source_dir/" "$backup_dir/"

echo "Mirror Backup completed!"
