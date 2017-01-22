#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum groupinstall -y mariadb mariadb-client
systemctl start mariadb
systemctl enable mariadb
sed -i '1 a\skip-networking=1' /etc/my.cnf
systemctl restart mariadb
# Set root pass: redhat, then 'Y' to all
# Have not been able to automated this yet
mysql_secure_installation
# Denied: mysql -u root
mysql -u root --password=redhat
