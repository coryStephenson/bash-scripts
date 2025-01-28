#!/bin/bash

# Update and upgrade the system
apt update && apt upgrade -y

# Disable root login via SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
service ssh restart

# Disable password authentication for SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
service ssh restart

# Set strong password policies
sed -i 's/# minlen/minlen/g' /etc/security/pwquality.conf
sed -i 's/# dcredit/dcredit/g' /etc/security/pwquality.conf
sed -i 's/# ucredit/ucredit/g' /etc/security/pwquality.conf
sed -i 's/# lcredit/lcredit/g' /etc/security/pwquality.conf
sed -i 's/# ocredit/ocredit/g' /etc/security/pwquality.conf

# Enable firewall and allow only necessary ports
ufw enable
ufw allow 22 # SSH
ufw allow 80 # HTTP
ufw allow 443 # HTTPS

# Install and configure a host-based intrusion detection system (HIDS)
apt install -y ossec-hids
sed -i 's/EMAILS=""/EMAILS="your-email@example.com"/g' /var/ossec/etc/ossec.conf
/var/ossec/bin/ossec-control start

# Limit access to sensitive system files
chmod 600 /etc/passwd
chmod 600 /etc/shadow
chmod 600 /etc/group

# Disable unused services and daemons
systemctl disable <service-name>

# Enable automatic security updates
apt install -y unattended-upgrades

# Enable auditing and monitoring
apt install -y auditd
systemctl enable auditd

# Enable secure DNS resolution
apt install -y dnssec-trigger

# Enable system log monitoring
apt install -y logwatch
