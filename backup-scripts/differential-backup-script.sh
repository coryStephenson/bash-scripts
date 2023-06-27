#!/bin/bash

# Source directory to be backed up
source_dir="/path/to/source"

# Destination directory to store the backup
backup_dir="/path/to/backup"

# Directory to store the previous backup
prev_backup_dir="/path/to/previous/backup"

# Perform differential backup
echo "Performing Differential Backup..."

# Find files that have been modified or added since last backup
find "$source_dir" -type f -newer "$prev_backup_dir" -exec cp --parents {} "$backup_dir" \;

echo "Differential Backup completed!"
