#!/usr/bin/env bash

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
	read -r -p "Continue? [y/N] " ans
	[[ "$ans" =~ ^[Yy]$ ]]
}

install() {
	echo "Installing required packages and updating system"
	sudo xbps-install -Su $yes xbps
	sudo xbps-install -u $yes
	sudo xbps-install $yes "${install_packages[@]}"
}

install_packages=(neovim niri git)

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

[[ "$sudo" == "true" ]] && install


