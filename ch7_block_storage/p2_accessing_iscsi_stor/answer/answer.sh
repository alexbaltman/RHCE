#!/bin/bash
cat <<EOF >/etc/yum.repos.d/myrepo.repo
[myrepo]
name=myrepo
gpgcheck=0
enabled=1
baseurl=http://mirror.centos.org/centos/7/os/x86_64
EOF
yum install -y iscsi-initiator-utils
echo "InitiatorName=iqn.2017-01.com.example:host1" > /etc/iscsi/initiatorname.iscsi
# Have to restart iscsid to change iqn or login to tgt will fail
systemctl restart iscsid
systemctl enable iscsid
systemctl start iscsi
systemctl enable iscsi
target_iqn=`iscsiadm -m discovery -t st -p 192.168.6.66 | awk '{print $2}'`
iscsiadm -m node -T $target_iqn -p 192.168.6.66 -l
iscsi_disk=`iscsiadm -m session -P3 | grep 'Attached scsi disk sd' | awk '{print $4}'`
mkfs -t xfs /dev/$iscsi_disk
uuid=`blkid /dev/$iscsi_disk | awk '{print $2}'`
mkdir -p /mnt/iscsi_disk
echo "$uuid /mnt/iscsi_disk xfs _netdev 0 2" >> /etc/fstab
mount -a
touch /mnt/iscsi_disk/myfile.txt

# Critical to change from node.startup = onboot to node.startup = automatic
# https://groups.google.com/forum/#!topic/open-iscsi/8U9mAXutlyE
sed -i 's/node.startup = onboot/node.startup = automatic/g' /var/lib/iscsi/nodes/iqn*/*/default
