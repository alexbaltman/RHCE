#!/bin/bash
#if commented out then not clear if needed at this time
#echo '192.168.6.66 host2 host2.example.com' >>/etc/hosts
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

### SETUP KERBEROS CLIENT
yum install -y wget krb5-workstation pam_krb5
wget -O /etc/krb5.conf http://192.168.6.66/krb5.conf
wget http://192.168.6.66/krb5.keytab -O /etc/krb5.keytab
chmod 0600 /etc/krb5.keytab
useradd user01
echo 'user01' | passwd user01 --stdin
sed -i 's/#   GSSAPIAuthentication no/    GSSAPIAuthentication yes/g' /etc/ssh/ssh_config
sed -i 's/#   GSSAPIDelegateCredentials no/    GSSAPIDelegateCredentials yes/g' /etc/ssh/ssh_config
systemctl reload sshd
authconfig --enablekrb5 --update
# Test it:
# su - user01
# kinit
# klist

### SETUP NFS
#yum install -y policycoreutils-python
# cat /proc/fs/nfsd/versions --> -4.2, 4.2 is necessary for feat export selinux labels
sed -i 's/RPCNFSDARGS=\"\"/RPCNFSDARGS=\"-V 4.2\"/' /etc/sysconfig/nfs
# verbose logging
sed -i 's/RPCGSSDARGS=\"\"/RPCNFSDARGS=\"-vvv\"' /etc/sysconfig/nfs
systemctl start nfs-server
systemctl enable nfs-server
firewall-cmd --permanent --add-service={nfs,mountd,rpc-bind}
firewall-cmd --reload
mkdir -m 0755 /securenfs
#semanage fcontext -a -t nfs_t "/securenfs(/.*)?"
#setsebool -P nfsd_anon_write=1
#restorecon -Rv /securenfs
echo '/securenfs 192.168.6.66(sec=krb5p,rw,no_root_squash)' >>/etc/exports
exportfs -rav
# Can confirm w/ "showmount -e localhost" --> shows /securenfs host2
