## Performing a Multiuser SMB Mount

### Overview
When a Samba share is mounted, the mout creds determine the access perms on the mnt by default. The new *multiuser* mount option separates the mount creds from the creds used to determine file access for ea user. In rhel this can be used w/ sec=ntlmssp auth (contrary to mount.cifs).

The root user mounts the share using the multiuser option and an SMB username that has min access to the contents of the share. REgular users can then stash their own SMB usernames/pass in the current sessions kernel keyring w/ the *cifscreds* cmd. Their accesses to the share are auth w/ their own creds from the keyring, not the mnt creds. The suers can clear or change their creds for that login session at any time, and they are cleared when the session ends. File access perms are enforced entirely by the SMB server based on the access creds currently in use.

For example, to create a new mnt point /mnt/multiuser and mount the share myshare form the SMB file server serverX, auth as SMB user fred, who has the NTLM pass redhat and using the multiuser mnt option:
```
mkdir /mnt/multiuser
mount -o multiuser,sec=ntlmssp,username=fred //serverX/myshre /mnt/multiuser
Password for fred@//serverX/myshre: redhat
```

The cmd *cifscreds* is required to store authcreds in the keyring of the local user. Those auth creds are forwarded to the samba server on a multiuser mnt. The cifs-utils pkg provides the cifscreds cmd:
```
yum install -y cifs-utils
```
The cifscreds cmd has various actions:
- *add* to SMB creds to the session keyring of a user. This option is followed by the host name of the SMB file server
- *update* existing creds in the session keyring of the user. This option is followed by the host name of the SMB file server
- * clear* to remove a particular entry from the session keyring of the user. This option is followed by the hostname of the Samba server 
- *clearall* to clear all existing creds from the session keyring of the user

Note: By default, cifcreds assumes that the username to use w/ the SMB creds matches the current linux username. A different username can be used for SMB creds w/ the -u username option after teh add, update, or clear action.

For example, assume that root has mounted //serverX/myshare on the mount point /mnt/multisuer using the multiuser option. In order to access files on tht share, user frank must use cifscreds to temporarily stash his username/pass in the kernel-managed session keyring.
```
cifscreds add serverX
Password: redhat
echo "Frank was here">/mnt/multiuser/frank2.txt
cat /mnt/multiuser/frank2.txt
Frank was here
exit
```

Assume that perms on the files in the SMB share grant frank rw access to the dir, but jane is only granted read access.
```
cifscreds add serverX
Password: redhat
echo "Jane was not here">mnt/multisuer/jane2.txt
...Permission denied
cat /mnt/multiuser/frank2.txt
Frank was here
```
