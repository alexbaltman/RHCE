#!/bin/bash
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth2
# or nmcli con reload
systemctl restart NetworkManager

nmcli con add type bridge con-name br0 ifname br0
nmcli con mod br0 ipv4.addresses 192.168.7.8/24
nmcli con mod br0 ipv4.method manual
nmcli con add type bridge-slave con-name br-slave-1 ifname eth1 master br0
nmcli con add type bridge-slave con-name br-slave-2 ifname eth2 master br0

sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth2
