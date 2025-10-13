#!/usr/bin/env bash

# Execute as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Must be root"
    exit 1
fi

dependency_check() {

                                           echo -e "\n\nInitiating dependency check...\n\n"

  for pkg in fuse3 ntfs-3g; do
        
       if ! command -v "$pkg" > /dev/null 2>&1; then
            echo -e "\n\nDependency known as ${pkg} not found.\n\n"
            echo -e "\n\nInstalling dependency known as ${pkg}...\n\n"
            apt install "${pkg}"
        else
            echo -e "\n\nDependency known as ${pkg} is already installed.\n\n"
       fi
    done

                                             echo -e "\n\nDependency check complete.\n\n"

}


mount_partition() {

                                                    echo -e "\n\nInitiating partition mounting procedure...\n\n"


                                  # 1) Read user input for mount point variable MNT_PNT
	                                    echo "Desired mount point directory? (Please enter absolute path) "

		                          # The -r option stipulates that backslash does not act as an escape character
		                            read -r MNT_PNT

		                       # 2) Test directory variable non-existence && mkdir ~/iso-files

				            if [[ ! -d "${MNT_PNT}" ]]; then

						    echo -e "\n\n${MNT_PNT} not found. Making directory ${MNT_PNT}...\n"
			                            mkdir "${MNT_PNT}"

					       else

						echo -e "\n\n${MNT_PNT} already exists. The file will be placed in ${MNT_PNT}.\n\n"

					       fi
                 
                 
                # Find block device partition path (absolute)

                echo -e "\n\nListing block devices...\n\n"

                      lsblk

                         echo -e "\n\n\n\n"

                         # 1) Read user input for mount point variable MNT_PNT
	                                    echo "Which partition would you like to have mounted? (Please enter absolute path) "

		                          # The -r option stipulates that backslash does not act as an escape character
		                                   read -r PARTITION

                           BLK_DEV=$(lsblk -o name -lpn | grep "${PARTITION}")

                     # Verify we found a partition
                          if [ -z "$BLK_DEV" ]; then
                             echo -e "\n\nNo ${BLK_DEV} partition found.\n\n"
                             exit 1

                           else

                             echo -e "\n\nPartition ${BLK_DEV} found.\n\n"

                          fi

                              # Mount the partition
                                   mount -t ntfs3 "${BLK_DEV}" "${MNT_PNT}"

                                      # Check if the partition is mounted
                                          if ! mountpoint -q "${MNT_PNT}"; then
                                                  echo -e "\n\n$BLK_DEV is not mounted at $MNT_PNT.\n\n"
                                                  exit 1
                                            else
                                                  echo -e "\n\n$BLK_DEV is mounted at $MNT_PNT.\n\n"
                                          fi 



}


main() {

  echo -e "\n\nUpdating apt sources list...\n\n"

  apt update

  echo -e "\n\nUpdate complete.\n\n"


  dependency_check

  mount_partition

}

main
