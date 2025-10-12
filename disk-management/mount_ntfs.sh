#!/usr/bin/env bash

dependency_check() {
  
    for pkg in fuse ntfs-3g; do
      
        command -v "$pkg" > /dev/null 2>&1 \
          || { echo "$pkg is required, but not installed."; \
          exit 1; }

    done
}

mount_partition() {

                                  # 1) Read user input for mount point variable MNT_PNT
	                                    echo "Desired mount point directory? (Please enter absolute path) "

		                          # The -r option stipulates that backslash does not act as an escape character
		                            read -r MNT_PNT

		                       # 2) Test directory variable non-existence && mkdir ~/iso-files

				            if [[ ! -d "${MNT_PNT}" ]]; then

						    echo -e "\n\n${MNT_PNT} not found. Making directory ${MNT_PNT}..."
			                            mkdir "${MNT_PNT}"

					       else

						echo -e "\n\n${MNT_PNT} already exists. The file will be placed in ${MNT_PNT}."

					       fi
                 
                 
                 # Find block device path (absolute)
                     BLK_DEV=$(lsblk -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}' | grep '/dev/sdb') 

  # Mount the partition
  mount -t ntfs-3g /dev/sdb2 /mnt/ntfs2/


