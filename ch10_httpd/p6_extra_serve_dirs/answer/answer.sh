#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y httpd
mkdir -p /var/www/html/usersecrets
mkdir -p /var/www/html/grpsecrets
mkdir -p /var/www/html/localsecrets
restorcecon -Rv /var/www/html

htpasswd -nmb mkting_user redhat >>/etc/httpd/conf/.htpasswd
htpasswd -nmb mkting_user2 redhat >>/etc/httpd/conf/.htpasswd
chmod 0600 /etc/httpd/conf/.htpasswd
chown apache:apache /etc/httpd/conf/.htpasswd

cat <<EOF >/etc/httpd/conf.d/usersecrets.conf
<Directory /var/www/htmlusersecrets>
  AuthType Basic
  AuthName 'Area 51'
  AuthUserFile /etc/httpd/conf/.htpasswd
  Require user mkting_user
</Directory>
EOF

cat <<EOF >/etc/httpd/conf/.htgroups
marketing: mkting_user mkting_user2
EOF
chmod 0600 /etc/httpd/conf/.htgroups
chown apache:apache /etc/httpd/conf/.htgroups

cat <<EOF >/etc/httpd/conf.d/grpsecrets.conf
<Directory /var/www/html/grpsecrets>
  AuthType Basic
  AuthName 'Area 51'
  AuthUserFile /etc/httpd/conf/.htpasswd
  AuthGroupFile /etc/httpd/conf/.htgroups
  Require group marketing
</Directory>
EOF

cat <<EOF >/etc/httpd/conf.d/localsecrets.conf
<Directory /var/www/html/localsecrets>
  Require local
</Directory>
EOF

# apachectl configtest
# yum install -y elinks
# elinks http://localhost/localsecrets
# elinks http://localhost/grpsecrets
# elinks http://localhost/usersecrets

systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
