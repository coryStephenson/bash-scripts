#!/usr/bin/env bash

if (( EUID != 0)); then
    echo "Please run script as root"
    exit 1
fi

# Ultimately, I have an Ollama container and an Open WebUI container

# The Open WebUI container is the only one that needs to be running.


docker_desktop() {

    # Source: https://docs.docker.com/desktop/setup/install/linux/ubuntu
    # If you're not using GNOME, you must install gnome-terminal to enable terminal access from Docker Desktop:
    sudo apt install gnome-terminal


    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/ubuntu
    Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
    Components: stable
    Signed-By: /etc/apt/keyrings/docker.asc
EOF
    # Verify that Apt sources file was created
    sudo cat /etc/apt/sources.list.d/docker.sources

    echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
       $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


    sudo apt update

    # Downloads the latest .deb package
    wget -P /home/cory/Downloads https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb

    # For checksums, see the Release notes at https://docs.docker.com/desktop/release-notes/
    wget -P /home/cory/Downloads https://desktop.docker.com/linux/main/amd64/213807/checksums.txt

    # Find the .deb file and output to console
    find ~/Downloads -printf '%T+ %p\n' | sort -r | head -n3

    # Install the package using apt
    sudo apt-get update
    sudo apt-get install ./docker-desktop-amd64.deb
    sudo apt-get install docker-ce
}


fixes_dependency_issues() {

# Source: https://askubuntu.com/questions/1409192/cannot-install-docker-desktop-on-ubuntu-22-04
You can fix this by running the following commands:

    Update and install dependencies

    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg lsb-release

    Set up the Docker repository

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    Install the docker engine

    sudo apt update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

    Install Docker Desktop (You must download the deb package first from step 2 from the following document: Install Docker Dekstop)

    sudo apt-get install ./docker-desktop-<version>-<arch>.deb

More info here:

    Install Docker Engine on Ubuntu
    Install Docker Dekstop

}


fixes_ollama_serve() {

    # Source: https://github.com/ollama/ollama/issues/707
    # Posted by Jaykumaran
    For Ubuntu

    Step 1. sudo nano /etc/systemd/system/ollama.service

    Add Environment="OLLAMA_HOST=0.0.0.0:11434"

    Step 2: source ~/.bashrc

    Step 3: systemctl stop ollama

    If an warning pops up like:
    Warning: The unit file, source configuration file or drop-ins of ollama.service changed on disk. Run 'systemctl daemon-reload' to reload units.

    Finally,

    Step 4: systemctl daemon-reload

    It should work now,

    ollama serve

    # Note: In my case, I did not have to issue the 'ollama serve' command in order for my particular ollama model (ministral-3:3b) to do its thing.
    # Even if I had issued this command, I'm not entirely sure what it does. It just appears to serve the ollama "service" locally on my machine.
    # How this relates to my Docker containers is beyond me at this time.
}


download_amd_drivers() {

    # Needed to pass Ollama model to GPU instead of the CPU
    sudo dpkg -i amdgpu-install_6.4.60402-1_all.deb
    sudo amdgpu-install --no-dkms --usecase=opencl --opencl=rocr
    sudo apt update
    sudo apt install ocl-icd-opencl-dev opencl-headers

    # How can I tell if my model was loaded onto the GPU?
    # Source: https://docs.ollama.com/faq
    ollama ps


    # It is recommended to add the user to the render and video group, just in case.
    sudo usermod -a -G render $LOGNAME
    sudo usermod -a -G video $LOGNAME

    # Reboot the computer at this point
    sudo reboot

    # Verify that everything was installed properly
    clinfo
}


make_containers() {

# Source: https://ollama.com/download
# Install Ollama locally
curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=v0.13.5 sh

# Pull Ollama image
# Source: https://hub.docker.com/r/ollama/ollama
docker pull ollama/ollama:rocm

# Pull Open WebUI image
# Source: https://docs.openwebui.com/getting-started/quick-start/
docker pull ghcr.io/open-webui/open-webui:main


# Source: The Ollama "Overview" on Docker Hub

# To run Ollama using Docker with AMD GPUs, use the rocm tag and the following command:
docker run -d --device /dev/kfd --device /dev/dri -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama:rocm

# To run Open WebUI using Docker (and Ollama locally)
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

}


ollama_service_modifier() {

# The following changes have to be made to the ollama.service file
# File Path: /etc/systemd/system/ollama.service
# Different options for OLLAMA_CONTEXT_LENGTH are 5096, 2048, and 1024, the smaller the number, the more memory is conserved, if space is an issue.

[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
Environment="OLLAMA_HOST=0.0.0.0:11434"            # Assigns port number for host
Environment="OLLAMA_CONTEXT_LENGTH=1024"           # Sets memory for context window
Environment="OLLAMA_KEEP_ALIVE=-1"                 # Keeps your Ollama model(s) loaded in RAM or VRAM indefinitely

[Install]
WantedBy=default.target


# After saving the changes to the ollama.service file, issue the following commands:

sudo vim /etc/systemd/system/ollama.service
sudo systemctl daemon-reload
sudo systemctl restart ollama

}


resize_container() {

docker run -it --memory="5g" ollama/ollama:rocm

}


ollama_model() {

ollama run ministral-3:3b

}
