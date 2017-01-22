#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y cifs-utils
mkdir /mnt/multiuser
echo 'username=rob' >/.smbcreds_multiuser
echo 'password=redhat' >>/.smbcreds_multiuser
echo '//192.168.6.66/smbshare /mnt/multiuser cifs credentials=/.smbcreds_multiuser,multiuser,sec=ntlmssp 0 0' >>/etc/fstab
mount /mnt/multiuser
# Expect failure:
touch /mnt/multiuser/rob.txt
umount /mnt/multiuser
sed -i 's/username=rob/username=brian/g' /.smbcreds_multiuser
mount /mnt/multiuser
echo "BlahBlah" >>/mnt/multiuser/brian.txt
umount /mnt/multiuser
sed -i 's/username=brian/username=rob/g' /.smbcreds_multiuser
mount /mnt/multiuser
cat /mnt/multiuser/brian.txt

# cifscreds add -u myuser 192.168.6.66
