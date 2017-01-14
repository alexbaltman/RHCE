#!/bin/bash
systemctl start nfs-server
systemctl enable nfs-server
mkdir /nfsshare
chown nfsnobody /nfsshare
echo '/nfsshare host2(rw)' >> /etc/exports
exportfs -r
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
