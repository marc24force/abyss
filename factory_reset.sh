#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF >&2
Ús: $0 [--home] [--save FITXER1,FITXER2,...]

Opcions:
  --home            Esborra el contingut del directori personal de l'usuari
  --save FITXERS    Llista separada per comes de fitxers/directoris a preservar (només funciona amb --home)
  -h, --help        Mostra aquest missatge d'ajuda

Exemples:
  $0
  $0 --home
  $0 --home --save ".bashrc,Documents"

Cal executar-lo com a root. Només quedaran els paquets de base-system.
EOF
	exit "${1:-1}"
}

# Comprovació de permisos d'administrador
if [ "$(id -u)" -ne 0 ]; then
	echo "Aquest script requereix permisos de root."
	exit 1
fi

REMOVE_HOME=0
SAVE_LIST=()

# Processament d'arguments
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
			echo "Paràmetre desconegut: $1"
			usage 1
			;;
	esac
done

# Determinem l'usuari i home reals
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

echo "Iniciant restauració del sistema (sense afectar /etc)."
[ "$REMOVE_HOME" -eq 1 ] && echo " - Contingut de $TARGET_HOME serà eliminat"
[ "${#SAVE_LIST[@]}" -gt 0 ] && echo " - Fitxers/directoris preservats: ${SAVE_LIST[*]}"
	echo
	read -rp "Continuar amb la restauració? (yes/no): " ans
	[ "$ans" = "yes" ] || exit 1
	
# Gestió del directori personal
if [ "$REMOVE_HOME" -eq 1 ]; then
	echo "Esborrant contingut de $TARGET_HOME..."
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

	echo "Restauració de contingut mínim de $TARGET_HOME..."
	cp -rT /etc/skel "$TARGET_HOME"
	chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME"
fi

# Sincronització de repositoris
echo "Actualitzant repositoris..."
xbps-install -S

# Obtenir llistat de paquets instal·lats
echo "Identificant paquets instal·lats..."
mapfile -t installed < <(xbps-query -l | awk '{print $2}' | sed 's/-[^-]*_[0-9]*$//')

# Obtenir llistat de paquets del sistema base
echo "Determinant paquets de base-system..."
mapfile -t base < <(echo "base-system"; xbps-query -Rx --fulldeptree base-system | sed 's/-[^-]*_[0-9]*$//')

declare -A base_map
for pkg in "${base[@]}"; do
	base_map["$pkg"]=1
done

# Generar llista de paquets a eliminar
remove_list=()
for pkg in "${installed[@]}"; do
	[[ -z "${base_map[$pkg]:-}" ]] && remove_list+=("$pkg")
done

# Eliminació de paquets no essencials
if [ "${#remove_list[@]}" -gt 0 ]; then
	echo "Eliminant ${#remove_list[@]} paquets no essencials..."
		xbps-remove -Ry "${remove_list[@]}"
fi

# Neteja de dependències orfes
echo "Eliminant dependències orfes..."
xbps-remove -oy

# Neteja de cache de paquets
echo "Netejant la cache de paquets..."
xbps-remove -Oy

# Gestió de /var/service
echo "Esborrant tot el contingut de /var/service..."
rm -rf /var/service/*
mkdir -p /var/service

echo "Creant symlinks per serveis imprescindibles..."
for tty in agetty-tty{1..6}; do
	ln -s "/etc/sv/$tty" "/var/service/$tty"
done
ln -s "/etc/sv/dhcpcd" "/var/service"
ln -s "/etc/sv/wpa_supplicant" "/var/service"
ln -s "/etc/sv/sshd" "/var/service"
ln -s "/etc/sv/acpid" "/var/service"

echo
echo "Restauració completada. Només queden paquets de base-system i $TARGET_HOME i /var/service han estat reconfigurats."
