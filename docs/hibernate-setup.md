# Hibernate Setup (Swap File on LUKS)

Hibernate requires a disk-backed swap to write RAM contents to. zram (compressed RAM swap) does not work for this since it loses data on power off.

## Prerequisites

- LUKS-encrypted root partition (`/dev/mapper/root`)
- ext4 filesystem
- Enough free disk space for a swap file equal to RAM size

## 1. Create Swap File

```sh
sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 2. Add to fstab

Append to `/etc/fstab`:

```
/swapfile none swap defaults 0 0
```

## 3. Get Resume Offset

```sh
sudo filefrag -v /swapfile | head -4
```

Note the first `physical_offset` value (e.g. `2439168`).

## 4. Add Kernel Parameters

Edit `/etc/default/grub` and add to `GRUB_CMDLINE_LINUX`:

```
resume=/dev/mapper/root resume_offset=<physical_offset>
```

Then regenerate GRUB config:

```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 5. Add resume Hook to initramfs

Edit `/etc/mkinitcpio.conf` and add `resume` after `encrypt`:

```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt resume filesystems fsck)
```

Rebuild initramfs:

```sh
sudo mkinitcpio -P
```

## 6. Reboot

Reboot for changes to take effect. Test with `systemctl hibernate`.
