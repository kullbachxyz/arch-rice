# Automatic SSH Key Unlock

This setup uses `pam_ssh` to automatically unlock your SSH key at login when the key passphrase matches your login password.

## New Key

1. Generate an SSH key (use the **same passphrase as your login password**):
   ```bash
   ssh-keygen -t ed25519
   ```

2. Symlink to `login-keys.d`:
   ```bash
   mkdir -p ~/.ssh/login-keys.d
   ln -sf ~/.ssh/id_ed25519 ~/.ssh/login-keys.d/
   ```

3. Log out and back in, then verify:
   ```bash
   ssh-add -l
   ```

## Existing Key

1. Copy your key to `~/.ssh/`:
   ```bash
   cp /path/to/id_ed25519 ~/.ssh/
   cp /path/to/id_ed25519.pub ~/.ssh/
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

2. Change the passphrase to match your login password:
   ```bash
   ssh-keygen -p -f ~/.ssh/id_ed25519
   ```

3. Symlink to `login-keys.d`:
   ```bash
   mkdir -p ~/.ssh/login-keys.d
   ln -sf ~/.ssh/id_ed25519 ~/.ssh/login-keys.d/
   ```

4. Log out and back in, then verify:
   ```bash
   ssh-add -l
   ```

## Notes

- The key passphrase **must match** your login password for automatic unlock.
- If you change your login password, update your SSH key passphrase:
  ```bash
  ssh-keygen -p -f ~/.ssh/id_ed25519
  ```
- Multiple keys can be added by symlinking them all to `~/.ssh/login-keys.d/`.
