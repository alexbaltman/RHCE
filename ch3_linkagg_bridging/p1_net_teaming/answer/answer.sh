#!/bin/bash

sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth2
systemctl restart NetworkManager
nmcli dev dis eth1
nmcli dev dis eth2

nmcli con add type team con-name team0 ifname team0 config '{"runner": {"name": "activebackup"}}'
nmcli con mod team0 ipv4.addresses 192.168.7.8/24
nmcli con mod team0 ipv4.method manual
nmcli con add type team-slave con-name team0-port1 ifname eth1 master team0
nmcli con add type team-slave con-name team0-port2 ifname eth2 master team0

nmcli con up team0-port1
nmcli con up team0-port2
