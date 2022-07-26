#!/bin/bash
############################################################################
# This script simply formats a block device and mounts it to the data
# directory in a very safe manner by checking that the block device is
# completely empty
#
############################################################################

echo -e "\n\n******************************************************************************\n
Name of Script: $0\n
Author: Cory Stephenson\n
Original script can be found here: https://gist.github.com/basilmusa/eb7c972b07f4403de340f324fb692a43\n
I'd like to thank Basil Musa for his contribution. It was a very well written script.\n
View script for further description of tasks\n
Tasks:\n
1) Check whether or not the block device is already mounted, if yes, then exit\n
2) Check wheth or not the block device is already initialized, if yes, then exit\n
3) Create partition table\n 
4) Partition block device\n
5) Check alignment for optimal performance\n
6) Set boot flags on each partition\n
********************************************************************************************\n\n"

<<steps
1) Modify shell behavior using set
2) Initialize the variables that represents the options passed to the script
3) Create usage() function
4) Use while getopts loop with a nested case statement
steps


<<alignment

*** DO NOT USE IN PRODUCTION *** I AM NOT SURE THAT IT WORKS YET ***

SCSI_DISK=$(lsblk -o name -lpn | head -1 | sed 's/^.\{5\}//')

optimal_io_size=$(cat /sys/block/"${SCSI_DISK}"/queue/optimal_io_size)
minimal_io_size=$(cat /sys/block/"${SCSI_DISK}"/queue/minimum_io_size)
alignment_offset=$(cat /sys/block/"${SCSI_DISK}"/alignment_offset)
block_size=$(cat /sys/block/"${SCSI_DISK}"/queue/physical_block_size)

var=$(echo "${optimal_io_size} + ${alignment_offset}" | bc)
sector_start=$(echo "${var} / ${block_size}" | bc) 
echo -e "Partitioning should begin with the ${sector_start}th sector.\n\n"


## PARTITION ALIGNMENT CHECK #############################################
PARTITION_NUMBER=$(lsblk -o name -lpn | head -1 | sed 's/^.\{8\}//')
parted -s -- ${BLOCK_DEVICE_PATH} align-check optimal 1

alignment

<<filesystem                    
                      FILESYSTEMS=("ext3" "ext4" "btrfs" "fat16" "fat32" "hfs" "hfs+" "linux-swap" "ntfs" "udf" "xfs" "Quit")

                      echo -e "\nFILESYSTEM TYPES\n\n"
                      select FS in "${FILESYSTEMS[@]};
                      do
         
                      case $FS in
         
         
                      "ext3")
              
                                 ## Third Extended File System
              
                      "ext4")
              
                         ## Fourth Extended File System
                         Note the use of ‘--’, to prevent the following ‘-1s’ last-sector indicator from being interpreted as an invalid command-line option.
                         
                         
                         parted -s -a optimal ${BLOCK_DEVICE_PATH} mkpart primary ext4 0% 8G 
                      "btrfs")
              
                         ## Better FS aka Butter FS aka B-Tree FS
              
                      "fat16")
              
                         ## MS-DOS File System
              
                      "fat32")   
              
                         ## Windows File System 
              
                      "vfat")
              
                         sudo mkfs.vfat -F32 /dev/${SCSI_DISK}
                      "hfs")     
              
                         ## Macintosh Hierarchical File System
              
                      "hfs+")
              
                      "linux-swap")
              
                      "ntfs")
              
                      "udf")
              
                      "xfs")
              
     

                      
                      "msdos") 
            
                               parted --script ${BLOCK_DEVICE_PATH} mklabel msdos
                      
                      
                      "Quit")
            
                      echo -e "\n\nAre you sure you want to quit?\n"
                      select ans in "Yes" "No";
                          do
                          
                          case $ans in
                                "Yes")
                                          exit 0
                                          ;;
                                "No")
                                          partition
                                          ;;
                          esac
                          done
                          ;;
                          
               *) echo -e "\nInvalid entry. Please try an option on display."
               
                  partition
               ;;
                          esac
                          done 

done

filesystem

set -eu
set -x


