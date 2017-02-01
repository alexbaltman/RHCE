#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

sed -i 's/#Port 22/Port 22\nPort 999/g' /etc/ssh/sshd_config
yum install -y policycoreutils-python
semanage port -a -t ssh_port_t -p tcp 999

firewall-cmd --permanent --zone=work --add-source=192.168.6.66/32
firewall-cmd --permanent --zone=work --add-port=999/tcp
firewall-cmd --reload
