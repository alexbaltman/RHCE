#!/bin/bash
# Note: nmtui is an option as well
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
nmcli con add con-name eth1 ifname eth1 type ethernet
nmcli con mod eth1 ipv4.addresses 192.168.7.66/24
nmcli con mod eth1 ipv4.method manual
systemctl restart NetworkManager
