## Selecting a systemd target
A systemd target is a set of systemd units that should be started to reach a desired state.

| Target | Purpose |
| --- | --- |
| graphical.target | System supports multiple users, graphical and txt logins |
| multi-user.target | System supports multiple users, text based logins |
| rescue.target | sulogin prompt, basic sys init completed |
| emergency.target | sulogin prompt, initramfs pivot complete and sys root mounted on / read-only |


Targets can be a part of another target as needed.

- View target dependencies
```
systemctl list-dependencies graphical.target | grep target
```
- Overview of all avail tgt.s 
```
systemctl list-units --type=target --all
```

On a running system an admin can choose to switch targets using systemctl isolate:
```
systemctl isolate multi-user.target
```

Note: not all targets can be isolated - only those that have AllowIsolate=yes set in their unit files. e.g. graphical.target can, but cryptsetup.target cannot.

### Setting a default target
When the system starts and control is passed over to systemd from the initramfs, systemd will try to activate the default.target target. Normally the default.target target will be a sym link to either graphical.target or multi-user.target.

- View default target
```
systemctl get-default
```
- Set default target
```
systemctl set-default graphical.target
```

To select a different target at boot time a special option can be appended to the kernel cmd line from the boot loader: systemd.unit=<target>. 
- To boot into rescue shell you would add:
```
systemd.unit=rescue.target
```

Procedure to select a different target:
1. (Re)boot the system
2. Interrupt the boot loader menu countdown by pressing any key
3. Move the cursor to the entry to be started
4. Type 'e' to edit
5. Move cursor to line starting with linux16 (the kern cmd line)
6. Append systemd.unit=<target>
7. Press Ctrl+x

### Recover Root Pass
1. Reboot sys
2. Interrupt boot
3. Move cursor to desired entry to boot
4. Press 'e'
5. Move cursor to line with linux16
6. Append rd.break, breaking before handing control to initramfs
7. Remove ttyS0 and quiet setting
8. Press ctrl+x
9. At the root shell remount rw: 'mount -o remount,rw /sysroot
10. chroot /sysroot
11. passwd root
12. touch /.autorelabel
13. exit; exit
