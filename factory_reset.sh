#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF >&2
Usage: $0 [--home] [--save FILE1,FILE2,...]

Options:
  --home            Wipe the contents of the user's home directory
  --save FILES      Comma-separated list of files/directories to preserve (only with --home)
  -h, --help        Show this help message

Examples:
  $0
  $0 --home
  $0 --home --save ".bashrc,Documents"

Must run as root. Only base-system packages will remain.
EOF
	exit "${1:-1}"
}

# root check
if [ "$(id -u)" -ne 0 ]; then
	echo "This script requires root."
	exit 1
fi

REMOVE_HOME=0
SAVE_LIST=()

# argument parsing
while [ "$#" -gt 0 ]; do
	case "$1" in
		--home)
			REMOVE_HOME=1
			shift
			;;
		--save)
			shift
			IFS=',' read -ra SAVE_LIST <<< "$1"
			shift
			;;
		--help|-h)
			usage 0
			;;
		*)
			echo "Unknown parameter: $1"
			usage 1
			;;
	esac
done

# resolve the real user and home
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

echo "Starting system restore (leaving /etc untouched)."
[ "$REMOVE_HOME" -eq 1 ] && echo " - Contents of $TARGET_HOME will be deleted"
[ "${#SAVE_LIST[@]}" -gt 0 ] && echo " - Preserved files/directories: ${SAVE_LIST[*]}"
echo
read -rp "Continue with the restore? (yes/no): " ans
[ "$ans" = "yes" ] || exit 1

# home directory handling
if [ "$REMOVE_HOME" -eq 1 ]; then
	echo "Deleting contents of $TARGET_HOME..."
	shopt -s dotglob
	for entry in "$TARGET_HOME"/* "$TARGET_HOME"/.*; do
		base_entry=$(basename "$entry")
		[[ "$base_entry" == "." || "$base_entry" == ".." ]] && continue
		skip=0
		for keep in "${SAVE_LIST[@]}"; do
			[[ "$base_entry" == "$keep" || "$base_entry/" == "$keep" ]] && skip=1 && break
		done
		[ $skip -eq 0 ] && rm -rf "$entry"
	done
	shopt -u dotglob

	echo "Restoring minimal contents of $TARGET_HOME..."
	cp -rT /etc/skel "$TARGET_HOME"
	chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME"
fi

# repository sync
echo "Updating repositories..."
xbps-install -S

# installed package list
echo "Identifying installed packages..."
mapfile -t installed < <(xbps-query -l | awk '{print $2}' | sed 's/-[^-]*_[0-9]*$//')

# base-system package list
echo "Determining base-system packages..."
mapfile -t base < <(echo "base-system"; xbps-query -Rx --fulldeptree base-system | sed 's/-[^-]*_[0-9]*$//')

declare -A base_map
for pkg in "${base[@]}"; do
	base_map["$pkg"]=1
done

# build the removal list
remove_list=()
for pkg in "${installed[@]}"; do
	[[ -z "${base_map[$pkg]:-}" ]] && remove_list+=("$pkg")
done

# remove non-essential packages
if [ "${#remove_list[@]}" -gt 0 ]; then
	echo "Removing ${#remove_list[@]} non-essential packages..."
	xbps-remove -Ry "${remove_list[@]}"
fi

# orphan sweep
echo "Removing orphaned dependencies..."
xbps-remove -oy

# package cache cleanup
echo "Cleaning the package cache..."
xbps-remove -Oy

# /var/service handling
echo "Deleting everything under /var/service..."
rm -rf /var/service/*
mkdir -p /var/service

# generated per-profile VPN units are host-local — sweep them too
rm -rf /etc/sv/vpn-* /run/vpn

echo "Creating symlinks for essential services..."
for tty in agetty-tty{1..6}; do
	ln -s "/etc/sv/$tty" "/var/service/$tty"
done
ln -s "/etc/sv/dhcpcd" "/var/service"
# wifi must outlive the purge: the next --bootstrap needs the network
ln -s "/etc/sv/wpa_supplicant" "/var/service"
ln -s "/etc/sv/sshd" "/var/service"
ln -s "/etc/sv/acpid" "/var/service"

echo
echo "Restore complete. Only base-system packages remain, and $TARGET_HOME and /var/service have been reconfigured."
