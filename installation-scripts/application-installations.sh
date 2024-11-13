#!/usr/bin/env bash

# Error handling
set -euixof pipefail
set -o errtrace

# Verify root privileges for execution
if [[ $EUID -ne 0 ]]; then
echo "This script must be run as root"
exit 1
fi

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

