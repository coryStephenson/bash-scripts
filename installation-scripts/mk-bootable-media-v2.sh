#!/usr/bin/env bash
set -Eeuo pipefail

DEFAULT_ISO_DIR="${HOME}/iso-files"
CURRENT_DOWNLOAD=""

quit_script() {
  printf '\nQuitting.\n'
  exit 0
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run_as_root() {
  if (( EUID == 0 )); then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Root privileges are required for: $*"
  fi
}

cleanup_download() {
  local exit_code=$?
  if (( exit_code != 0 )) && [[ -n "${CURRENT_DOWNLOAD}" && -e "${CURRENT_DOWNLOAD}" ]]; then
    printf '\nInterrupted. Removing partial download: %s\n' "$CURRENT_DOWNLOAD"
    rm -f -- "$CURRENT_DOWNLOAD"
  fi
  exit "$exit_code"
}

trap cleanup_download ERR INT TERM

pause() {
  read -rp $'\nPress Enter to continue... ' _
}

confirm() {
  local reply
  read -rp "$1 [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

choose_downloader() {
  for cmd in curl wget axel; do
    command -v "$cmd" >/dev/null 2>&1 && {
      printf '%s\n' "$cmd"
      return 0
    }
  done
  return 1
}

download_iso() {
  local destination url detected_name iso_name output downloader

  read -rp "Download directory [${DEFAULT_ISO_DIR}]: " destination
  destination=${destination:-$DEFAULT_ISO_DIR}
  mkdir -p -- "$destination"

  read -rp 'ISO URL: ' url
  [[ -n "$url" ]] || die 'An ISO URL is required.'

  detected_name=${url##*/}
  detected_name=${detected_name%%\?*}
  read -rp "Filename [${detected_name}]: " iso_name
  iso_name=${iso_name:-$detected_name}
  [[ -n "$iso_name" ]] || die 'A filename is required.'

  output="${destination}/${iso_name}"
  if [[ -e "$output" ]]; then
    printf '\n%s already exists.\n' "$output"
    confirm 'Overwrite it?' || quit_script
    rm -f -- "$output"
  fi

  downloader=$(choose_downloader) || die 'Install curl, wget, or axel first.'
  CURRENT_DOWNLOAD="$output"

  printf '\nDownloading %s with %s...\n\n' "$iso_name" "$downloader"
  case "$downloader" in
    curl) curl -L --fail --progress-bar -o "$output" "$url" ;;
    wget) wget -O "$output" "$url" ;;
    axel) axel -o "$output" "$url" ;;
  esac

  CURRENT_DOWNLOAD=""
  printf '\nSaved to %s\n' "$output"
}

verify_checksum() {
  local file expected actual checksum_cmd

  read -rp 'Path to ISO/file: ' file
  [[ -f "$file" ]] || die "File not found: $file"

  printf '\n1) SHA256\n2) SHA512\n3) Return\n'
  read -rp 'Choose a checksum algorithm: ' checksum_cmd
  case "$checksum_cmd" in
    1) checksum_cmd='sha256sum' ;;
    2) checksum_cmd='sha512sum' ;;
    3) return 0 ;;
    *) die 'Invalid checksum selection.' ;;
  esac

  command -v "$checksum_cmd" >/dev/null 2>&1 || die "$checksum_cmd is not installed."
  read -rp 'Paste the expected checksum: ' expected
  expected=$(tr -d '[:space:]' <<<"$expected" | tr '[:upper:]' '[:lower:]')
  actual=$($checksum_cmd -- "$file" | awk '{print $1}')

  printf '\nExpected: %s\nActual:   %s\n' "$expected" "$actual"
  [[ "$actual" == "$expected" ]] \
    && printf 'Result: checksums match.\n' \
    || printf 'Result: checksums do not match.\n'
}

