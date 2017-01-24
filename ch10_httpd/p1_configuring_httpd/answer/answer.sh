#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y httpd httpd-manual
sed -i 's/ServerAdmin root@localhost/ServerAdmin webmaster@host1.example.com/g' /etc/httpd/conf/httpd.conf
echo 'Hello Dawg!' >/var/www/html/index.html
systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
