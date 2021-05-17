# Run this script after "arch-chroot /mnt"


## ADD PARSING OF INPUT!
# * Username
# * Hostname
# * Local url-thing (FQDN)

ln -sf /usr/share/zoneinfo/Europe/Stockholm /etc/localtime
hwclock --systohc

# Adding locales
sed -i 's/^\#en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/^\#sv_SE.UTF-8 UTF-8$/sv_SE.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

# Create locale.conf
echo -e "LANG=sv_SE.UTF-8\nLC_MESSAGES=en_US.UTF-8" > /etc/locale.conf

# Setup hostname
echo $1 > /etc/hostname
echo -e "127.0.0.1\t\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t\t$1.$2\t$1"  >> /etc/hosts

##################################
## Install packages
##################################
# Required for bootmanager and UEFI-install
pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools

# Packages
pacman -S --noconfirm 	networkmanager \\
			vim \\
			openssh \\
			zsh \\
			doas \\
			man-db \\
			man-pages \\
			texinfo \\
			htop \\
			tmux \\
			exa

##################################
## Setup users
##################################

# Create user with username from input
useradd -m -G wheel -s /bin/zsh $3

# Change password of the new user
echo "SET PASSWORD OF USER: $3:"
passwd $3

# Add user to doas
echo "permit :wheel as root" > /etc/doas.conf

##################################
## Setup boot manager
##################################
echo "SETTING UP BOOTLOADER:"
mkdir /boot/EFI
mount /dev/sda1 /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
grub-mkconfig -o /boot/grub/grub.cfg
echo "BOOTLOADER: DONE."

##################################
## Setup NetworkManager
##################################
systemctl enable NetworkManager

##################################
## Setup ssh-keys and settings
##################################
echo "SETTING UP SSH-KEYS"

# Install keys and start enable sshd.service
mkdir /home/$3/.ssh
curl https://github.com/jbarrskog.keys > /home/$3/.ssh/authorized_keys

# Creating own RSA-keypair
ssh-keygen -C "$(whoami)@$(uname -n)-$(date -I)"

# Enable sshd on boot, and start immediately
systemctl enable sshd --now
echo "SSH-KEYS: DONE."

##################################
## Secure SSH according to ssh-audit.com/hardening_guides.html
# Unfortunately, these commands are for Ubuntu 20.04 LTS, but I suppose they will work...
##################################

# Create defaults, and move arch-initial config
mkdir /etc/ssh/sshd_config.d
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.d/arch_default
echo "Include /etc/ssh/sshd_config.d/*.conf" > /etc/ssh/sshd_config

# Prevent password auth
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Prevent SSH to root
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# TODO: Add more sshd-settings?

# Generate new keys
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Remove small Diffie-Hellman moduli
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Restrict supported key exchang, cipher, and MAC algorithms
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config

echo -e "\n# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\nKexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\nHostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com" > /etc/ssh/sshd_config.d/ssh-audit_hardening.conf

##################################
## Unmount and shutdown
##################################

# Quit the chroot
exit

# Unmount
umount -R /mnt
echo -e "Done. VM will reboot in 5 seconds.\nRemember to remove install-media, and prehaps make alterations in Proxmox settings:\nhttps://pve.proxmox.com/wiki/OVMF/UEFI_Boot_Entries"
sleep 5
shutdown now
