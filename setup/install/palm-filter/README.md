# palm-filter

Userspace palm-rejection shim for the built-in Apple MTP trackpad on
Asahi Linux. libinput's quirks expose only `TOUCH_MAJOR`/pressure thresholds,
which can't separate fingertips from palms on this trackpad. This daemon
grabs `/dev/input/event2` exclusively, classifies each contact via
`WIDTH_MAJOR` / `WIDTH_MINOR`, and re-emits a cleaned event stream through
a uinput virtual device that libinput picks up automatically.

## Install

```
bash install.sh
```

Idempotent. Builds in release mode, installs the binary to
`/usr/local/bin/palm-filter`, drops the systemd unit at
`/etc/systemd/system/palm-filter.service`, and enables it.

## Algorithm

Per touch slot, sticky from contact start to release:

- `WIDTH_MAJOR > PF_WMAJ_PALM` → Palm (drop all events)
- `WIDTH_MINOR >= PF_WMIN_FINGER` → Finger (forward events)
- otherwise → Pending (drop until classified or 500ms timeout)

A Finger that later exceeds `PF_WMAJ_PALM` is cancelled (TID=-1 sent to
libinput).

## Tuning

Thresholds are `Environment=` lines in `palm-filter.service`. Defaults
were fitted against an M-series MacBook trackpad (vendor 0x05ac, product
0x0351):

- `PF_WMAJ_PALM=2200`
- `PF_WMIN_FINGER=1300`
- `PF_PENDING_TIMEOUT_MS=500`

If a different machine drops fingers or leaks palms, capture fresh data
and re-fit:

```
sudo libinput record /dev/input/event2 -o /tmp/tp.yml
# do palm rest 3s, pause, one-finger move 3s, pause, two-finger scroll 3s
# Ctrl+C
```

…then inspect width/touch axis ranges per contact and pick thresholds
between the finger and palm clusters.

## Disable

```
sudo systemctl disable --now palm-filter.service
```

The original trackpad becomes accessible to libinput again immediately
(grab is released on process exit).
