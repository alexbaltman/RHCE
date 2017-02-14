#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y httpd mod_ssl
mkdir -p /srv/{www,webapp}X/www
echo 'Hello Wooorld!'>/srv/wwwX/www/index.html
echo 'My Application, yo'>/srv/webappX/www/index.html
restorecon -Rv /srv

# Auto gen self-signed cert
openssl req -newkey rsa:2048 -nodes -keyout wwwX_pvt.key -x509 -days 365 -out wwwX_pub.crt \
    -subj "/C=US/ST=North Carolina/L=RTP/O=Example Co/CN=wwwX.host1.com"
openssl req -newkey rsa:2048 -nodes -keyout webappX_pvt.key -x509 -days 365 -out webappX_pub.crt -subj "/C=US/ST=North Carolina/L=RTP/O=Example Co/CN=webappX.host1.com"

cp *pub.crt /etc/pki/tls/certs/
rm -f *pub.crt
chmod 0600 /etc/pki/tls/certs/*
cp *pvt.key /etc/pki/tls/private/
rm -f *pvt.key
chmod 0600 /etc/pki/tls/private

cat <<EOF >/etc/httpd/conf.d/wwwX.conf
<VirtualHost *:443>
  ServerName wwwX.host1.com
  SSLEngine On
  SSLCertificateFile /etc/pki/tls/certs/wwwX_pub.crt
  SSLCertificateKeyFile /etc/pki/tls/private/wwwX_pvt.key
  DocumentRoot /srv/wwwX/www
</VirtualHost>
<Directory /srv/wwwX/www>
  require all granted
</Directory>
<VirtualHost *:80>
  ServerName wwwX.host1.com
  RewriteEngine on
  RewriteRule ^(/.*)$ https://%{HTTP_HOST}$1 [redirect=301]
</VirtualHost>
EOF

cat <<EOF >/etc/httpd/conf.d/webappX.conf
<VirtualHost *:443>
  ServerName webappX.host1.com
  SSLEngine On
  SSLCertificateFile /etc/pki/tls/certs/webappX_pub.crt
  SSLCertificateKeyFile /etc/pki/tls/private/webappX_pvt.key
  DocumentRoot /srv/webappX/www
</VirtualHost>
<Directory /srv/webappX/www>
  require all granted
</Directory>
<VirtualHost *:80>
  ServerName webappX.host1.com
  RewriteEngine on
  RewriteRule ^(/.*)$ https://%{HTTP_HOST}$1 [redirect=301]
</VirtualHost>
EOF

# Be sure to check your configs with 'apachectl configtest', helps a bunch!

systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=http --add-service=https
firewall-cmd --reload
