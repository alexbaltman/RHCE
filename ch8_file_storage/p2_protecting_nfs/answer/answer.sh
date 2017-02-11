#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y policycoreutils-python
wget http://192.168.6.66/krb5.keytab -O /etc/krb5.keytab
chmod 0600 /etc/krb5.keytab

# cat /proc/fs/nfsd/versions --> -4.2 means disabled. Had to reboot to get the +.
sed -i 's/RPCNFSDARGS=\"\"/RPCNFSDARGS=\"-V 4.2\"/' /etc/sysconfig/nfs
# verbose logging for GSS - optional
sed -i 's/RPCGSSDARGS=\"\"/RPCNFSDARGS=\"-vvv\"' /etc/sysconfig/nfs
mkdir /securenfs
chown user01 /securenfs
semanage fcontext -a -t nfs_t "/securenfs(/.*)?"
restorecon -Rv /securenfs
echo '/securenfs host2.example.com(sec=krb5p,rw,no_root_squash)' >>/etc/exports
exportfs -rav

systemctl start nfs
systemctl enable nfs
# Confirm mount with: "showmount -e localhost"
firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
firewall-cmd --reload
# reboot is to get nfsd v4.2 into the kernel: /proc/fs/nfsd/versions
reboot
