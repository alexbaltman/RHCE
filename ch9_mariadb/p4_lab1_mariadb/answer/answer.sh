#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum groupinstall mariadb -y
systemctl start mariadb
systemctl enable mariadb
firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload

mysql -u root
create database legacy;
exit;
mysql -u root legacy</root/mariadb.dump

# Reason for duplicates: http://stackoverflow.com/questions/16287559/mysql-adding-user-for-remote-access
mysql -u root
CREATE USER mary@'%' identified by 'mary_password';
CREATE USER mary@localhost identified by 'mary_password';
CREATE USER legacy@'%' identified by 'legacy_password';
CREATE USER legacy@localhost identified by 'legacy_password';
CREATE USER report@'%' identified by 'report_password';
CREATE USER report@localhost identified by 'report_password';

GRANT SELECT on legacy.* to mary@'%';
GRANT SELECT on legacy.* to mary@'localhost';
GRANT INSERT, UPDATE, DELETE, SELECT on legacy.* to legacy@'%';
GRANT INSERT, UPDATE, DELETE, SELECT on legacy.* to legacy@localhost;
GRANT SELECT on legacy.* to report@'%';
GRANT SELECT on legacy.* to report@localhost;
FLUSH PRIVILEGES;

use legacy;
INSERT INTO manufacturer(name,seller,phone_number) values ('HP','Joe Doe','+1 (432) 754-3509');
INSERT INTO manufacturer(name,seller,phone_number) values ('DELL','Luke Skywalker','+1 (431) 219-4589');
INSERT INTO manufacturer(name,seller,phone_number) values ('Lenovo','Darth Vader','+1 (327) 647-6784');

exit;
