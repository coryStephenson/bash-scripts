#!/usr/bin/env bash

# Error handling
# set -euixof pipefail
# set -o errtrace

     # Verify root privileges for execution
     if [[ $EUID -ne 0 ]]; then
           echo "This script must be run as root"
           exit 1
     fi

# List all locally installed binaries via apt
# apt list --installed

: << 'Set up Flatpak on Kubuntu'
https://flatpak.org/setup/Kubuntu
1) Install Flatpak - To install Flatpak on Kubuntu, open Discover, go to Settings, install the Flatpak backend and restart Discover.
2) Install the Flatpak system settings add-on - To integrate Flatpak support into the Plasma System Settings, open the Terminal app and run:
sudo apt install kde-config-flatpak
3) Add the Flathub repository - Flathub is the best place to get Flatpak apps. To enable it, open Discover, go to Settings and add the Flathub repository.
4) Restart - To complete setup, restart your system. Now all you have to do is install apps!
Set up Flatpak on Kubuntu

: << 'Installing snap on Debian'
apt update
apt install snap     # Installs the snap daemon
snap install snapd   # Installs the latest snapd

     if [[ $? -ne 0 ]]; then
           echo "Error encountered: Some snaps require new snapd features. Installing the core snap and its latest version..."
           snap install core
           snap refresh core
           exit 0
     fi

     if [[ $? -eq 0 ]]; then
           echo "Testing your system..."
           echo "Installing the hello-world snap..."
           snap install hello-world
           hello-world
           exit 0
     fi
Installing snap on Debian

# Check if desired applications already exist on local system
# Source for 3>&1 1>&2 2>&3 stream redirect commands: https://unix.stackexchange.com/questions/42728/what-does-31-12-23-do-in-a-script
echo "Checking the desired applications for prior existence on local system..."
while read -r p ; do whereis $p 3>&1 1>&2 2>&3; done < <(cat << "EOF"
    perl
    zip unzip
    exuberant-ctags
    mutt
    libxml-atom-perl
    postgresql-9.6
    libdbd-pgsql
    curl
    wget
    libwww-curl-perl
EOF
)


# Source for do/while loop conditions: https://askubuntu.com/questions/519/how-do-i-write-a-shell-script-to-install-a-list-of-applications
echo "Installing the desired applications..."
while read -r p ; do sudo apt-get install -y $p ; done < <(cat << "EOF"
    perl
    zip unzip
    exuberant-ctags
    mutt
    libxml-atom-perl
    postgresql-9.6
    libdbd-pgsql
    curl
    wget
    libwww-curl-perl
EOF
)

# Installing Wezterm (check website for any command updates)
flatpak install flathub org.wezfurlong.wezterm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
sudo apt update
sudo apt install wezterm
cd ..
mkdir -p .config/wezterm
touch .config/wezterm/wezterm.lua
cd .config/wezterm
kate wezterm.lua

# Installing Neovim via pre-built binary, according to https://github.com/neovim/neovim/blob/master/INSTALL.md
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Then add this to your shell config (~/.bashrc, ~/.zshrc, ...):
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
