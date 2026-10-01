#!/bin/bash

# the set command is used to set or unset certain flags or settings within the shell environment
# set -o is used to specify option names
# errexit tells the shell to exit the script immediately if a command exits with a non-zero status
# nounset tells the shell to treat unset variables as an error when substituting
# pipefail says the return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if no command exited with a non-zero status
# For more info on these options and more, type 'help set' at the terminal prompt

set -o errexit
set -o nounset
set -o pipefail


# Select statement for backup type
PS3="Select backup type: "
options=("Full Backup" "Incremental Backup" "Differential Backup" "Mirror Backup" "Quit")

# Function for full backup
full_backup() {
  echo "Performing Full Backup..."
  # Source directory to be backed up
      source_dir="/path/to/source"

  # Destination directory to store the backup
      backup_dir="/path/to/backup"

  # Perform full backup
      echo "Performing Full Backup..."
          rsync -avz --delete "$source_dir/" "$backup_dir/"
      echo "Full Backup completed!"
}

# Function for incremental backup
incremental_backup() {
# Backup strategy and implementation found at: https://linuxconfig.org/how-to-create-incremental-backups-using-rsync-on-linux

echo "Performing Incremental Backup..."
  
# You cannot change the value of readonly variables
readonly SOURCE_DIR="${HOME}"
readonly BACKUP_DIR="/mnt/data/backups"
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_PATH="${BACKUP_DIR}/inc_${DATETIME}"
readonly LATEST_LINK="${BACKUP_DIR}/latest"

# make directory, including parents
mkdir -p "${BACKUP_DIR}"

# remote sync - archive mode, increase verbosity
# --delete says delete extraneous files from destination directory
# --exclude says to exclude files
rsync -av --delete \
  "${SOURCE_DIR}/" \
  --link-dest="${LATEST_LINK}" \
  --exclude=".cache" \
  "${BACKUP_PATH}"

# Remove soft link that points to previous backup
rm -rf "${LATEST_LINK}"

# Create another soft link with the same name that points to the latest backup
ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
  echo "Incremental Backup completed!"
}

# Function for differential backup
differential_backup() {
  echo "Performing Differential Backup..."
  # Add your logic for performing differential backup here
  echo "Differential Backup completed!"
}

# Function for mirror backup
mirror_backup() {
  echo "Performing Mirror Backup..."
  # Add your logic for performing mirror backup here
  echo "Mirror Backup completed!"
}

# Loop for user input
while true; do
  select opt in "${options[@]}"; do
    case $REPLY in
      1) full_backup ;;
      2) incremental_backup ;;
      3) differential_backup ;;
      4) mirror_backup ;;
      5) echo "Quitting..." ; exit ;;
      *) echo "Invalid option. Please select a valid option." ;;
    esac
    break
  done
done
