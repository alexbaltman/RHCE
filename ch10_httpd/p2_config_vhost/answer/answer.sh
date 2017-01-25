#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y httpd httpd-manual
mkdir -p /srv/{default,wwwX.host1.com}/www
echo 'Coming Soon!' >/srv/default/www/index.html
echo 'wwwX' >/srv/wwwX.host1.com/www/index.html
restorecon -Rv /srv

cat <<EOF >/etc/httpd/conf.d/00-default-vhost.conf
<VirtualHost *:80>
  DocumentRoot /srv/default/www
  CustomLog "logs/default-vhost.log" combined
</Virtualhost>
<Directory /srv/default/www>
  Require all granted
</Directory>
EOF

cat <<EOF >/etc/httpd/conf.d/01-wwwX.host1.com-vhost.conf
<VirtualHost *:80>
  ServerName wwwX.host1.com
  ServerAlias wwwX
  DocumentRoot /srv/wwwX.host1.com/www
  CustomLog "logs/wwwX.host1.com.log" combined
</VirtualHost>
<Directory /srv/wwwX.host1.com/www>
  Require all granted
</Directory>
EOF

systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
