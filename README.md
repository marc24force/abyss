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
- `user/config/` is symlinked into `~/.config`; `user/service/` is symlinked into
  `~/.service` (stale links are removed).

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

## Groups

```
TARGET_USER: _seatd audio video input   # seatd session + device access (no logind ACLs on runit)
_greeter:    video _seatd               # the greeter draws its session through seatd
```

Both are set by `abyss.sh --bootstrap`. No further groups are required by the
services above.
