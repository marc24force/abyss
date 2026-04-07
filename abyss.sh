#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF >&2
Usage: $0 [OPTIONS]

Options:
  --bootstrap   Download dependencies and configure system (requires root)
  --yes         Skip confirmation dialogs
  -h, --help        Show this help message and exit
EOF
	exit "${1:-1}"
}

DIR=$(dirname $(realpath $0))
DEP_FILE="$DIR/dependencies.txt"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

BOOTSTRAP="false"
YES_ALL="false"

while [ "$#" -gt 0 ]; do
	case "$1" in
		--bootstrap)
			BOOTSTRAP="true"
			shift
			;;
		--yes)
			shift
			YES_ALL="true"
			;;
		--help|-h)
			usage 0
			;;
		*)
			echo "Unknown argument: $1"
			usage 1
			;;
	esac
done

confirm() {
	[[ "$YES_ALL" == "true" ]] && return 0;
	read -r -p "Do you want to continue? [Y/n] " ans
	[[ ! "$ans" =~ ^[Nn]$ ]]
}

if [ "$BOOTSTRAP" = "true" ]; then

	# Check if running as root
	if [ "$(id -u)" -ne 0 ]; then
		echo "Error: --bootstrap requires root privileges." >&2
		exit 1
	fi

	# Get dependencies from file
	mapfile -t dependencies < <(grep -v '^\s*#' "$DEP_FILE" | sed '/^\s*$/d' | awk '{print $1}')

	echo "Installing dependencies and updating system"
	if confirm; then
		# Update xbps to proceed
		xbps-install -Suy xbps
		# Set mkinitcpio for initramfs
		xbps-install -y mkinitcpio
		xbps-alternatives -s mkinitcpio
		# Install all dependencies
		xbps-install -y "${dependencies[@]}"
		# Update the system and reconfigure linux for new packages
		xbps-install -uy
		xbps-reconfigure -f linux$(uname -r | cut -d. -f1-2)
	else 
		echo "Skipping..."
	fi

	# Get services from file
	mapfile -t services < <(grep -v '^\s*#' "$DEP_FILE" | grep '#service' | awk '{print (NF >= 3 ? $3 : $1) }')

	echo "Start installed services"
	if confirm; then
		# Create links for all listed services
		ln -sf $(printf "/etc/sv/%s " "${services[@]}") /var/service
		# And add _greeter user to required groups
		usermod -G _greeter,video,_seatd _greeter
	else 
		echo "Skipping..."
	fi

	echo "Copy configuration files to /etc"
	if confirm; then
		cp -rT $DIR/system/etc /etc
	else
		echo "Skipping..."
	fi

	echo "Adding ${TARGET_USER} to required groups"
	if confirm; then
		usermod -aG _seatd ${TARGET_USER}
	else
		echo "Skipping..."
	fi
fi

echo "Setting ${TARGET_USER} configuration"
if confirm; then
	mkdir -p ${TARGET_HOME}/.config
	ln -sf $DIR/user/config/* ${TARGET_HOME}/.config
	chown -R ${TARGET_USER}:${TARGET_USER} ${TARGET_HOME}/.config
else
	echo "Skipping..."
fi

echo "Creating per-user services"
if confirm; then
	mkdir -p ${TARGET_HOME}/.service
	ln -sf $DIR/user/service/* ${TARGET_HOME}/.service
	chown -R ${TARGET_USER}:${TARGET_USER} ${TARGET_HOME}/.service
else
	echo "Skipping..."
fi

echo "Rebooting to apply changes"
if confirm; then
	sudo reboot
fi
echo "Abyss configuration done"

