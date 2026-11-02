# Abyss

Void Linux rice · greetd/regreet · seatd · niri · turnstile-runit user services

## Install

Clone anywhere, then:

```
sudo ./abyss.sh --bootstrap [--yes]   # fresh machine: xbps deps from dependencies.txt,
                                      # #service entries -> /var/service, /etc <- system/etc,
                                      # groups, reboot
./abyss.sh                            # already installed: resync user config + services
```

- `dependencies.txt`: xbps packages; entries marked `#service` get their runit service
  enabled from `/etc/sv` into `/var/service` (`turnstile #service turnstiled` renames;
  `socklog-void #service {socklog-unix,nanoklogd}` enables several).
- `system/etc/` is copied verbatim to `/etc` at bootstrap; anything under
  `system/etc/sv/` is additionally enabled as a system service.
- `system/etc/kernel.d/post-install/90-grub` regenerates `grub.cfg` on every
  kernel update (needs the `grub` package).
- `user/config/` is symlinked into `~/.config`; `user/service/` is symlinked into
  `~/.service` (stale links are removed); `user/bin/`
  is symlinked into `~/.local/bin` (add-only: your own tools are kept).

Full re-provision: `sudo ./factory_reset.sh` takes the box back to base-system
packages + your home (wpa_supplicant and dhcpcd survive as the network bridge),
then `sudo ./abyss.sh --bootstrap` rebuilds the rice — installing iwd/openresolv,
enabling their services and retiring wpa_supplicant on the way.

## User services (`~/.service` ← `user/service`)

Only session-independent daemons live here. Anything needing `WAYLAND_DISPLAY` or
`NIRI_SOCKET` is a compositor client — start it with `spawn-at-startup` in the niri
config instead, or it will read a stale session environment at login.

| service         | what it is                                                     |
|-----------------|----------------------------------------------------------------|
| dbus            | session bus; writes `~/.environment/DBUS_SESSION_BUS_ADDRESS` at login |
| pipewire        | audio server                                                   |
| pipewire-pulse  | PulseAudio-compatible endpoint                                 |
| wireplumber     | pipewire session policy                                        |
| udiskie         | removable-drive automount (needs polkitd; udisksd is dbus-activated) |
| turnstile-ready | holds login until `conf` `core_services` are up                |

System services ship under `system/etc/sv/` and are enabled by the bootstrap:

| location | boot-time IP geolocation; writes `lat lon` to `/var/cache/location`, re-fetching every `refresh` and retrying `retry` on failure. |

## Per-service `conf` files

Any service can take a `conf` file in its directory (create it in the repo and the
symlinked service picks it up); the `run` script sources it and substitutes the
variables into its exec. The supported variables and some possible variations:

| service         | conf variables                     | possible variations                                                              |
|-----------------|------------------------------------|----------------------------------------------------------------------------------|
| pipewire        | `OPTS`                             | e.g. `OPTS="-c /etc/pipewire/custom.conf"`                                        |
| pipewire-pulse  | `OPTS`                             | same idea, per-server flags                                                       |
| wireplumber     | `OPTS`                             | e.g. `OPTS="--config-file /etc/wireplumber/custom.conf"`                          |
| dbus            | `OPTS`, `DBUS_SESSION_BUS_ADDRESS` | e.g. `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus` (default)         |
| udiskie         | `OPTS`                             | combine: `--automount`, `--tray`, `--smart-tray`, `--notify`, `--filter <STR>`, `--config <file>` |
| turnstile-ready | `core_services`                    | sv names to wait for, e.g. `core_services="dbus pipewire wireplumber"`             |
| location (system)| `refresh`, `retry`                | e.g. `refresh="7d"` and `retry="10m"`                                             |

## Network

`iwd` (Wi-Fi scan/auth/roam) + `dhcpcd` (addressing) + `openresolv` (owner of
`/etc/resolv.conf`) + `openfortivpn` (work VPN, run manually). iwd runs with
`EnableNetworkConfiguration=false`, so addressing stays with dhcpcd.

Both dhcpcd and openfortivpn speak resolvconf natively: a DHCP lease refresh
while the VPN is up *merges* the two DNS sets instead of last-writer-wins.
The host-local openfortivpn config should use
`--set-dns=1 --use-resolvconf=1 --pppd-use-peerdns=0`.

Wi-Fi is driven by `user/bin/net` → `~/.local/bin/net` — a plain CLI that only
front-ends `iwctl`:

| command                | effect                                                              |
|------------------------|---------------------------------------------------------------------|
| `net status`           | `iface=… state=… ssid=… ip=…` (machine-parseable)                    |
| `net scan [n=6]`       | scan and list the n strongest networks (`*` = currently connected)   |
| `net connect <ssid>`   | connect; iwctl itself asks for the passphrase on first use and iwd saves the profile |
| `net disconnect`       | disconnect the station                                               |
| `net ls`               | saved networks (name + security)                                     |
| `net forget <ssid>`    | remove a saved profile (via `iwctl known-networks`)                  |
| `net provision <ssid>` | 802.1X questionnaire (PEAP/TTLS); needs the admin password once |

Privileges: `system/etc/sudoers.d/30-net` grants passwordless `/usr/bin/iwctl`
to the `network` group only — and `net` uses no other privileged command:
profiles are managed through `iwctl known-networks` (never by touching
`/var/lib/iwd` directly). Passphrases and 802.1X secrets live in
`/var/lib/iwd`, never in this repo. `iwctl` colorizes its tables even when
piped — `net` strips the ANSI escapes before parsing.

## Groups

```
TARGET_USER: _seatd audio video input network   # seatd + nodes + Wi-Fi control (sudoers.d/30-net)
_greeter:    video _seatd                       # the greeter draws its session through seatd
```

Both are set by `abyss.sh --bootstrap`. The `network` group otherwise does
nothing: it only unlocks `iwctl` via `system/etc/sudoers.d/30-net`.
