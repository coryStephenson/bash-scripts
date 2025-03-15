#!/usr/bin/env bash

if command -v virtualbox >/dev/null 2>&1; then
  echo "VirtualBox already exists, displaying usage menu...\n\n"
       # Source for usage menu: https://gist.github.com/sianios/155a464eb001f046df98
          usage="Usage: ./virtualbox.sh [option] [VM name]"
          options="
          Options:
          list                List available virtual machines
          running             List running virtual machines
          start               Start virtual machine
          stop                Send shutdown signal to OS to shutdown machine
          poweroff            Shutdown machine like pulling the plug
          save                Save state of running virtual machine
          reset               Send a restart signal to OS
          "

          case $1 in
              list) VBoxManage list vms ;;
              running) VBoxManage list runningvms ;;
              start) VBoxHeadless -startvm $2 & ;;
              stop) VBoxManage controlvm $2 acpipowerbutton ;;
              poweroff) VBoxManage controlvm $2 poweroff ;;
              save) VBoxManage controlvm $2 savestate ;;
              reset) VBoxManage controlvm $2 reset ;;
              *) echo -e ""$usage" \n" "$options"
          esac
else
  
  echo "VirtualBox does not exist, installing...\n\n"
  # Source for importing virtualbox GPG keys and extension pack: https://linuxiac.com/how-to-install-virtualbox-on-debian-12-bookworm/
        GPG=/usr/share/keyrings/oracle_vbox_2016.gpg
     if [ ! -e "$GPG" ]; then
         echo "GPG keys do not exist.\n\n"
         echo "Downloading and Importing VirtualBox's GPG keys...\n"
             wget -O- -q https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmour -o /usr/share/keyrings/oracle_vbox_2016.gpg
     else 
         echo "GPG keys already exist.\n\n"
     fi 
        
        REPO=/etc/apt/sources.list.d/virtualbox.list
     if [ ! -e "$REPO" ]; then
         echo "VirtualBox Repository for Debian 12 does not exist.\n\n"
         echo "Adding VirtualBox Repository for Debian 12...\n"
              echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle_vbox_2016.gpg] http://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
     else
         echo "VirtualBox Repository for Debian 12 already exists.\n\n"
     fi
        echo "Running system update...\n"
             sudo apt update
 
      if command -v virtualbox >/dev/null 2>&1; then
           echo "VirtualBox already exists, displaying usage menu...\n\n"
       # Source for usage menu: https://gist.github.com/sianios/155a464eb001f046df98
          usage="Usage: ./virtualbox.sh [option] [VM name]"
          options="
          Options:
          list                List available virtual machines
          running             List running virtual machines
          start               Start virtual machine
          stop                Send shutdown signal to OS to shutdown machine
          poweroff            Shutdown machine like pulling the plug
          save                Save state of running virtual machine
          reset               Send a restart signal to OS
          "

          case $1 in
              list) VBoxManage list vms ;;
              running) VBoxManage list runningvms ;;
              start) VBoxHeadless -startvm $2 & ;;
              stop) VBoxManage controlvm $2 acpipowerbutton ;;
              poweroff) VBoxManage controlvm $2 poweroff ;;
              save) VBoxManage controlvm $2 savestate ;;
              reset) VBoxManage controlvm $2 reset ;;
              *) echo -e ""$usage" \n" "$options"
          esac
     else
        echo "\n\nInstalling VirtualBox on Debian 12...\n"
             sudo apt install virtualbox-7.1
     fi
             
        # Verify exact version of VirtualBox
             VER=$(vboxmanage -v | cut -dr -f1)
             
        # Download and Install VirtualBox Extension Pack
             wget https://download.virtualbox.org/virtualbox/"${VER}"/Oracle_VirtualBox_Extension_Pack-"${VER}".vbox-extpack
             sudo vboxmanage extpack install Oracle_VirtualBox_Extension_Pack-"${VER}".vbox-extpack
             
        # Verify that the expansion pack was installed correctly
             vboxmanage list extpacks
             
        # Adding your user account to the vboxusers group
             sudo usermod -a -G vboxusers $USER
             
fi
              
             




