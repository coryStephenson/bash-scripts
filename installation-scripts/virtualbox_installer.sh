#!/bin/bash

# Script to install Oracle's VirtualBox and its Extension Pack on a Debian-based Linux machine

# Function to update the package list
update_package_list() {
    echo "Updating package list..."
    sleep 3
    sudo apt update
    sleep 3
    echo "\n\n\n"
}

# Function to install dependencies
install_oracle_key() {
    echo "Importing VirtualBox's Repo GPG key..."
    sleep 3
    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg 
    sleep 3
    echo "\n\n\n"
}

# Function to add VirtualBox repository
add_virtualbox_repository() {
    echo "Adding Oracle's VirtualBox repository..."
    sudo add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib"
}

# Function to import Oracle's public key
import_oracle_key() {
    echo "Importing Oracle's public key..."
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
}

# Function to install VirtualBox
install_virtualbox() {
    echo "Installing VirtualBox..."
    sudo apt update
    sudo apt install -y virtualbox-6.1
}

# Function to install VirtualBox Extension Pack
install_extension_pack() {
    echo "Installing VirtualBox Extension Pack..."
    VBOX_VERSION="$(VBoxManage --version | cut -d 'r' -f 1)"
    wget https://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack
    sudo VBoxManage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack
}

# Main script execution
main() {
    update_package_list
    install_dependencies
    add_virtualbox_repository
    import_oracle_key
    install_virtualbox
    install_extension_pack
    echo "VirtualBox and Extension Pack installation completed successfully!"
}

# Execute the main function
main

13.37 seconds
