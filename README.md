# Orchard

My Arch configuration for Apple silicon Macs (Asahi Linux).

# Install

On an M1/M2 machine:

```
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

After rebooting into arch, connect to wifi and install:

```
nmtui
pacman -Sy --noconfirm git
git clone https://github.com/pachun/orchard /tmp/orchard
bash /tmp/orchard/setup/bootstrap.sh
```
