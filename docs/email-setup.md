# Email Setup

Terminal email using `aerc` (client), `mbsync` (IMAP sync), and `msmtp` (SMTP with offline queue).

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

## 3. Configure msmtp

Copy and edit the example:

```bash
cp ~/.config/msmtp/config.example ~/.config/msmtp/config
chmod 600 ~/.config/msmtp/config
nvim ~/.config/msmtp/config
```

Replace placeholders:
- `your@email.com` - your email address
- `smtp.example.com` - your provider's SMTP server
- `account1` - short account name

## 4. Create Mail Directory

```bash
mkdir -p ~/.local/share/mail/your@email.com
```

## 5. Initial Sync

```bash
mbsync -aV
```

This downloads all mail. First sync may take a while.

## 6. Configure aerc

Copy and edit the template:

```bash
cp ~/.config/aerc/accounts.conf.template ~/.config/aerc/accounts.conf
chmod 600 ~/.config/aerc/accounts.conf
nvim ~/.config/aerc/accounts.conf
```

Replace placeholders:
- `your@email.com` - your email address
- `Your Name` - display name for outgoing mail
- `account1` - must match the name used in mbsyncrc and msmtp config

## 7. Folder Remapping (Optional)

If your provider uses non-standard folder names, create a remap file:

```bash
cp ~/.config/aerc/remap/example.conf.template ~/.config/aerc/remap/provider.conf
nvim ~/.config/aerc/remap/provider.conf
```

Then reference it in `accounts.conf`:

```ini
folder-map = ~/.config/aerc/remap/provider.conf
```

## 8. Launch aerc

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

## Auto-Sync with goimapnotify

`goimapnotify` uses IMAP IDLE to maintain a persistent connection to the mail server. When new mail arrives, the server pushes a notification instantly and goimapnotify triggers `mbsync`. If the server doesn't support IDLE, it falls back to polling every 15 minutes.

### Configure goimapnotify

```bash
cp ~/.config/imapnotify/account1.conf.yaml.example ~/.config/imapnotify/account1.conf.yaml
nvim ~/.config/imapnotify/account1.conf.yaml
```

Replace placeholders to match your mbsyncrc (host, username, passwordCMD, account name).

### Run

```bash
goimapnotify -conf ~/.config/imapnotify/account1.conf.yaml
```

For multiple accounts, create one config file per account and run one instance each.

### Autostart

The `mailnotify` script in `~/.local/bin/` validates and launches `goimapnotify` for all config files in `~/.config/imapnotify/` (excluding `.example` files). It is started in `.xinitrc`:

```bash
mailnotify &
```

### Desktop Notifications

`mailnotify-newmail` in `~/.local/bin/` is called by `onNewMailPost` in each imapnotify config. It parses new mail in `INBOX/new/` across all accounts, decodes MIME headers (From/Subject) via perl, and sends `notify-send` notifications with bold sender and subject. For >5 new mails it sends a single summary instead. It also signals dwmblocks (RTMIN+6) to refresh the mail count immediately.

The full flow: IMAP IDLE event → `mbsync` syncs mail → `mailnotify-newmail` sends notifications + refreshes dwmblocks.

Set it in your imapnotify config:

```yaml
onNewMail: "mbsync your@email.com"
onNewMailPost: "mailnotify-newmail"
```

### dwmblocks Module

`~/.local/src/dwmblocks/scripts/mail.sh` shows an envelope icon with the count of unread mail across all accounts (signal 6, updates every 60s). It counts mail in both `INBOX/new/` and unseen mail in `INBOX/cur/` (no `S` flag). Hidden when count is 0. Left click opens aerc in `$TERMINAL`.

## Multiple Accounts

Add additional account blocks to both `~/.mbsyncrc` and `~/.config/aerc/accounts.conf`. Use unique account names for each.

## Troubleshooting

**Folders not showing**: Check `Patterns` in mbsyncrc matches server folder names. Run `mbsync -l account1` to list remote folders.

**Sent mail not saved**: Verify `copy-to` in accounts.conf matches actual Sent folder name.
