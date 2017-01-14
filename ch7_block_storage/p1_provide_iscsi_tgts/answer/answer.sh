#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF
yum install -y targetcli
systemctl start target
systemctl enable target
firewall-cmd --permanent --add-port=3260/tcp
firewall-cmd --reload
# From left to right: n to create new part, \n=enter, \n again for Partition 1, 
#                     \n for first sector accepting default, \n for last using default,
#                     t for changing parition label to LVM and w to write. 
#                     echo will add final \nbehind that
echo -e "n\n\n\n\n\nt\n8e\nw" | fdisk /dev/sdb
pvcreate /dev/sdb1
vgcreate ISCSI_vg /dev/sdb1
lvcreate -n disk1_iscsi_lv -l "100%FREE" ISCSI_vg
targetcli /backstores/block/ create host1.disk1 /dev/ISCSI_vg/disk1_iscsi_lv
targetcli /iscsi/ create iqn.2017-01.com.example:host1
# Need to create iqn on host2 the same as below OR use this one to create iqn on host2
targetcli /iscsi/iqn.2017-01.com.example:host1/tpg1/acls create iqn.2017-01.com.example:host2
targetcli /iscsi/iqn.2017-01.com.example:host1/tpg1/luns create /backstores/block/host1.disk1
targetcli /iscsi/iqn.2017-01.com.example:host1/tpg1/portals create 192.168.6.6
targetcli saveconfig
