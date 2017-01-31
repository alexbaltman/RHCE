#!/bin/bash
nmcli dev dis team0
nmcli con mod team0 team.conf '{"runner":{"name":"activebackup"}}'
systemctl restart NetworkManager
nmcli con up team-slave-eth1
nmcli con up team-slave-eth2

sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth2

#Needs a reboot here to get the route right or you have to "ip r flush" and then add a static route manually
