#!/usr/bin/env bash

# 1) Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (use sudo)."
    exit 1
fi

     # 2) Check if a device argument was provided
     if [ -z "$1" ]; then
         echo "Usage: $0 /dev/sdX"
         echo "Replace /dev/sdX with the actual device name (e.g., /dev/sda)"
         exit 1
     fi

     DEVICE="$1"

          # 3) Delete any existing partitions on the USB stick
          parted --script "$DEVICE" print | grep -oP '^\s*\d+' | while read PART_NUM; do
              parted --script "$DEVICE" rm "$PART_NUM"
          done

          
	  echo "All partitions have been deleted on $DEVICE."

               # 4) Confirm with the user before proceeding
               echo "WARNING: This will delete all partitions on the device $DEVICE!"
               read -p "Do you want to continue? (y/n): " CONFIRM
                    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
                         echo "Aborted."
                         exit 1
                    fi

# 5) Run parted to create a new partition table and partition
parted --script "$DEVICE" mklabel msdos
parted --script "$DEVICE" mkpart primary fat32 1MiB 100%
parted --script "$DEVICE" name 1 MULTIBOOT

     # 6) Format the partition as FAT32
     mkfs.fat -F 32 "${DEVICE}1"


     echo "Partitioning and formatting complete. The partition has been named 'MULTIBOOT'."

################################################
# Install GRUB on USB stick to make it bootable 
################################################

# 7) Make the directory that will contain the GRUB files
mkdir -p /media/MULTIBOOT/boot


scheme() {

PS3=$'\n\n'"Which partition scheme do you prefer in this case? "
COLUMNS=1
partition=("MBR partitioning scheme (Standard for firmware interface: BIOS)" "GPT partitioning scheme (Specification for interface b/w operating system and firmware: UEFI)")

while true
do
        echo -e "\nSELECT PARTITION SCHEME\n\n"
   select a in "${partition[@]}";
       do

       case $a in


          "MBR partitioning scheme (Standard for firmware interface: BIOS)")

   
                                                                                # 8) Introduce the MBR partitioning scheme (Standard for firmware interface: BIOS)
                                                                                     grub-install --target=i386-pc --boot-directory=/media/MULTIBOOT/boot "$DEVICE"

	                                                                        ;;


          "GPT partitioning scheme (Specification for interface b/w operating system and firmware: UEFI)")

                                                                                # 9) Introduce the GPT partitioning scheme (Specification for interface b/w operating system and firmware: UEFI)
                                                                                     grub-install --target=x86_64-efi --boot-directory=/media/MULTIBOOT/boot "$DEVICE"

	                                                                        ;;

          *) echo -e "\nInvalid entry. Please try an option on display."

             scheme
	  ;;
      esac
    done
done

}

     
          # 10) Create a GRUB configuration file to boot the distros on your hard drive
          grub-mkconfig -o /media/MULTIBOOT/boot/grub/grub.cfg

               # 11) Remove everythin after the line that says ### END/etc/grub.d/00_header ###
               sed '/### END/etc/grub.d/00_header ###/ q' /media/MULTIBOOT/boot/grub/grub.cfg

               # 12) Output contents of configuration file
               cat /media/MULTIBOOT/boot/grub/grub.cfg
               sleep 10


################################################
# Add a populated menu to the GRUB shell 
################################################


FILE="/media/MULTIBOOT/boot/grub/grub.cfg"

cat <<'EOL' >> "$FILE"
submenu "Ubuntu 16.04" {
set isofile=/Ubuntu/ubuntu-1.04-desktop-amd64.iso
loopback loop $isofile
menuentry "Try Ubuntu 16.04 without installing" {
linux (loop)/casper/vmlinuz.efi file=/cdrom/preseed/
ubuntu.seed boot=casper iso-scan/filename=$isofile quiet
splash ---
initrd (loop)/casper/initrd.lz
}
menuentry "Install Ubuntu 16.04" {
linux (loop)/casper/vmlinuz.efi file=/cdrom/preseed/
ubuntu.seed boot=casper iso-scan/filename=$isofile only-
ubiquity quiet splash ---
  initrd (loop)/casper/initrd.lz
 }
}
EOL

################################################
# Get my bearings
################################################

# Reveal the current workin directory
     pwd

# List block devices  
     lsblk


# Create the Ubuntu directory on the drive and copy over the ISO file.
# Then unmount the drive and reboot from the stick. You should see a GRUB menu 
# with one entry for Ubuntu that opens up to reveal boot and install options.


# I have opted to download an .iso file directly to a specific directory on the stick instead

################################################
# Download the .iso file(s)
################################################

catch() {
  exit_code="${1}"
  line_number="${2}"
  iso_name="${ISO_NAME}"
  echo -e "SIGINT: Exit code ${exit_code} at about line number ${line_number}.\n"
  echo -e "Removing ${iso_name}...\n"
  rm -rf "${ISO_NAME}"*
  echo -e "Exit code for .iso removal: $?"
}


# 1) Read user input for directory variable DESTINATION
echo "Desired .iso download directory? (Please enter absolute path) "

read -r DESTINATION


     # 2) Test directory variable non-existence && mkdir -p /media/MULTIBOOT/Ubuntu

     if [[ ! -d "${DESTINATION}" ]]; then

          echo -e "\n\n${DESTINATION} not found. Making directory ${DESTINATION}..."
          mkdir -p /media/MULTIBOOT/Ubuntu

     else 

          echo -e "\n\n${DESTINATION} already exists. The file will be placed in ${DESTINATION}."

     fi



          # 3) Read user input for .iso image URL variable ISO

	       echo -e "\n\nDesired .iso download URL? "

	            read -r ISO_URL

	       echo -e "\n\nDesired filename for .iso download? "

		    read -r ISO_NAME


	        # 4) Test image variable non-existence && download using wget inside while loop

		            cd "${DESTINATION}"
		            find "${DESTINATION}" -name "${ISO_NAME}".iso
		            exit_code=$?

		            if [ $exit_code -ne 0 ] && [ $exit_code -ne 14 ]; then
                                 echo "\n\n${ISO_NAME} not found. Catching..."

					else
						echo -e "\n\n${ISO_NAME} already exists. The file resides in the following directory: ${DESTINATION}"
						echo -e "\nIt may just be a partial download. To be on the safe side, I'll delete it.\n"
                                                echo -e "\nRemoving files that start with ${ISO_NAME}...\n"
                                                rm -rf "${ISO_NAME}"*
						     trap 'catch '${exit_code}' '${LINENO}'' ERR INT TERM EXIT
						     echo -e "\n\nStarting download via wget..."
						     wget -o "${DESTINATION}"/"${ISO_NAME}" "${ISO_URL}"
						     echo -e "\n\nExit status (0 means success; 1 means error): $?"
                            
			    fi

      
      # 5) Unmount the drive
      umount "$DEVICE"




