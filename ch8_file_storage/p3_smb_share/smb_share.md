## Providing SMB File Shares

### Overview
Server Message Block (SMB) is the standard file-sharing protocol for Windows Servers and clients. SMB file srvers can be configured in a number of different ways. One of the simplest is to configure the file servers and their clients as members of a common Windows workgroup which announces servers and clients to the local subnet. The file servers each manage their own local user accounts and passwords independently. More sophisticated configurations may be local user accounts and passwords independently. More sophisticated configurations may be members of a Windows domain and coordinate user authentication through a domain controller.

Using a software pkg named Samba. RHEL is able to act as a server for SMB file shares. Mounting SMB file shares as a client is handled by a kernel driver and utilities included in the *cifs-utils* pkg.


### SMB File Sharing w/ Samba
The samba svc can share nix file systems as SMB network file shares. This section will cover the basic configuration steps needed for a Samba server to provide a file share to the members of a Windows workgroup, managing its own users locally. It will not discuss the more complex configuration required to make a samba server a member of a windows domain. The basic steps that must be performed in order to configure Samba to provide an SMB file share as a workgroup member are:
1. Install the *samba* package
2. Prepare the permissions on the directory to be shared
3. Configure /etc/samba/smb.conf
4. Set up appropriate Linux users
5. Start Samba and open the local FW
6. Verify that the share can be mounted from a client.

### Installing Samba
To deploy the samba service on a RHEL sys, the *samba* pkg must be installed. This can be done directly or as part of the file-srver pkg grp:
```
yum install -y samba [samba-client]
```

Note: Do NOT use Samba to share a directory that is also an NFS export or a mounted NFS system. This can result in file corruption, state file locks or other file access issues with the share.

The directory to be shared must be created if it does not already exist
```
mkdir /sharedpath
```

#### Users and regular Permissions
The permissions which should be set on the dir will depend on who needs access to it and how it will be mounted by clients.

A client normally mounts a share by authenticating access to the SMB server as a particular user. All files on the share need to be readable (and possibly writable) by the user that is used to mount the share.

#### SELinux Contexts and Booleans
In order for Samba to work correctly when SELinux is in enforcing mode, the dir will need to have the correct SELinux contexts and certain SELinux Booleans may need to be set.

If the shared dir will only be accessed through Samba, then the dir and all its subdirs and files should be labeled *samba_share_t*, which gives Samba read/write access. It is best to configure the SELinux policy so that restorecon will set this type on the share and its contents if the fs is relabeled. 
```
semanage fcontext -a -t samba_share_t '/sharedpath(/.*)?'
restorecon -vvFR /sharedpath
```

Note: Samba can also serve files labeled with SELinux types public_content_t (read-only) and public_content_rw_t (read-write). To allow rw access to files and dirs labeled public_content_rw_t, the SELinux Boolean smbd_anon_write must also be enabled.

