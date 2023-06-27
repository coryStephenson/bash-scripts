#!/bin/bash

# Source directory to be backed up
source_dir="/path/to/source"

# Destination directory to store the backup
backup_dir="/path/to/backup"

# Directory to store the previous backup
prev_backup_dir="/path/to/previous/backup"

# Perform incremental backup
echo "Performing Incremental Backup..."

# Create a temporary directory to stage the changes
tmp_dir=$(mktemp -d)

# Use rsync to copy modified or added files to the temporary directory
rsync -avz --update --delete --exclude-from="$prev_backup_dir/exclude.txt" \
      "$source_dir/" "$tmp_dir/"

# Use cp to update the previous backup with the changes in the temporary directory
cp -r --preserve=timestamps --attributes-only "$tmp_dir/" "$prev_backup_dir/"

# Use rsync to copy the changes from the temporary directory to the backup directory
rsync -avz --delete "$tmp_dir/" "$backup_dir/"

# Remove the temporary directory
rm -rf "$tmp_dir"

echo "Incremental Backup completed!"
