# Installs Signal Desktop

# NOTE: These instructions only work for 64-bit Debian-based
# Linux distributions such as Ubuntu, Mint etc.

# 1. Install our official public software signing key:
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

# 2. Add our repository to your list of repositories:
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee /etc/apt/sources.list.d/signal-xenial.list

# 3. Update your package database and install Signal:
sudo apt update && sudo apt install signal-desktop

# Installs VLC Media Player Via Flathub
flatpak install flathub org.videolan.VLC

# Installs Shortwave Radio
flatpak install flathub de.haeckerfelix.Shortwave

# Installs Obsidian Note Taking App
flatpak install flathub md.obsidian.Obsidian

# Installs GNU IMAGE MANIPULATION PROGRAM
flatpak install flathub org.gimp.GIMP

# Installs Thunderbird Email, Newsfeed, Chat, and Calendaring Client/Program
flatpak install flathub org.mozilla.Thunderbird

# Installs Bitwarden Password Manager For Desktop
flatpak install flathub com.bitwarden.desktop

# Installs No Code/Commandline Alternative To Managing Flatpacks
flatpak install flathub io.github.flattool.Warehouse

# Installs NewsFlash RSS Reader For Internet Notifications Without Social Meida Accounts
flatpak install flathub io.gitlab.news_flash.NewsFlash

# Install Kiwix Offline Wikipedia/Wiki Viewer
flatpak install flathub org.kiwix.desktop

# Install Stellarium Planetarium 
flatpak install flathub org.stellarium.Stellarium

# Install OBS Studio Live Streaming Software
flatpak install flathub com.obsproject.Studio

# Install Shotcut Video Editing Software
flatpak install flathub org.shotcut.Shotcut

# Install Ollama Local AI Program
curl -fsSL https://ollama.com/install.sh | sh

# Restart Computer
sudo systemctl reboot 


