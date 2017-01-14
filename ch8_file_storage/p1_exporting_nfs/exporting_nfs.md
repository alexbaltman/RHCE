## Exporting NFS

### Overview
The Network File System is a network commonly used by Unix systems and network attached stor devs to allow multiple clients to share access to files over the network. It provides access to shared directories or files from client systems.

Note: The NFS protocol transmits data in clear txt over the net. Furthermore, the server relies on the clieent to id users. It is not recommended to export dirs w/ sensitive info w/o the use of Kerbveros auth and encryption which is covered later in this section.

### NFS Exports
A NFS server installation requires the *nfs-utils* package to be installed. It provides all necessary utilities to export a directory with NFS to clients. The config file for the NFS server exports is the /etc/exports file.

The /etc/exports file lists the dir to share to client hosts over the net and indicates which hosts or nets have access to the export. 

Note: Instead of adding the info required for exporting dirs to the exports file, a newly created file name *.exports can b e added to the /etc/exports.d dir holding the config of exports.
Note2: Exporting the same dir w/ NFS and Samba is not supported on RHEL b/c NFS and Samba use diff file locking mechanisms which can cause file corruption.

One or more clients can be listed separated by a space.
- DNS resolvable hostname, like host1.example.com in the following example, where the /myshare directory is exported and can be mounted to host1.example.com
```
/myshare host1.example.com
```
- DNS resolvable host name with wildcards for multiple characters and/or ? for a single character: Allow all subdomains in the example.com domain to access the NFS export:
```
/myshare *.example.com
```
- DNS resolvable hostname w/ char class lists in square brackets: Allow hosts host1.example.com and host2.example.com ... host20... to access the NFS export
```
/myshare server[0-20].example.com
```
- IPv4 addr. The following ex allows access to the /myshare NFS share from 172.25.11.10
```
/myshare 172.25.22.10
```
- IPv4 net. Allow access to NFS exported dir /myshare from the 172.25.0.0/16 network
```
/myshare 172.25.0.0/16
```
- IPv6 addr w/o square brackets. Allow client w/ ipv6 addr 2000:472:18:b51:c32:a21 access to NFS export
```
/myshare 2000:472:18:b51:c32:a21
```
- IPv6 network w/o square brackets. This ex allows the IPv6 network 2000:472:18:b51::/64 access to the NFS export
```
/myshare 2000:472:18:b51::/64
```
- A dir can be exported to multiple hosts simultaneously by specifying multiple tgts w/ their options, separated by spaces, following the dir to export
```
/myshare *.example.com 172.25.0.0/16
```

Optionally there can be one or more export options specified in round brackets as a comma separated list dirctly followed by each client definition. Commonly used export optons are as follows.

- ro, read-only, the default setting when nothing is specified. It is allowed to explicityly specify it w/ an entry. Restricts the NFS cliens to read files on the NFS share. Any write operation is prohibited. The following ex explicitly states the ro flag for the host1.example.com host.
```
/myshare host2.example.com(ro)
```
- rw, read-write, allows read and write access for the NFS clients in the following example the host1.example.com is able to access the NFS export read only while server 00-20 has read write access.
```
/myshare host1.example.com(ro) server[0-20].example.com(rw)
```
- no_root_squash, by default, root on an NFS client is treated as user nfsnobody by the NFS server. That is, if root attempts to access a file on a mounted export, the server will treat it as an access by user nfsnobody instead. This is a security measure that can be problematic in scenarios where the NFS export is used as / by a diskless client and root needs to be treated as root. To disable  this protection the server needs to add *no_root_squash* to the list of optins set for the export in /etc/exports
```
/myshare diskless.example.com(rw,no_root_squash)
```
Note: This particular config is not secure and wold be better done in cnjunction w/ kerberos auth and integrity checking.

To reload and reexport changes to the running nfs server exports, you must:
```
exportfs -r
or
systemctl restart nfs-server
```

### Configuring an NFS export
1. Start and enable server
```
systemctl start nfs-server
systemctl enable nfs-server
```
2. Create a dir to share
```
mkdir /myshare
```
3. Export dir from server to client/s as rw enabled share.
```
/myshare desktopX(rw)
```
4. Apply changes
```
exportfs -r
```
5. Port 2049/tcp for nfsd must be opened
```
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
```
6. On client
```
mkdir /mnt/nfsexport
mount serverX:/myshare /mnt/nfsexport
```
7. To make persistent on client add to fstab
```
serverX.example.com:/nfsshare /mnt/nfsexport nfs default 0 0
```
Note: default in fstab includes: ro, using a local control mechanism
To get showmount -e to work to show the exports of an NFS server you need to enable rpc-bind and mountd.
