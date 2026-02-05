# Email Setup

Terminal email using `aerc` (client) and `mbsync` (IMAP sync).

## Prerequisites

- `pass` configured with GPG key for password storage
- IMAP/SMTP credentials from your email provider

## 1. Store Passwords

```bash
pass insert mail/your@email.com
```

## 2. Configure mbsync

Copy and edit the template:

```bash
cp ~/.mbsyncrc.template ~/.mbsyncrc
chmod 600 ~/.mbsyncrc
nvim ~/.mbsyncrc
```

Replace placeholders:
- `your@email.com` - your email address
- `imap.example.com` - your provider's IMAP server
- `account1` - short account name (e.g., `personal`, `work`)

## 3. Create Mail Directory

```bash
mkdir -p ~/.local/share/mail/your@email.com
```

## 4. Initial Sync

```bash
mbsync -aV
```

This downloads all mail. First sync may take a while.

## 5. Configure aerc

Copy and edit the template:

```bash
cp ~/.config/aerc/accounts.conf.template ~/.config/aerc/accounts.conf
chmod 600 ~/.config/aerc/accounts.conf
nvim ~/.config/aerc/accounts.conf
```

Replace placeholders:
- `your@email.com` - your email address
- `Your Name` - display name for outgoing mail
- `smtp.example.com` - your provider's SMTP server
- `account1` - must match the name used in mbsyncrc

## 6. Folder Remapping (Optional)

If your provider uses non-standard folder names, create a remap file:

```bash
cp ~/.config/aerc/remap/example.conf.template ~/.config/aerc/remap/provider.conf
nvim ~/.config/aerc/remap/provider.conf
```

Then reference it in `accounts.conf`:

```ini
folder-map = ~/.config/aerc/remap/provider.conf
```

## 7. Launch aerc

```bash
aerc
```

Key bindings:
- `Ctrl+s` - sync mail (runs mbsync)
- `j/k` - navigate messages
- `Enter` - view message
- `C` or `m` - compose
- `rq` - reply with quote
- `d` - delete
- `a` - archive
- `q` - quit

## Auto-Sync (Optional)

Create systemd user units for periodic sync:

```bash
mkdir -p ~/.config/systemd/user
```

`~/.config/systemd/user/mbsync.service`:
```ini
[Unit]
Description=Mailbox sync

[Service]
Type=oneshot
ExecStart=/usr/bin/mbsync -a
```

`~/.config/systemd/user/mbsync.timer`:
```ini
[Unit]
Description=Mailbox sync timer

[Timer]
OnBootSec=1m
OnUnitActiveSec=5m

[Install]
WantedBy=timers.target
```

Enable:
```bash
systemctl --user enable --now mbsync.timer
```

## Multiple Accounts

Add additional account blocks to both `~/.mbsyncrc` and `~/.config/aerc/accounts.conf`. Use unique account names for each.

## Troubleshooting

**Folders not showing**: Check `Patterns` in mbsyncrc matches server folder names. Run `mbsync -l account1` to list remote folders.

**Sent mail not saved**: Verify `copy-to` in accounts.conf matches actual Sent folder name.
