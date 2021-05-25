#!/usr/bin/zsh
DISTRO=$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)

if [ -z $DISTRO ]; then
	print Unknown distro
elif [ $DISTRO = arch ]; then
	print Requesting doas for installation...
	doas pacman -Syu go
else
	print $DISTRO is not implemented yet...
fi

## Install packages

if [ ! -f "$ZSH/aliases_hack.zsh" ]; then
	echo "# Aliases for hackbox" > $ZSH/aliases_hack.zsh
fi

# gron - tomnomnom
print Installing tomnomnom/gron
go get -u github.com/tomnomnom/gron
print Adding aliases:
echo "# Gron - github.com/tomnomnom/gron" >> $ZSH/aliases_hack.zsh
echo 'alias norg="gron --ungron"' | tee -a $ZSH/aliases_hack.zsh
echo 'alias ungron="gron --ungron"' | tee -a $ZSH/aliases_hack.zsh

