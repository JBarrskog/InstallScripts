#!/usr/bin/bash

##################################
## Install QEMU guest agent (for Proxmox VM)
##################################
sudo apt install qemu-guest-agent
sudo systemctl start qemu-guest-agent

##################################
## Hardening
##################################
sudo chmod -R 750 /home/$USER
sudo chmod -R 700 /home/$USER/.ssh
sudo chmod -R 600 /home/$USER/.ssh/authorized_keys
sudo chmod 600 /etc/at.deny
sudo chmod 600 /etc/crontab
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 700 /etc/cron.d
sudo chmod 700 /etc/cron.hourly
sudo chmod 700 /etc/cron.daily
sudo chmod 700 /etc/cron.weekly
sudo chmod 700 /etc/cron.monthly

# Disable core dump
sudo sed -i 's/\#\*               soft    core            0/\*                soft    core            0\n\*                hard    core            0/g' /etc/security/limits.conf

##################################
## Install Open SSH
##################################
sudo apt install openssh-server

##################################
## Configure OpenSSH
##################################
sudo rm /etc/ssh/sshd_config

echo "Include /etc/ssh/sshd_config.d/*.conf" | sudo tee /etc/ssh/sshd_config > /dev/null

echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "PermitEmptyPasswords no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config > /dev/null

echo "HostKey /etc/ssh/ssh_host_rsa_key" | sudo tee -a /etc/ssh/sshd_config > /dev/null
echo "HostKey /etc/ssh/ssh_host_ed25519_key" | sudo tee -a /etc/ssh/sshd_config > /dev/null

##################################
## Secure SSH according to ssh-audit.com/hardening_guides.html
##################################
# Re-generate the RSA and ED25519 keys
sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Remove small Diffie-Hellman moduli
sudo awk '$5 >= 3071' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.safe > /dev/null
sudo mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Enable the RSA and ED25519 keys
sudo sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config

# Restrict supported key exchange, cipher, and MAC algorithms
echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms
curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers
chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs
hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms
ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com"
| sudo tee /etc/ssh/sshd_config.d/ssh-audit_hardening.conf > /dev/null

# Restart OpenSSH service
sudo service ssh restart
