# Gnome Keyring Setup

Automatic keyring unlock at TTY login via PAM. Apps like Nextcloud client store credentials in the keyring and find them after reboot without re-authentication.

## How it works

PAM runs `pam_gnome_keyring.so` at TTY login:
- `auth` phase: captures the login password
- `session` phase: starts `gnome-keyring-daemon` and unlocks the `login` keyring using the captured password

The keyring password must match the login password. The systemd socket unit (`gnome-keyring-daemon.socket`) must be masked — if it starts the daemon first, it claims the D-Bus name before PAM can unlock the `login` collection, breaking auto-unlock.

## What install.sh does

- Adds `pam_gnome_keyring.so` to `/etc/pam.d/login` (auth + session)
- Adds `pam_gnome_keyring.so` to `/etc/pam.d/passwd` so the keyring password stays in sync when the login password changes
- Masks `gnome-keyring-daemon.socket` and `gnome-keyring-daemon.service`

No xinitrc changes needed — PAM starts the daemon before `startx` runs, and i3 inherits the unlocked keyring via the environment.

## Manual setup

### 1. Install packages

```bash
sudo pacman -S gnome-keyring libsecret
```

### 2. Configure PAM

`/etc/pam.d/login`:

```
#%PAM-1.0

auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
password   include      system-local-login
session    optional     pam_gnome_keyring.so auto_unlock
```

`/etc/pam.d/passwd` — append:

```
password   optional     pam_gnome_keyring.so
```

### 3. Mask the systemd units

```bash
systemctl --user mask gnome-keyring-daemon.socket gnome-keyring-daemon.service
```

### 4. Log out and back in

Full TTY logout (`exit`) and re-login. The `login` keyring is created on first use with the login password as keyring password.

## Verification

```bash
busctl --user list | grep secrets
# org.freedesktop.secrets should show a PID, not just (activatable)

secret-tool store --label='test' service test account test
# Password: prompt asks for the VALUE to store, not a keyring unlock
secret-tool lookup service test account test
```

## Troubleshooting

**"Cannot create an item in a locked collection"** — the `default` keyring file has a different password than the login password. Delete it and re-login:

```bash
rm ~/.local/share/keyrings/Default_keyring.keyring
echo -n "login" > ~/.local/share/keyrings/default
```

Then log out and back in.

**"Object does not exist at path /org/freedesktop/secrets/collection/login"** — the systemd socket daemon started before PAM could create the `login` collection. Make sure the units are masked:

```bash
systemctl --user mask gnome-keyring-daemon.socket gnome-keyring-daemon.service
systemctl --user stop gnome-keyring-daemon.socket gnome-keyring-daemon.service
killall gnome-keyring-daemon
```

Then log out and back in.

**Keyring not unlocked after re-login** — check that the keyring password matches the login password. Delete `~/.local/share/keyrings/login.keyring` and re-login to let PAM recreate it.
