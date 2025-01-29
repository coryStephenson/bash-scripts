#!/usr/bin/env bash

# IMPORTANT! Place this script in the root directory of the flash drive
# 1) Change directory to the location of the script
     cd $(dirname $0)


# 2) Extract the header portion of the default grub.cfg     
sudo grub-mkconfig 2>/dev/null | sed -n '\%BEGIN /etc/grub.d/00_header%,\%END /etc/grub.d/00_header%p' >| boot/grub/grub.cfg


     # 3) Add each of the individual submenus (distros are added in alphabetical order)
          for menu in */submenu; 
             do
                echo "source /$menu" >>boot/grub/grub.cfg
             done
  
