#!/usr/bin/env bash

if (( EUID != 0)); then
    echo "Please run script as root"
    exit 1
fi

# Script to install Oracle's VirtualBox and its Extension Pack on a Debian-based Linux machine

# Function to update the package list
update_package_list() {
    echo "Updating package list..."
    sleep 3
    sudo apt update
    sleep 3
    echo -e "\n\n\n"
}

# Function to import VirtualBox's Repo GPG key
import_oracle_key() {
    
    # First, we’ll import the GPG key from the VirtualBox repository 
    # to ensure the authenticity of the software we install from it.
    
    echo "Importing VirtualBox's Repo GPG key..."
    sleep 3
    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg \
    --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg 
    sleep 3
    echo -e "\n\n\n"
}

# Function to add VirtualBox repository
add_virtualbox_repository() {
    
    # Next, we’ll add the official VirtualBox repository to our Ubuntu 22.04 system. 
    # If a new version is released, the update package will be made available with the rest of your system’s regular updates.
    
    echo "Adding Oracle's VirtualBox repository..."
    sleep 3
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] http://download.virtualbox.org/virtualbox/debian $(. /etc/os-release && echo "$VERSION_CODENAME") contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
    sleep 3
}

# Function to install VirtualBox
install_virtualbox() {
    echo "Installing VirtualBox 7.2..."
    sleep 3
    sudo apt install virtualbox-7.2
    sleep 3
    echo -e "\n\n\n"
}

# Function to install VirtualBox Extension Pack
install_extension_pack() {
    
    # USB 2 and USB 3 support
    # VirtualBox Remote Desktop Protocol (VRDP)
    # Host webcam passthrough
    # Disk image encryption with AES
    # Intel PXE boot ROM
    # Support for NVMe SSDs
    # The Extension Pack’s version is strongly recommended 
    # to match the VirtualBox’s installed version. To verify the exact one of 
    # the just-installed VirtualBox, you can use a built-in vboxmanage command:

    

    # Downloads the Extension Pack
    wget https://download.virtualbox.org/virtualbox/$(vboxmanage -v | cut -dr -f1)/Oracle_VirtualBox_Extension_Pack-$(vboxmanage -v | cut -dr -f1).vbox-extpack
    
    echo "Installing VirtualBox Extension Pack..."
    sleep 3
    sudo vboxmanage extpack install Oracle_VirtualBox_Extension_Pack-$(vboxmanage -v | cut -dr -f1).vbox-extpack
    sleep 3

    # Verify the installed VirtualBox extension pack version
    vboxmanage list extpacks
    sleep 3
    
    # Before using VirtualBox, add your user account to the "vboxusers" group
    echo "Adding your user account to the vboxusers group..."
    sudo usermod -aG vboxusers $USER
    sleep 3

}


# Main script execution
main() {
    update_package_list
    import_oracle_key
    add_virtualbox_repository
    update_package_list
    install_virtualbox
    install_extension_pack
    echo "VirtualBox and Extension Pack installation completed successfully!"
    sleep 1
    echo "Perform a reboot now...and then run `users $USER` to ensure you are in the vboxusers group."
    sleep 3
    echo "The script will now terminate..."
    sleep 3
    exit 0
}

# Execute the main function
main


