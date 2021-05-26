#!/usr/bin/zsh
#
_add_aliases() {
	# $1 is path to alias-file
	# $2 is header comment
	# $3 is the name of an array with strings of aliases to add
	
	if [ ! -f $1 ]; then
		print Creating alias-file at: $1
		echo "#######################" > $ZSH/aliases_hack.zsh
		echo "# Aliases for hackbox #" >> $ZSH/aliases_hack.zsh
		echo "#######################\n\n" >> $ZSH/aliases_hack.zsh
	fi
	
	print Adding alias:
	echo "\n\n" >> $1
	echo $2 >> $1
	for alias in ${(P)${array_name}}; do
		echo $alias | tee -a $1
	end

	
}
DISTRO=$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)
ALIAS_PATH=$ZSH/aliases_hack.zsh

if [ -z $DISTRO ]; then
	print Unknown distro
elif [ $DISTRO = arch ]; then
	print Requesting doas for installation...
	doas pacman -Syu go
else
	print $DISTRO is not implemented yet...
fi

## Install packages


# gron - tomnomnom
print "\n\nInstalling tomnomnom/gron"
go get -u github.com/tomnomnom/gron
alias_array=('alias ungron="gron --ungron"', 'alias norg="gron --ungron"')
_add_aliases $ALIAS_PATH "# GRON - github.com/tomnomnom/gron", "alias_array"
