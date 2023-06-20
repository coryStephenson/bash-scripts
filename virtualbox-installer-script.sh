#!/bin/bash

# Update package list
sudo apt update

# Install dependencies
sudo apt install -y curl gnupg

# Add VirtualBox repository
curl -fsSL https://www.virtualbox.org/download/oracle_vbox.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/oracle_vbox.asc.gpg
echo "deb [arch=$(dpkg --print-architecture)] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

# Update package list again
sudo apt update

# Install VirtualBox
sudo apt install -y virtualbox-6.1

# Optional: Install VirtualBox Extension Pack
sudo apt install -y virtualbox-ext-pack

echo "VirtualBox installation completed!"
