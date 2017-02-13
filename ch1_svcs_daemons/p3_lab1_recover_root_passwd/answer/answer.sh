!#/bin/bash
# Reboot, hit e on grub menu
# Append rd.break to linux16 line
# Hit CTRL-X
mount -o remount,rw /sysroot
chroot /sysroot
echo 'agent007' | passwd --stdin root
touch /.autorelabel
exit
exit
systemctl set-default graphical.target
systemctl start rsyslog
systemctl enable rsyslog
