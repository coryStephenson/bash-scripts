#! /usr/bin/env bash

FOUND=("\033[38;5;10m")

NOTFOUND=("\033[38;5;9m")

# ${parameter:offset}
# ${parameter:offset:length}

<<substring

This is referred to as Substring Expansion. It expands to up to
the length characters of the value of parameter starting at the character specified by offset.
If parameter is '@', an indexed array subscripted by '@' or '*', or an associative array name,
the results differ as described below. If length is omitted, it expands to the substring of the
value of parameter starting at the character specified by offset and extending to the end of the 
value.Length and offset are arithmetic expressions (see Shell Arithmetic).

substring

declare -a package=("inxi" "python2.7" "vim" "imagemagick" "gpg" "curl" "wget" "axel" "network-manager" "wpa_supplicant" "iwd" "htop"
	            "youtube-dl" "traceroute" "ffmpeg" "smbclient" "pandoc")

PKG="${package[@]:1}"

command -v ${PKG} &> /dev/null

if [[ $? != 0 ]]; then
    echo -e "${NOTFOUND}[!] ${PKG} not found [!]"
    echo -e "${NOTFOUND}[!] Would you like to install ${PKG} now ? [!]"
    read -p "[Y/N] >$ " ANSWER
    if [[ ${ANSWER} == [yY] || ${ANSWER} == [yY][eE][sS] ]]; then
    
	    if grep -q "bian" /etc/os-release; then
		    apt -y install ${PKG}
	    elif grep -q "arch" /etc/os-release; then
		    if [[ -f /bin/yay ]] || [[ -f /bin/yaourt ]]; then
			yaourt -S ${PKG} 2>./err.log || yay -S ${PKG} 2>./err.log
		    else
			pacman -S ${PKG}
		    fi
	    elif grep -q "fedora" /etc/os-release; then
		 sudo dnf install ${PKG}
	    else
		 echo -e "${NOTFOUND}[!] This script couldn't detect your package manager [!]"
		 echo -e "${NOTFOUND}[!] Manually install it [!]"
	    fi
    elif [[ ${ANSWER} == [nN] || ${ANSWER} == [nN][oO] ]]; then
	    echo -e "${NOTFOUND}[!] Exiting [!]"
    fi
else
    echo -e "${FOUND}[+] ${PKG} found [+]"
fi
