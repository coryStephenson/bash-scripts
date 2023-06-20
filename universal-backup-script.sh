#!/bin/bash

# Backup directory
backup_dir="/path/to/backup/dir"

# Select statement for backup type
PS3="Select backup type: "
options=("Full Backup" "Incremental Backup" "Differential Backup" "Mirror Backup" "Quit")

# Function for full backup
full_backup() {
  echo "Performing Full Backup..."
  # Add your logic for performing full backup here
  echo "Full Backup completed!"
}

# Function for incremental backup
incremental_backup() {
  echo "Performing Incremental Backup..."
  # Add your logic for performing incremental backup here
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
