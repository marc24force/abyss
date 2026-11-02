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
		# Update the system and reconfigure the newest installed kernel series
		xbps-install -uy
		kpkg=$(xbps-query -l | awk '{print $2}' | grep -E '^linux[0-9]+(\.[0-9]+)?-[0-9]' | sort -V | tail -n1 | cut -d- -f1)
		xbps-reconfigure -f "$kpkg"
	else 
		echo "Skipping..."
	fi

	# Get services from file
	mapfile -t services < <(grep -v '^\s*#' "$DEP_FILE" | grep '#service' | awk '{print (NF >= 3 ? $3 : $1) }')

	# Protect against command injection 
	for svc in "${services[@]}"; do
		if [[ "$svc" =~ [\$\;#\`] ]]; then
			echo "Unsafe service entry detected: '$svc'"
			exit 1
		fi
	done
	
	echo "Start installed services"
	if confirm; then
		# Create links for all listed services
		eval ln -sf $(printf "/etc/sv/%s " "${services[@]}") /var/service
	else 
		echo "Skipping..."
	fi

	echo "Copy configuration files to /etc"
	if confirm; then
		cp -rT $DIR/system/etc /etc
	else
		echo "Skipping..."
	fi

	echo "Enable services shipped by Abyss"
	if confirm; then
		for d in "$DIR"/system/etc/sv/*; do
			[ -d "$d" ] || continue
			ln -sf "/etc/sv/$(basename "$d")" /var/service
		done
	else
		echo "Skipping..."
	fi

	echo "Retiring wpa_supplicant"
	if confirm; then
		rm -f /var/service/wpa_supplicant
	else
		echo "Skipping..."
	fi

	echo "Adding required groups"
	if confirm; then
		getent group _seatd >/dev/null 2>&1 && usermod -aG _seatd _greeter
		getent group video  >/dev/null 2>&1 && usermod -aG video _greeter
		# runit has no logind ACLs: device access comes from plain groups
		for g in _seatd audio video input network; do
			getent group "$g" >/dev/null 2>&1 && usermod -aG "$g" "${TARGET_USER}"
		done
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
	# remove stale links first
	find ${TARGET_HOME}/.service -mindepth 1 -maxdepth 1 -type l -delete
	for d in "$DIR"/user/service/*; do
		[ -d "$d" ] || continue
		ln -sf "$d" "${TARGET_HOME}/.service/$(basename "$d")"
	done
	chown -R ${TARGET_USER}:${TARGET_USER} ${TARGET_HOME}/.service
else
	echo "Skipping..."
fi

echo "Syncing user bins (~/.local/bin)"
if confirm; then
	mkdir -p ${TARGET_HOME}/.local/bin
	# add-only: users may keep their own tools there
	for f in "$DIR"/user/bin/*; do
		[ -f "$f" ] || continue
		ln -sf "$f" "${TARGET_HOME}/.local/bin/$(basename "$f")"
	done
	chown -R ${TARGET_USER}:${TARGET_USER} ${TARGET_HOME}/.local/bin
else
	echo "Skipping..."
fi

echo "Rebooting to apply changes"
if confirm; then
	sudo reboot
fi
echo "Abyss configuration done"

