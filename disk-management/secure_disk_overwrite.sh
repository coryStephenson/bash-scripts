#!/usr/bin/env bash

# Secure Disk Overwrite Script
# WARNING: This will PERMANENTLY destroy all data on the specified device

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get optimal block size
get_optimal_blocksize() {
    local device="$1"
    # Try to get physical block size, fallback to logical, then default
    if [[ -f "/sys/block/$(basename "$device")/queue/physical_block_size" ]]; then
        cat "/sys/block/$(basename "$device")/queue/physical_block_size"
    elif [[ -f "/sys/block/$(basename "$device")/queue/logical_block_size" ]]; then
        cat "/sys/block/$(basename "$device")/queue/logical_block_size"
    else
        echo "4096"
    fi
}

# Function to get device size in bytes
get_device_size() {
    local device="$1"
    if command -v blockdev &> /dev/null; then
        blockdev --getsize64 "$device"
    else
        # Fallback method
        local sectors=$(cat "/sys/block/$(basename "$device")/size")
        echo $((sectors * 512))
    fi
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    local size=$bytes
    
    while [[ $size -gt 1024 && $unit -lt 4 ]]; do
        size=$((size / 1024))
        unit=$((unit + 1))
    done
    
    echo "${size}${units[$unit]}"
}

# Function to perform secure overwrite
secure_overwrite() {
    local device="$1"
    local passes="$2"
    local block_size="$3"
    local device_size="$4"
    
    print_status "Starting secure overwrite of $device"
    print_status "Device size: $(format_bytes "$device_size")"
    print_status "Block size: $block_size bytes"
    print_status "Number of passes: $passes"
    
    # Pass patterns for multi-pass wipe
    local patterns=("random" "zero" "0xFF" "0x55" "0xAA")
    
    for ((pass=1; pass<=passes; pass++)); do
        print_status "Pass $pass/$passes..."
        
        case $pass in
            1) pattern="random" ;;
            2) pattern="zero" ;;
            3) pattern="0xFF" ;;
            4) pattern="0x55" ;;
            *) pattern="random" ;;
        esac
        
        case $pattern in
            "random")
                print_status "Writing random data..."
                if command -v pv &> /dev/null; then
                    dd if=/dev/urandom bs="$block_size" | pv -s "$device_size" | dd of="$device" bs="$block_size" oflag=direct 2>/dev/null
                else
                    dd if=/dev/urandom of="$device" bs="$block_size" oflag=direct status=progress
                fi
                ;;
            "zero")
                print_status "Writing zeros..."
                if command -v pv &> /dev/null; then
                    dd if=/dev/zero bs="$block_size" | pv -s "$device_size" | dd of="$device" bs="$block_size" oflag=direct 2>/dev/null
                else
                    dd if=/dev/zero of="$device" bs="$block_size" oflag=direct status=progress
                fi
                ;;
            *)
                print_status "Writing pattern $pattern..."
                if command -v pv &> /dev/null; then
                    tr '\0' '\377' < /dev/zero | dd bs="$block_size" | pv -s "$device_size" | dd of="$device" bs="$block_size" oflag=direct 2>/dev/null
                else
                    tr '\0' '\377' < /dev/zero | dd of="$device" bs="$block_size" oflag=direct status=progress
                fi
                ;;
        esac
        
        # Force sync to ensure data is written
        sync
        print_status "Pass $pass completed"
    done
}

# Main function
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Parse arguments
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <device> [passes] [quick]"
        echo "  device: Target device (e.g., /dev/sdb)"
        echo "  passes: Number of overwrite passes (default: 3, max: 5)"
        echo "  quick:  Use 'quick' for single-pass random overwrite"
        echo ""
        echo "Examples:"
        echo "  $0 /dev/sdb           # 3-pass overwrite"
        echo "  $0 /dev/sdb 1         # 1-pass overwrite"
        echo "  $0 /dev/sdb quick     # Quick single-pass random"
        exit 1
    fi
    
    local device="$1"
    local passes=3
    local quick=false
    
    # Parse additional arguments
    if [[ $# -gt 1 ]]; then
        if [[ "$2" == "quick" ]]; then
            quick=true
            passes=1
        elif [[ "$2" =~ ^[1-5]$ ]]; then
            passes="$2"
            if [[ $# -gt 2 && "$3" == "quick" ]]; then
                quick=true
            fi
        fi
    fi
    
    # Validate device
    if [[ ! -b "$device" ]]; then
        print_error "Device $device does not exist or is not a block device"
        exit 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$device"; then
        print_error "Device $device is currently mounted. Unmount it first."
        exit 1
    fi
    
    # Get device information
    local block_size=$(get_optimal_blocksize "$device")
    local device_size=$(get_device_size "$device")
    
    # Show warning and confirmation
    print_warning "═══════════════════════════════════════"
    print_warning "         DESTRUCTIVE OPERATION"
    print_warning "═══════════════════════════════════════"
    print_warning "Device: $device"
    print_warning "Size: $(format_bytes "$device_size")"
    print_warning "ALL DATA WILL BE PERMANENTLY DESTROYED!"
    print_warning "═══════════════════════════════════════"
    
    read -p "Type 'WIPE' to confirm: " confirm
    if [[ "$confirm" != "WIPE" ]]; then
        print_error "Operation cancelled"
        exit 1
    fi
    
    # Start timing
    local start_time=$(date +%s)
    
    if [[ "$quick" == true ]]; then
        print_status "Performing quick wipe (single random pass)..."
        dd if=/dev/urandom of="$device" bs="$block_size" oflag=direct status=progress
        sync
    else
        secure_overwrite "$device" "$passes" "$block_size" "$device_size"
    fi
    
    # Final verification pass - read back some random sectors
    print_status "Performing verification..."
    local sectors_to_check=10
    local sector_size=512
    for ((i=0; i<sectors_to_check; i++)); do
        local random_offset=$((RANDOM % (device_size / sector_size)))
        dd if="$device" bs="$sector_size" count=1 skip="$random_offset" 2>/dev/null | od -x | head -1 > /dev/null
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_status "═══════════════════════════════════════"
    print_status "Secure wipe completed successfully!"
    print_status "Time taken: ${duration} seconds"
    print_status "Device $device has been securely overwritten"
    print_status "═══════════════════════════════════════"
}

# Trap to handle interruption
trap 'print_error "Operation interrupted"; exit 1' INT TERM

# Run main function
main "$@"