usage() {
	echo "    Usage: ./${0} [options] <block_device> <mount_directory>" >&2
	echo "    Example: ./${0} /dev/vdb /data" >&2
	echo "    To figure out the block devices on the machine use lsblk command" >&2

	exit 1
}




while getopts "P:N:A:p:F:" opt;
do
       case "${opt}" in
       P)     PART_TABLE=$OPTARG;;
       N)     NUM_PARTS=$OPTARG;;
       A)     ALIGNMENT=$OPTARG;;
       p)     PART_TYPE=$OPTARG;;
       F)     FILESYSTEM=$OPTARG;;
       :) echo "You need to give an argument for option -${OPTARG}."
          exit 1
          ;;
       *) echo "Invalid argument: -${OPTARG}."
          exit 1
          ;;
       esac
done
shift $((OPTIND - 1))

if [ $# -ne 2 ]
then
      usage
fi


BLOCK_DEVICE_PATH="${1}"
MOUNT_TO_DIR="${2}"


## SAFETY CHECK ###########################################################
# Check if ${BLOCK_DEVICE_PATH} is mounted, if yes, then exit
if [[ $(/bin/mount | grep -q "${BLOCK_DEVICE_PATH}") > /dev/null ]]; then
     echo "BLOCK DEVICE ${BLOCK_DEVICE_PATH} ALREADY MOUNTED"
     exit 1;
fi

## SAFETY CHECK ###########################################################
if [[ $(/sbin/blkid ${BLOCK_DEVICE_PATH}) ]]; then
     echo "BLOCK DEVICE ALREADY INITIALIZED, WILL NOT PROCEED WITH SCRIPT";
     exit 1;
fi


## CREATE PARTITION TABLE AND CREATE PARTITION
parted --script "${BLOCK_DEVICE_PATH}" -- mklabel gpt
for (("${a:=1}" ; $a <= $NUM_PARTS; a++)); 
do
     echo -e "\n\nWhere would you like the number ${a} partition to start? "
          read START
     echo -e "\n\nWhere would you like the number ${a} partition to end? "
          read END

     
     parted -s -a "${ALIGNMENT}" "${BLOCK_DEVICE_PATH}" mkpart "${PART_TYPE}" "${FILESYSTEM}" "${START}"% "${END}"%
     
     parted -s "${BLOCK_DEVICE_PATH}" set 1 boot on
    
     

done

## NEEDED FOR lsblk TO REFRESH
     echo "Sleeping 5 seconds"
     sleep 5;
     
     
partprobe "${BLOCK_DEVICE_PATH}"

## PARTITIONNAME WITHOUT '/dev' 
x=$(lsblk -o name -lpn "${BLOCK_DEVICE_PATH}" | tail -"${NUM_PARTS}" | sed 's/^.\{5\}//')
declare -a SCSI_PARTITION
SCSI_PARTITION=($x);
                      

for j in "${SCSI_PARTITION[@]}";
do
     echo $j

     ## SAFETY CHECK ###########################################################
     if [[ ${#SCSI_PARTITION} -ne 4 ]]; then
          echo "EXITING SINCE [$SCSI_PARTITION] DOES NOT CONTAIN 4 CHARACTERS";
          exit 1;
     fi;

     ## Format it as ext4
     mkfs.ext4 "/dev/$SCSI_PARTITION"
done
     
## Create a mount directory at /data if does not exist
mkdir -p ${MOUNT_TO_DIR}

for j in ${SCSI_PARTITION[@]}; do

     # Mount it in /etc/fstab
     UUID_STRING=$(blkid -o export /dev/$SCSI_PARTITION | grep "^UUID")
     
     
     if [ -n ${UUID_STRING} ]; then
          echo -e "\n$UUID_STRING ${MOUNT_TO_DIR} ext4 defaults,nofail 0 0" >> /etc/fstab
     fi

     

done

# Run mount -a
mount -a
     
# TO UNDO WHAT THE SCRIPT HAS DONE
# PLEASE DO NOT COMMENT THIS OUT, ONLY SERVES FOR DOCUMENTATION
# USE ONLY WHEN YOU ARE SURE WHAT YOU ARE DOING
# umount /dev/vdb1
# wipefs -a /dev/vdb1
# parted /dev/vdb rm 1
# wipefs -a /dev/vdb
