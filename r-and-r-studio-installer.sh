#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Add R repository to sources.list
echo "deb https://cloud.r-project.org/bin/linux/debian buster-cran40/" >> /etc/apt/sources.list

# Add GPG key for R repository
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9

# Update package list and install R
apt update
apt install -y r-base

# Install dependencies for R Studio
apt install -y gdebi-core libapparmor1 libclang-dev libssl-dev libxml2-dev libgit2-dev libcurl4-openssl-dev

# Download and install R Studio
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2021.09.0-351-amd64.deb
gdebi -n rstudio-2021.09.0-351-amd64.deb

# Clean up
rm -rf rstudio-2021.09.0-351-amd64.deb
