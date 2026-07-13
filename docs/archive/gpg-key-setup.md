# Automatic GPG Key Unlock

This setup uses `pam-gnupg` to automatically unlock your GPG key at login when the key passphrase matches your login password. This is useful for `pass` and other GPG-based tools.

## Setup

### 1. Configure PAM

Add to `/etc/pam.d/system-login`:

```
auth     optional  pam_gnupg.so store-only
session  optional  pam_gnupg.so
```

The `auth` line captures your login password, `session` passes it to gpg-agent.

### 2. Configure gpg-agent

Add to `~/.gnupg/gpg-agent.conf`:

```
allow-preset-passphrase
max-cache-ttl 86400
```

### 3. Get your keygrip

```bash
gpg -K --with-keygrip
```

Look for the 40-character hex string under the `[E]` (encryption) subkey. Copy the keygrip for each key you want auto-unlocked.

### 4. Create the config file

```bash
echo "YOUR_KEYGRIP_HERE" > ~/.pam-gnupg
```

One keygrip per line for multiple keys.

### 5. Set matching passphrase

The GPG key passphrase **must match** your login password.

For a new key:
```bash
gpg --full-generate-key
```

Use your login password as the passphrase.

For an existing key:
```bash
gpg --edit-key YOUR_KEY_ID
> passwd
```

Set it to your login password.

## Verify

Log out and back in, then:
```bash
echo "test" | gpg --clearsign
```

This should complete without prompting for a passphrase.

## Notes

- **Will not work with auto-login** -- you must type your password at login.
- If you change your login password, update your GPG key passphrase to match.
- Works alongside `pam_ssh` -- both can be configured in `/etc/pam.d/system-login`.
