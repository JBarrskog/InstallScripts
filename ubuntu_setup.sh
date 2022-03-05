#!/usr/bin/bash

if [[ $EUID -ne 0 ]]
  then echo "Please run as root"
  exit
fi
##################################
## Install QEMU guest agent (for Proxmox VM)
##################################
install qemu-guest-agent
systemctl start qemu-guest-agent

##################################
## Hardening
##################################
chmod -R 750 /home/$USER
chmod -R 700 /home/$USER/.ssh
chmod -R 600 /home/$USER/.ssh/authorized_keys
chmod 600 /etc/at.deny
chmod 600 /etc/crontab
chmod 600 /etc/ssh/sshd_config
chmod 700 /etc/cron.d
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.monthly

# Disable core dump
sed -i 's/\#\*               soft    core            0/\*                soft    core            0\n\*                hard    core            0/g' /etc/security/limits.conf

##################################
## Install Open SSH
##################################
apt install openssh-server

##################################
## Configure OpenSSH
##################################
rm /etc/ssh/sshd_config
touch /etc/ssh/sshd_config

echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "X11Forwarding no" >> /etc/ssh/sshd_config

echo "HostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config
echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> /etc/ssh/sshd_config
##################################
## Secure SSH according to ssh-audit.com/hardening_guides.html
##################################
# Re-generate the RSA and ED25519 keys
rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Remove small Diffie-Hellman moduli
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Enable the RSA and ED25519 keys
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config

# Restrict supported key exchange, cipher, and MAC algorithms
echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf

# Restart OpenSSH service
service ssh restart