### Configuring /etc/samba/smb.conf
The main config file for Samba is /etc/samba/smb.conf. This file is divided into multiple sections. Ea section starts w/ a section name in square brackets, followed by a list of parameters set to particular values. /etc/samba/smb.conf starts with a [global] section used for general server config. Subsequent sections ea define a file share or printer share provided by the samba server. Two special sections may exist, [home[ and [printers], which have special uses. Any line beginning w/ either a semicolon or hash char is commented out.

#### The [global] section
The [global] section defines the basic config of the samba server. There are three things which should be configured here:
1. workgroup is used to specify the Win workgrp for the server. Most Win systems default to WORKGROUP, although win XP defaulted to MSHOME. This is used to help systems browse for the server using the NetBIOS for TCP/IP name svc. 

To set the workgroup to WORKGROUP, change the existing workgroup entry in the /etc/samba/smb.conf to
```
workgroup = WORKGROUP
```
2. Security controls how clients are auth by samba. For security = user, clients log in w/ a valid user/pass managed by the local samba server. This setting is the default in /etc/samba/smb.conf.

3. hosts allow is a comma, space, or tab delimited list of hosts that are permitted to access teh samba svc. If it is not specified all hosts can access Samba. If it is not specified in the [global] section, it can be set on ea share separately. If it is specified in the [global] section, then it will apply to all shares, regardless of whether ea share has a diff setting. 

Hosts can be specified by hostname or src ip addr. Host names are checked by reverse resolving the ip addr of the incoming con attempt. The full syntax of this directive is described by the hosts_access man page. 

Allowed hosts can be specified in a # of ways:
- ipv4 net/prefix: 192.168.0.0/24
- ipv4 net/netmask: 192.168.0.0/255.255.255.0
- if the ipv4 subnet prefix is on a byte boundary: 192.168.0.
- ipv6 net/prefix: [2001:db8:0:1::/64]
- host name: desktop.example.com
- All hosts ending in: .example.com

For example to restric access to only the hosts from 172.25.0.0/16 net using the trailing dot notation, the hosts allow entry in the /etc/samba/smb.conf config file would read:
```
hosts allow = 172.25.
```
To additionally allow access from al lhost names ending with ".example.com", the /etc/samba/smb.conf config file entry would be:
```
hosts allow = 172.25. .example.com
```

#### File share sections
To create a file share at the end of /etc/samba/smb.conf, place the share name in brackets to start a new section for the share. Some key driectives should be set in this section:
1. path must be set to indicate which dir to share; for ex, path = /sharedpath
2. writable = yes should be set if all auth users should have rw access to the share. the default setting is writable = no

If writable = no is set, a comma separated write list of users w/ rw access to the share can be provided. Users not on the list will have read-only access. Members of the local grps can also be specified: write list = @management will permit all auth users who are member of the nix grp "management" to have write access
3. valid users, if set specified a list of users allowed to access the share. Users not on the list are not allowed to access the share. However, if the list is blank, all users can access the share.

For example, to allow only user fred and members of grp management read-only access to the share myshare, the section would read:
```
[myshare]
  path = /sharedpath
  writable = no
  valid users = fred, @management
```

#### The [homes] section
The [homes] section defines a special file share, which is enabled by default. This share makes a local home dirs available via SMB. The share name can be specified as homes, in which case the samba server will convert it to the home dir path of the auth user, or as a specific username. 

Note: The *samba_enable_home_dirs* SELinux Boolean allows local linux home dirs to be shared by samba to other systems. This needs to be enabled for [homes] to work (setsebool -P samaba_enable_home_dirs=on). The use_samba_home_dirs Boolean, on the other hand, allows remote SMB file shares to be mounted and used as local Linux home dirs. It is easy to confuse the two options.

#### Validating /etc/samba/smb.conf
To verify that there are no errors in the edited smb.conf file, the command testparm is available. Run testparm w/ no args to verify if there are no obvious syntax errors:
```
testparm
```
Note: The directive *read only = no* is the same as *writable = yes*, which can be confusing.

### Preparing Samba users
The security = user settting requires a linux account w/ a samba account that has a valid NTLM pass. To create a samba-only system user, keep the linux pass locked and set the login shell to /sbin/nologin. This prevents the login of the user directly or w/ ssh on the system.

For example, to create the locked linux account for a user fred:
```
useradd -s /sbin/nologin fred
```
The samba-client contains the smbpasswd command. It can create samba accounts and set passwords. 
```
yum install -y samba-client
```
If smbpasswd is passed a username w/o any options, it will attempt to change the acc password. The root user can use it w/ the -a option to add the Samba account and set the NTLM password. The -x option can be used by root to delte a samba acc and pass for a user. 

For example, to create a samba acc for user fred an assign an NTLM pass:
```
smbpasswd -a fred
New SMB password: redhat
Retype...: redhat
...
Added user fred
```
A more powerful tool than smbpasswd is also avail for the root user, *pbedit*. For ex, pbedit -L will list all users w/ samba acc.s configured on the sys. See pbedit man page. 

### Stating Samba
Use systemctl to start the samba svc:
```
systemctl start smb nmb
systemctl enable smb nmb
```
The two svc.s these units start, smbd and nmbd must communicate through the local fw. Sambas smbd daemon normally uses TCP/445 for SMB cons. It also listens on TCP/139 for NetBIOS over TCP backward compatibility. The nmbd daemon uses UDP/137 and UDP/138 to provide NetBIOS over TCP/IP net browsing support.

To config fw:
```
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
```
Note: Samba checks periodically to determine if /etc/samba/smb.conf has been changed. If the config file has changed, samba auto reloads it. This will not affect any cons arleady established to the samba svc, until the con is closed or samba is completely restarted. The cmd systemctl reload smb nmb can be used to reload config file immediately or systemctl restart smb nmb to restart samba entirely.

### Mounting SMB Filesystems
#### Regular SMB mounts
The cifs-utils pkg can be used to mount SMB file shres on the local sys, whether from a samba server or a native win server. By default, SMB mounts use a single set of user creds (the mount creds) for mounting the share and determining access rights to files on the shre. All users on the linux sys using the mnt use the same creds to determine file access.

The mount cmd is used to mnt the share. By default the protocol used to auth users is NTLMv2 pass hashing encapsulated in Raw NTLMSSP msgs (sec=ntlmssp) as expected by recent versions of windows. The mount creds can be provided in two ways. If mounting interactively at the shell prompt, the username= option can be used to specify which SMB user to auth as; the user will be prompted for the pass. If mounting automatically a creds file readable only by root containing the user and pass can be provided w/ the credentials= option. 

For example, to mount the shre myshre from the SMB file server serverX, auth as SMB user fred, who has the NTLM pass redhat:
```
mkdir /mnt/myshare
mount -o username=fred //serverX/myshare /mnt/myshare
Password for fred@/serverX/myshare: redhat
```

### References
- samba
- smb.conf
- testparm
- mount
- mount.cifs
- smbpasswd
- pbedit
- samba_selinux
