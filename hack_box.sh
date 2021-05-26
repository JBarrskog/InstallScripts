#!/usr/bin/zsh
#
_add_settings() {
	# $1 is path to alias-file
	# $2 is header comment
	# $3 is the name of an array with strings of settings to add
	
	if [ ! -f $1 ]; then
		print Creating alias-file at: $1
		echo "#######################" > $ZSH/aliases_hack.zsh
		echo "# Aliases for hackbox #" >> $ZSH/aliases_hack.zsh
		echo "#######################\n\n" >> $ZSH/aliases_hack.zsh
	fi
	
	print Adding settings:
	echo "\n\n" >> $1
	echo $2 >> $1
	for setting in ${(P)${array_name}}; do
		echo $setting | tee -a $1
	done

	
}
DISTRO=$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)
ALIAS_PATH=$ZSH/hacking_settings.zsh
CURRENT_DIR=$PWD

if [ -z $DISTRO ]; then
	print Unknown distro
elif [ $DISTRO = arch ]; then
	print Requesting doas for installation...
	if ! type go > /dev/null; then
	    doas pacman -Syu --noconfirm go
	fi
else
	print $DISTRO is not implemented yet...
fi

## Install packages

if ! type gron > /dev/null; then
    # gron - tomnomnom
    print "\n\nInstalling tomnomnom/gron"
    go get -u github.com/tomnomnom/gron
    settings_array=('alias ungron="gron --ungron"', 'alias norg="gron --ungron"')
    _add_settings $ALIAS_PATH "# GRON - github.com/tomnomnom/gron", "settings_array"
fi
    
if ! type gron > /dev/null; then
    # assetfinder - tomnomnom
    print "\n\nInstalling tomnomnom/assetfinder"
    go get -u github.com/tomnomnom/assetfinder
fi
    
if ! type gron > /dev/null; then
    # gf - tomnomnom
    print "\n\nInstalling tomnomnom/gf"
    go get -u github.com/tomnomnom/gf
    settings_array=('source $HOME/go/**/gf-completion.zsh')
fi
    
if ! type gron > /dev/null; then
    # meg - tomnomnom
    print "\n\nInstalling tomnomnom/meg"
    go get -u github.com/tomnomnom/meg
fi
    
if ! type httprobe > /dev/null; then
    # httprobe - tomnomnom
    print "\n\nInstalling tomnomnom/httprobe"
    go get -u github.com/tomnomnom/httprobe
fi
    
if ! type anew > /dev/null; then
    # anew - tomnomnom
    print "\n\nInstalling tomnomnom/anew"
    go get -u github.com/tomnomnom/anew
fi
    
if ! type waybackurls > /dev/null; then
    # waybackuprls - tomnomnom
    print "\n\nInstalling tomnomnom/waybackurls"
    go get github.com/tomnomnom/waybackurls
fi

if ! type amass > /dev/null; then
    # amass - OWASP
    print "\n\nInstalling OWASP/amass"
    go get -v github.com/OWASP/Amass/cmd/amass
fi
    
if ! type ffuf > /dev/null; then
    # fuff - fuff
    print "\n\nInstalling ffuf/ffuf"
    go get -u github.com/ffuf/ffuf
fi
    
if ! type gobuster > /dev/null; then
    # gobuster - OJ
    print "\n\nInstalling OJ/gobuster"
    go install github.com/OJ/gobuster/v3@latest
fi
    
if ! type hakrawler > /dev/null; then
    # hakrawler - hakluke
    print "\n\nInstalling hakluke/hakrawler"
    go get github.com/hakluke/hakrawler
fi

if ! type subfinder > /dev/null; then
    # subfinder - projectdiscovery
    print "\n\nInstalling projectdiscovery/subfinder"
    go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
fi
    
    
if ! type masscan > /dev/null; then
    # masscan - robertdavidgraham
    print "\n\nInstalling robertdavidgraham/masscan"
    if [ -d ~/builds/masscan ]; then
        print "Found directory ~/builds/masscan, without successful installation. Removing directory..."
        rm -rf ~/builds/masscan
    fi
    /usr/bin/zsh -ic git clone https://github.com/robertdavidgraham/masscan ~/builds/masscan
    cd ~/builds/masscan
    make -j
    doas make install
    cd $CURRENT_DIR
fi
    
if ! type nmap > /dev/null; then
    # nmap - nmap
    print "\n\nInstalling nmap/nmap"
    if [ -d ~/builds/nmap ]; then
        print "Found directory ~/builds/nmap, without successful installation. Removing directory..."
        rm -rf ~/builds/nmap
    fi
    git clone https://github.com/nmap/nmap.git ~/builds/nmap
    cd ~/builds/nmap
    ./configure
    make -j
    doas make install
    cd $CURRENT_DIR
fi

if [ ! -d /usr/share/SecLists ]; then
    doas git clone https://github.com/danielmiessler/SecLists.git /usr/share/SecLists
else
    cd /usr/share/SecLists
    git pull
    cd $CURRENT_DIR
fi
