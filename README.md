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
`/etc/resolv.conf`) + `openfortivpn` (VPN tunnels — see [VPN](#vpn) below).
iwd runs with `EnableNetworkConfiguration=false`, so addressing stays with
dhcpcd.

Both dhcpcd and openfortivpn speak resolvconf natively: a DHCP lease refresh
while the VPN is up *merges* the two DNS sets instead of last-writer-wins
(the per-profile openfortivpn configs are generated host-side with
`set-dns = 1`, `use-resolvconf = 1` and `pppd-use-peerdns = 0`).

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

## VPN

`openfortivpn` tunnels, one at a time, per user: profiles live in
`~/.config/vpn/<name>/` (`vpn.conf` + `secret`, 0600 — host-local, never in
this repo). `user/bin/vpn` → `~/.local/bin/vpn` front-ends them:

| command               | effect                                                                    |
|-----------------------|---------------------------------------------------------------------------|
| `vpn status`          | one line per supervised profile (`name state=… ip=…`, machine-parseable)   |
| `vpn ls`              | profiles + auth mode + boot behaviour + current state                     |
| `vpn up <profile>`    | connect; asks for the one-time code on otp, prints and opens the login link on saml |
| `vpn down <profile>`  | disconnect                                                                |
| `vpn on <profile>`    | auto-start at boot (a single profile stays active; others are demoted)     |
| `vpn off <profile>`   | no auto-start at boot                                                     |
| `vpn add <profile>`   | questionnaire: gateway, port, auth mode, realm, trusted-cert              |
| `vpn forget <profile>`| remove the profile and its generated service                              |
| `vpn log <profile>`   | show the connection log                                                   |

Auth modes (`auth=` in the profile): `password` (stored in `secret`, fully
unattended — the only mode that makes sense with `vpn on`), `otp` (password +
one-time code typed at every `vpn up`), `saml` (browser login via
`--saml-login`: the CLI prints and opens the link).

Supervision is plain runit, system-level so it survives logout:
`/etc/abyss/vpn-ctl` — the only privileged command, granted to the `network`
group via `system/etc/sudoers.d/30-vpn` — generates an `/etc/sv/vpn-<name>`
stub per profile and links it into `/var/service`. Auto-start at boot is just
the link without a `down` file; nothing else. Secrets travel
stdin → `/run/vpn/<name>.secret` → a generated openfortivpn config
(`/run/vpn/<name>.conf`, 0600 root, tmpfs) — never argv, never visible in
`ps`. Failed connects back off linearly (15 s per try, capped at 300 s);
`vpn up` cuts the wait short.

State lands in `/run/vpn/status` — one `name state=… since=… ip=…` line per
profile, 0644, atomically rewritten.

## Groups

```
TARGET_USER: _seatd audio video input network   # seatd + nodes + Wi-Fi/VPN control (sudoers.d/30-net, 30-vpn)
_greeter:    video _seatd                       # the greeter draws its session through seatd
```

Both are set by `abyss.sh --bootstrap`. The `network` group otherwise does
nothing: it only unlocks `iwctl` (sudoers.d/30-net) and `vpn-ctl`
(sudoers.d/30-vpn).
