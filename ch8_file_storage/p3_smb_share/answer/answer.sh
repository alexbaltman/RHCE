#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y samba policycoreutils-python
mkdir /smbshare
chgrp marketing /smbshare
chmod 2775 /smbshare
semanage fcontext -a -t samba_share_t '/smbshare(/.*)?'
restorecon -vvFR /smbshare
sed -i 's/\tworkgroup = SAMBA/\tworkgroup = mycompany/g' /etc/samba/smb.conf
echo "[smbshare]" >>/etc/samba/smb.conf
echo "path = /smbshare" >>/etc/samba/smb.conf
echo "write list = @marketing" >>/etc/samba/smb.conf

yum install -y samba-client
(echo "redhat"; echo "redhat") | smbpasswd -s -a brian
(echo "redhat"; echo "redhat") | smbpasswd -s -a rob
systemctl start smb
systemctl start nmb
systemctl enable smb
systemctl enable nmb
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
