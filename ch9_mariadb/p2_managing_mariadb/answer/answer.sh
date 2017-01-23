#!/bin/bash
# Note: steve@'%' --> % does not include local host
mysql -u root <<EOF
CREATE USER john@localhost identified by 'john_password';
CREATE USER steve@'%' identified by 'steve_password';
GRANT INSERT, UPDATE, DELETE, SELECT on inventory.* to john@localhost;
GRANT SELECT on inventory.* to steve@'%';
FLUSH PRIVILEGES;
exit;
EOF

firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload
