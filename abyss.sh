#!/usr/bin/env bash

DIR=$(dirname $0)

usage() {
	echo "Usage: $0 [--help] [--no-sudo]"
	echo
	echo "  --help     Show this help message and exit"
	echo "  --no-sudo  Skip all the steps that require sudo"
	echo "  --yes      Skip confirmation dialogs"
	exit 1
}

confirm() {
	[[ "$yes" == "-y" ]] && return 0;
	read -r -p "Do you want to continue? [Y/n] " ans
	[[ ! "$ans" =~ ^[Nn]$ ]]
}

install() {
	echo "Installing required packages and updating system"
	sudo xbps-install -Su $yes xbps
	sudo xbps-install $yes mkinitcpio
	sudo xbps-alternatives -s mkinitcpio
	sudo xbps-install -u $yes
	sudo xbps-install $yes "${install_packages[@]}"
	sudo xbps-reconfigure -f linux$(uname -r | cut -d. -f1-2)
}

services() {
	echo "Start installed services"
	if confirm; then
		sudo ln -sf /etc/sv/dbus /var/service
		sudo ln -sf /etc/sv/seatd /var/service
		sudo ln -sf /etc/sv/turnstiled /var/service
		sudo ln -sf /etc/sv/greetd /var/service
		sudo usermod -G _greeter,video,_seatd _greeter
		sudo ln -sf /etc/sv/iwd /var/service
		sudo rm /var/service/wpa_supplicant -rf
	else
		echo "Skipping..."
	fi
}

etcfiles(){
	echo "Copy configuration files to /etc"
	if confirm; then
		sudo cp -rT $DIR/system/etc /etc
	else
		echo "Skipping..."
	fi
}
conffiles(){
	echo "Copy configuration files to .config/"
	if confirm; then
		cp -rT $DIR/user/config ~/.config
	else
		echo "Skipping..."
	fi
}
userservices(){
	echo "Creating per-user services"
	if confirm; then
		cp -rT $DIR/user/service ~/.service
	else
		echo "Skipping..."
	fi
}

# System basics
install_packages=(greetd ReGreet mesa-dri)
# Seat, session, bus, network
install_packages+=(seatd turnstile dbus iwd)
install_packages+=(xdg-desktop-portal xdg-desktop-portal-wlr)
# Important apps
install_packages+=(git curl wget base-devel qt6-wayland xwayland-satellite)
# Opinated apps
install_packages+=(neovim niri foot swww quickshell qutebrowser)
# Other useful apps
install_packages+=(wlsunset jq qt6-shadertools)
# Fonts
install_packages+=(nerd-fonts dejavu-fonts-ttf font-hack-ttf xorg-fonts)

sudo="true"
yes=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help)
			usage ;;
		--no-sudo)
			sudo="false"
			shift ;;
		--yes)
			yes="-y"
			shift ;;
	esac
done

conffiles
userservices

[[ "$sudo" == "true" ]] && install
[[ "$sudo" == "true" ]] && etcfiles
[[ "$sudo" == "true" ]] && services
