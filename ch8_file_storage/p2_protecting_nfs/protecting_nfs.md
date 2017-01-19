## Protecting NFS

### Kerberos-enabled NFS exports
The nfs server does not require auth and only enforces access restriction based on the ip addr or host name of the client by default. To remedy this, the nfs server provides options to secure access to file using a number of methods: none, sys, krb5, krb5i, and krb5p. The nfs server can choose to offer a single method or multiple methods for each exported share. NFS clients must connect to the xported share using one of the methods mandatated for that share, specified as mount option *sec=method*.

#### Security methods
- none: Anon access to the files, writes to the server will be allocated UID and GID of nfsnobody, this is the default. The nfs server trusts any uid sent by the client.
- sys: File access based on the standard nix file perms for uid and gid values. If not specified this is the default. The nfs server trusts any uid sent by the client. 
- krb5: Clients must prove identity using kerberos and then standard nix file perms apply uid/gid is determined based upon the kerberos principal from the accessing user.
- krb5i: Adds enc to all requests b/w the client and server, preventing data exposure on the net. This will have a perf impact, but provides the most sec. UID/GID is determined based upon the kerberos principal from the accessing user. 

For using any of the sec options that use a kerberos server, the *nfs-secure-server* needs to be running in addition to the *nfs-server*. 

Note: Kerberos options will req at a min a /etc/krb5.keytab and additional auth config that is not covered in this sec, joining the kerberos realm. The /etc/krb5.keytab will normally be provided by the auth or sec admin. Request a keytab that includes either a host principal, nfs principal, or both. 

### Config a kerberos enabled nfs server
This is how to export a dir w/ nfs using krb5p sec. This requires a keytab file. This is how the redhat lab does it:

1. Install keytab provided at http://classroom.example.com/pub/keytabs/serverX.keytab
```
wget -O /etc/krb5.keytab http://classroom.example.com/pub/keytabs/serverX.keytab
```
2. For nfs w/ kerberos sec, the nfs-secure-server needs to be running. Start the nfs-secure-server svc on the serverX system.
```
systemctl start nfs-secure-servery
systemctl enable nfs-secure-servery
```
3. Create the dir /securedexport on serverX. This dir will be used as the nfs exprt
```
mkdir /securedexport
```
4. Add the directory /securedexport to the /etc/exports file to export it w/ nfs. Enable krb5p sec to secure access to the nfs share. Allow read and write access to the exported dir from all subdomains of the example.com domain.
```
echo '/securedexport *.example.com(sec=krb5p,rw)' >>/etc/exports
```
5. After the changed /etc/exports file has been saved, apply the changes by executing exportfs -r
```
exportfs -r
```
6. The nfs port 2049/tcp for nfsd must be open on the server. To configure firewalld to enable access to the nfs exports immediately run:
```
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
```
7. Install the provided keytab on the desktopX system, which will act as the nfs client. mount the krb5p-secured share on the desktopX system
```
wget -O /etc/krb5.keytab http://classroom.example.com/pub/keytabs/desktopX.keytab
```
8. NFS uses the nfs-secure service on the client side to help negotiate and manage communication w/ the server when connecting to kerberos secured shares. It must be running to sue the secured nfs shares; start and enable it to ensure it is always avail on the desktopX sy system.
```
systemctl start nfs-secure
systemctl enable nfs-secure
```
Note: *nfs-secure* svc is part of the nfs-utils pkg, which should be installed by default. 
9. The mount point must exist to mount krb5p-secured export from serverX on the desktopX system. /mnt/securedexport is created on desktopX system.
```
mkdir /mnt/securedexport
```
10. The exported dir now can be mounted on dekstopX system w/ krb5p sec enabled.
```
mount -o sec=krb5p serverX:/securedexport /mnt/securedexport 
```

### SELinux and labeled NFS
SELinux offers additional sec by locking down the capabilities of services provided in RHEL. By default, nfs mounts have the selinux context nfs_t, independent of the SELinux context they have on the server that provides the export. 

This behavior can be changed on the client side by using mount option
*context="selinux_context"*. The following ex mounts the nfs export and enforces the selinux context: system_u:object_r:public_content_rw_t:s0:
```
mount -o context="system_u:object_r:public_content_rw_t:s0" server:X/myshare /mnt/nfsexport
```

The nfs server can be forced to properly export the SELinux context of a share by switching to nfs version 4.2. This specification curently only exists as an internal draft. It is already implemented in the nfs server shipped by rhel7, but needs to be turned on explicitly.

To enable NFS version 4.2 on the serverX system to export the SELinux labels, change the RPCNFSDARGS="" line in the /etc/sysconfig/nfs file to:
```
RPCNFSDARGS="-V 4.2"
```
The nfs-server or nfs-secure-server respectively require a restart
```
systemctl restart nfs-server
systemctl restart nfs-secure-server
```
On the client side, mount -o v4.2 must be specified as the mount option.
```
mount -o sec=krb5p,v4.2 serverX:/securedexport /mnt/securedexport
```
For testing purposes, a new file w/ the name selinux.txt is created in the exported dir /securedexport. After creation, the SELinux type is changed to public_content_t.
```
touch /securedexport/selinux.txt
chcon -t public_content_t /securedexport/selinux.txt
```
All SELinux labels are now properly handled by serverX and forwarded to the client system desktopX.
```
ls -Z /mnt/securedexport/
```

Note: In a default installation of rhel, the nfs_export_all_ro and nfs_export_all_rw SELinux Booleans are both enabled. This allows the NFS daemon to r/w almost any file. To lock down the capabilities of the NFS server, disable these booleans. For content to be readable by NFS, it should have the public_content_t or nfs_t context. If the public_content_rw_t context is used, the nfsd_anon_write boolean must be enabled to allow writes. Additional NFS related SELinux information can be found in the nfsd_selinux man page, which is in selinux-policy-devel rpm pkg. 

### References
+ nfs
+ mount
+ mount.nfs
+ exportfs
+ exports
+ nfsd_selinux
