#!/bin/bash
# Note: steve@'%' --> % does not include local host
mysql -u root
CREATE database inventory;
exit;
mysql -u root inventory </root/inventory.dump
