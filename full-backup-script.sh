#!/bin/bash

# Source directory to be backed up
source_dir="/path/to/source"

# Destination directory to store the backup
backup_dir="/path/to/backup"

# Perform full backup
echo "Performing Full Backup..."
rsync -avz --delete "$source_dir/" "$backup_dir/"
echo "Full Backup completed!"
