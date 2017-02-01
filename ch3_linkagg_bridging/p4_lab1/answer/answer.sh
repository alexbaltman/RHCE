#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF

yum install -y bridge-utils

sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/NM_CONTROLLED=no/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-eth2
sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth1
sed -i 's/ONBOOT=yes/ONBOOT=no/g' /etc/sysconfig/network-scripts/ifcfg-eth2

nmcli con add type team con-name team0 ifname team0 config '{"runner":{"name":"activebackup"}}'
nmcli con add type team-slave con-name team0-port1 ifname eth1 master team0
nmcli con add type team-slave con-name team0-port2 ifname eth2 master team0
nmcli dev dis team0
systemctl stop NetworkManager
systemctl disable NetworkManager

echo 'BRIDGE=br0' >> /etc/sysconfig/network-scripts/ifcfg-team0
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-br0
DEVICE=br0
ONBOOT=yes
TYPE=Bridge
IPADDR0=192.168.7.8
PREFIX0=24
EOF

reboot
