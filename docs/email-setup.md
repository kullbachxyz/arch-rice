# Email Setup

Terminal email using `neomutt` (client), `mbsync` (IMAP sync), `notmuch` (indexing), and `msmtp` (SMTP). Passwords from `pass`. Automatic sync every 15 minutes via cron.

## Prerequisites

- `pass` configured with GPG key for password storage
- IMAP/SMTP credentials from your email provider(s)

## 1. Store Passwords

```bash
pass insert mail/your@email.com
```

One entry per account.

## 2. Configure mbsync

`~/.mbsyncrc` — one block per account:

```
IMAPAccount your@email.com
Host imap.example.com
Port 993
User your@email.com
PassCmd "pass mail/your@email.com"
AuthMechs LOGIN
TLSType IMAPS
TLSVersions +1.3
CertificateFile /etc/ssl/certs/ca-certificates.crt

IMAPStore your@email.com-remote
Account your@email.com

MaildirStore your@email.com-local
Subfolders Verbatim
Path ~/.local/share/mail/your@email.com/
Inbox ~/.local/share/mail/your@email.com/INBOX

Channel your@email.com
Far :your@email.com-remote:
Near :your@email.com-local:
Patterns INBOX Drafts Sent Trash Archive
Sync All
Create Both
Expunge Both
Remove Near
SyncState ~/.local/share/mail/your@email.com/.mbsyncstate
MaxMessages 0
ExpireUnread no
```

Repeat for each additional account. Adjust `Patterns` to match your provider's folder names (`mbsync -l your@email.com` lists remote folders).

Initial sync (downloads all mail, may take a while):

```bash
mbsync -a
```

## 3. Configure notmuch

```bash
notmuch setup
```

`~/.notmuch-config`:

```ini
[database]
path=/home/USER/.local/share/mail/

[user]
name=Your Name
primary_email=primary@example.com
other_email=secondary@example.com

[new]
tags=unread;inbox;

[search]
exclude_tags=deleted;spam;

[maildir]
synchronize_flags=true

[crypto]
gpg_path=gpg
```

Initial index:

```bash
notmuch new
```

## 4. Configure msmtp

`~/.config/msmtp/config` (chmod 600):

```
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.local/share/msmtp/msmtp.log

account your@email.com
host smtp.example.com
port 587
tls_starttls on
from your@email.com
user your@email.com
passwordeval pass mail/your@email.com

account default : your@email.com
```

## 5. mailsync Script

`~/.local/bin/mailsync` — on-demand sync with new-mail notifications.

- Without flag: interactive — shows sync status and per-message notifications
- With `-s`: silent (for cron) — only shows new-mail notifications, errors always shown

New-mail detection: saves a timestamp before sync so that newly downloaded files are guaranteed newer. After sync, `find -newer` locates new inbox mail. For 1–5 messages: sender + subject per mail. For more than 5: summary notification. Prevents parallel runs via `pgrep mbsync`. Lockfile `/tmp/mailsync-running` is read by the dwmblocks mail module.

## 6. Automatic Sync via Cron

```bash
crontab -e
```

```
DISPLAY=:0
*/15 * * * * ~/.local/bin/mailsync -s
```

`DISPLAY=:0` is required since cron jobs don't inherit the desktop session. `DBUS_SESSION_BUS_ADDRESS` is set by the script itself when absent.

Enable cronie if not already running:

```bash
systemctl enable --now cronie
```

## 7. dwmblocks Mail Module

`sb-mailbox` shows unread inbox count. Displays `🔃` while sync is running (lockfile present). Left click opens neomutt, middle click triggers a manual sync.

## Verification

```bash
# Manual sync with output
mailsync

# Silent sync (as cron runs it)
mailsync -s

# Count unread inbox messages
find ~/.local/share/mail -path "*/[Ii][Nn][Bb][Oo][Xx]/new/*" -type f | wc -l

# notmuch search
notmuch search tag:unread
```
