#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y httpd mod_ssl mod_wsgi
mkdir -p /srv/webappX/www
cp /root/webapp.wsgi /srv/webappX/www
restorecon -Rv /srv/webappX

# Auto gen self-signed cert
openssl req -newkey rsa:2048 -nodes -keyout webappX_pvt.key -x509 -days 365 -out webappX_pub.crt \
    -subj "/C=US/ST=North Carolina/L=RTP/O=Example Co/CN=webappX.host1.com"

cp *pub.crt /etc/pki/tls/certs/
rm -f *pub.crt
chmod 0600 /etc/pki/tls/certs/*
cp *pvt.key /etc/pki/tls/private/
rm -f *pvt.key
chmod 0600 /etc/pki/tls/private

cat <<EOF >/etc/httpd/conf.d/webappX.conf
<VirtualHost *:443>
  ServerName webappX.host1.com
  DocumentRoot /srv/webappX/www
  SSLEngine On
  SSLCertificateFile /etc/pki/tls/certs/webappX_pub.crt
  SSLCertificateKeyFile /etc/pki/tls/private/webappX_pvt.key
  WSGIScriptAlias / /srv/webappX/www/webapp.wsgi
</VirtualHost>
<Directory /srv/webappX/www>
  require all granted
</Directory>
EOF

systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
