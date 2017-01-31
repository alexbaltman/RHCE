#!/bin/bash
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart NetworkManager
nmcli con mod "Wired connection 1" ipv6.addresses fddb:fe2a:ab1e::c0a8:3/64