latest_iso() {
  find "$DEFAULT_ISO_DIR" -maxdepth 1 -type f \( -iname '*.iso' -o -iname '*.img' \) -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -n 1 \
    | cut -d' ' -f2-
}

show_disks() {
  printf '\nAvailable disks:\n'
  lsblk -dpno NAME,SIZE,TRAN,RM,TYPE,MODEL | awk '$5=="disk" {print}'
}

is_disk_device() {
  [[ -b "$1" ]] && [[ "$(lsblk -dnro TYPE "$1" 2>/dev/null)" == 'disk' ]]
}

root_disk() {
  local root_source parent
  root_source=$(findmnt -nro SOURCE / 2>/dev/null || true)
  [[ -n "$root_source" ]] || return 0
  parent=$(lsblk -ndo PKNAME "$root_source" 2>/dev/null || true)
  [[ -n "$parent" ]] && printf '/dev/%s\n' "$parent"
}

has_existing_data() {
  local device=$1
  wipefs -n "$device" 2>/dev/null | grep -q . && return 0
  lsblk -nrpo NAME,TYPE,FSTYPE,MOUNTPOINT "$device" | awk '
    NR > 1 && ($2 == "part" || $3 != "" || $4 != "") { found = 1 }
    END { exit found ? 0 : 1 }
  '
}

unmount_device() {
  local device=$1 entry mountpoint
  while read -r entry; do
    mountpoint=$(findmnt -nr -S "$entry" -o TARGET 2>/dev/null || true)
    [[ -n "$mountpoint" ]] && run_as_root umount "$entry"
  done < <(lsblk -nrpo NAME "$device")
}

maybe_wipe_device() {
  local device=$1
  if has_existing_data "$device"; then
    printf '\nWarning: %s appears to contain existing partitions, filesystems, or mounted data.\n' "$device"
    printf 'A secure wipe with /dev/urandom is recommended before writing the ISO.\n'
    confirm 'Continue with the secure wipe?' || quit_script
    unmount_device "$device"
    run_as_root dd if=/dev/urandom of="$device" bs=4M status=progress conv=fsync
    run_as_root sync
  fi
}

write_bootable_media() {
  local iso_file device default_iso removable system_disk

  default_iso=$(latest_iso || true)
  read -rp "ISO path${default_iso:+ [${default_iso}]}: " iso_file
  iso_file=${iso_file:-$default_iso}
  [[ -f "$iso_file" ]] || die "ISO not found: $iso_file"

  show_disks
  read -rp 'Target thumb drive (whole disk, e.g. /dev/sdb): ' device
  is_disk_device "$device" || die 'Choose a whole-disk block device, not a partition.'

  system_disk=$(root_disk || true)
  [[ "$device" != "$system_disk" ]] || die "Refusing to write to the system disk: $device"

  removable=$(lsblk -dnro RM "$device" 2>/dev/null || printf '0')
  if [[ "$removable" != '1' ]]; then
    printf '\nWarning: %s is not marked as removable.\n' "$device"
    confirm 'Write to it anyway?' || quit_script
  fi

  printf '\nAbout to write:\n  ISO:    %s\n  Device: %s\n' "$iso_file" "$device"
  confirm 'This will destroy data on the target device. Continue?' || quit_script

  maybe_wipe_device "$device"
  unmount_device "$device"
  run_as_root dd if="$iso_file" of="$device" bs=4M status=progress conv=fsync
  run_as_root sync
  printf '\nBootable media created successfully.\n'
}

main_menu() {
  while true; do
    printf '\nmk-bootable-media v2\n'
    printf '1) Download ISO\n2) Verify checksum\n3) Create bootable media\n4) Quit\n'
    read -rp 'Choose an option: ' choice
    case "$choice" in
      1) download_iso; pause ;;
      2) verify_checksum; pause ;;
      3) write_bootable_media; pause ;;
      4) quit_script ;;
      *) printf 'Invalid selection.\n' ;;
    esac
  done
}

main_menu
