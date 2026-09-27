#!/usr/bin/env bash
set -euo pipefail

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root" 
   exit 1
fi

usage() {
    cat >&2 <<EOF
Usage: $0 -d <device> -l <label-type> -f <fs-type> [-t <part-type>] [-n <name>]

Required:
  -d <device>      Block device (e.g. /dev/sdb)
  -l <label-type>  Disklabel type: aix, amiga, bsd, dvh, gpt, loop, mac, msdos, pc98, sun
  -f <fs-type>     Filesystem type: btrfs, ext2, ext3, ext4, fat16, fat32, hfs, hfs+,
                   linux-swap, ntfs, reiserfs, udf, xfs

Conditionally required (depends on -l):
  -t <part-type>   Partition type: primary, logical, extended
                   REQUIRED when -l is msdos or dvh.
                   NOT ALLOWED for any other disklabel type.

Optional:
  -n <name>        Partition name
                   ONLY ALLOWED when -l is mac, pc98, or gpt.
  -h               Show this help message
EOF
    exit 1
}

VALID_LABELS=(aix amiga bsd dvh gpt loop mac msdos pc98 sun)
VALID_PART_TYPES=(primary logical extended)
VALID_FS_TYPES=(btrfs ext2 ext3 ext4 fat16 fat32 hfs "hfs+" linux-swap ntfs reiserfs udf xfs)

# Labels that require/allow a part-type
PART_TYPE_LABELS=(msdos dvh)
# Labels that allow a partition name
NAME_LABELS=(mac pc98 gpt)

in_list() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [[ "$needle" == "$item" ]] && return 0
    done
    return 1
}

while getopts ":d:l:t:f:n:h" opt; do
    case "$opt" in
        d) DEVICE="$OPTARG" ;;
        l) LABEL_TYPE="$OPTARG" ;;
        t) PART_TYPE="$OPTARG" ;;
        f) FS_TYPE="$OPTARG" ;;
        n) PART_NAME="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument" >&2; usage ;;
    esac
done
shift $((OPTIND - 1))

# --- Required option checks ---
: "${DEVICE:?Error: device must be specified with -d}"
: "${LABEL_TYPE:?Error: disklabel type must be specified with -l}"
: "${FS_TYPE:?Error: filesystem type must be specified with -f}"

# --- Base value validation ---
if ! in_list "$LABEL_TYPE" "${VALID_LABELS[@]}"; then
    echo "Error: invalid disklabel type '$LABEL_TYPE'. Must be one of: ${VALID_LABELS[*]}" >&2
    exit 1
fi

if ! in_list "$FS_TYPE" "${VALID_FS_TYPES[@]}"; then
    echo "Error: invalid filesystem type '$FS_TYPE'. Must be one of: ${VALID_FS_TYPES[*]}" >&2
    exit 1
fi

# --- Cross-validation: part-type vs disklabel ---
if in_list "$LABEL_TYPE" "${PART_TYPE_LABELS[@]}"; then
    # msdos/dvh: part-type is required
    : "${PART_TYPE:?Error: partition type must be specified with -t when -l is '$LABEL_TYPE'}"
    if ! in_list "$PART_TYPE" "${VALID_PART_TYPES[@]}"; then
        echo "Error: invalid partition type '$PART_TYPE'. Must be one of: ${VALID_PART_TYPES[*]}" >&2
        exit 1
    fi
else
    # Any other label: part-type is not allowed
    if [[ -n "${PART_TYPE:-}" ]]; then
        echo "Error: -t (partition type) is only valid when -l is one of: ${PART_TYPE_LABELS[*]}. Got -l '$LABEL_TYPE'." >&2
        exit 1
    fi
fi

# --- Cross-validation: name vs disklabel ---
if [[ -n "${PART_NAME:-}" ]] && ! in_list "$LABEL_TYPE" "${NAME_LABELS[@]}"; then
    echo "Error: -n (partition name) is only valid when -l is one of: ${NAME_LABELS[*]}. Got -l '$LABEL_TYPE'." >&2
    exit 1
fi

# --- Run parted ---
parted -s "$DEVICE" mklabel "$LABEL_TYPE"

# Build the mkpart command based on what's applicable/available
MKPART_ARGS=(mkpart)
[[ -n "${PART_TYPE:-}" ]] && MKPART_ARGS+=("$PART_TYPE")
[[ -n "${PART_NAME:-}" ]] && MKPART_ARGS+=("$PART_NAME")
MKPART_ARGS+=("$FS_TYPE" 1MiB 100%)

parted -s "$DEVICE" "${MKPART_ARGS[@]}"
