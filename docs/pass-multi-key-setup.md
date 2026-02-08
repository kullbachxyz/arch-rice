# Pass Multi-Key Setup

Access the same `pass` password store from multiple machines, each with its own GPG key.

## Setup

### 1. On the new machine: generate a GPG key

```bash
gpg --full-generate-key
```

Note the key ID.

### 2. On the new machine: export the public key

```bash
gpg --export --armor NEW_KEY_ID > newmachine.pub
```

Copy it to the existing machine (scp, USB, etc.).

### 3. On the existing machine: import and trust the new key

```bash
gpg --import newmachine.pub
gpg --edit-key NEW_KEY_ID
> trust
> 5
> quit
```

### 4. On the existing machine: re-init pass with both keys

```bash
pass init EXISTING_KEY_ID NEW_KEY_ID
```

This re-encrypts every entry to both keys.

### 5. Sync the store to the new machine

With git:
```bash
# Existing machine
pass git push

# New machine
git clone your-repo-url ~/.password-store
```

Or sync `~/.password-store/` via syncthing.

### 6. On the new machine: import the existing machine's public key

Needed so `pass insert`/`pass edit` can encrypt to both recipients:

```bash
# Existing machine
gpg --export --armor EXISTING_KEY_ID > existing.pub

# New machine
gpg --import existing.pub
gpg --edit-key EXISTING_KEY_ID
> trust
> 5
> quit
```

### 7. Verify

```bash
pass show some/entry
```

## Listing Keys

```bash
gpg -k                  # list public keys
gpg -K                  # list private keys
gpg -K --with-keygrip   # with keygrips (needed for pam-gnupg)
gpg --show-keys file.pub  # inspect a key file (without a file it reads stdin and appears to hang)
```

## Editing a GPG Key

```bash
gpg --edit-key YOUR_KEY_ID
```

- `uid N` — select a UID by number
- `adduid` — add a new name/email
- `deluid` — remove the selected UID
- `primary` — set selected UID as primary
- `passwd` — change passphrase
- `expire` — change expiry date
- `save` — save and quit

After editing, re-export and import on other machines:

```bash
gpg --export --armor YOUR_KEY_ID > updated.pub
# On other machines
gpg --import updated.pub
```

GPG merges updates automatically by key ID.

## Notes

- `.password-store/.gpg-id` lists all key IDs -- `pass` encrypts to all of them automatically.
- Adding another machine later: repeat the process and run `pass init` with all key IDs.
- If using `pam-gnupg`, each machine's GPG key passphrase must match that machine's login password.
