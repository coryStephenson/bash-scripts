#!/usr/bin/env bash
set -euo pipefail

# This script reports all installed packages on a Debian-based system
# from multiple sources:
# - apt/dpkg managed packages
# - .deb installations (via dpkg)
# - Snap, Flatpak
# - AppImages (not managed by a package manager)

cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_section_header() {
  local title="$1"
  echo
  printf '=== %s ===\n' "$title"
}

collect_dpkg_packages() {
  if ! cmd_exists dpkg-query; then
    echo 'Error: dpkg-query not found.' >&2
    return 1
  fi
  dpkg-query -W -f='${Package}\t\t\t\t\t${Version}\n' | sort -k1
}

collect_apt_manual() {
  if ! cmd_exists apt-mark; then
    echo
    return 0
  fi
  # apt-mark showmanual lists packages installed explicitly via apt (and not as a dependency)
  apt-mark showmanual 2>/dev/null | sort
}

collect_snap_packages() {
  # Checks for non-existence of snap command
  if ! cmd_exists snap; then
    echo
    return 0
  fi
  
  # Checks for existence of errors, existence of snaps, or non-existence of snaps
  if snap list 2>/dev/null | head -n1 >/dev/null 2>&1; then
    snap list | sed '1d' | sort
  elif snap list; then
    snap list
    return 0
  else
    echo 'No snaps installed or snapd inaccessible'
  fi
}

collect_flatpak_packages() {
  if ! cmd_exists flatpak; then
    echo
    return 0
  fi
  printf '\nFlatpak apps:\n\n'
  flatpak list --app 2>/dev/null | sort || true
  printf '\nFlatpak runtimes:\n\n'
  flatpak list --runtime 2>/dev/null | sort || true
}

main() {
  print_section_header 'DPKG/apt installed packages'
  collect_dpkg_packages || true

  print_section_header 'Manually installed via apt (apt-mark showmanual)'
  collect_apt_manual || true

  print_section_header 'Snap packages'
  collect_snap_packages || true

  print_section_header 'Flatpak packages'
  collect_flatpak_packages || true
}

# Run
main "$@"

