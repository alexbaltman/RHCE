## Provide iSCSI Targets

### Overview
In original scsi terminology a tgt is a single connectible sto or output dev uniquely identified on a scsi bus. In iscsi, in which the scsi bus is emulated across an ip net, a tgt can be a dedicated physical dev in a network attached storage enclosures or an iscsi soft configured local dev on a networked storage server. A tgt, like HBAs and initiators, is an end point in SCSI bus com, passing cmd descriptor blocks (CDB) to request or provide str txns. 

To provide access to the sto or output dev, a tgt is configured w/ one or more logical unit numbers (LUNs). In iscsi, LUNs appear as the tgts sequentially numbered disk drivers, although targets typically have only one LUN. An initiator performs SCSI negotiation w/ a tgt to establish con to the LUN. The LUN responds as an emulated SCSI disk blk dev, which can be used in raw form or formatted w/ a client supported fs.

Warning: Do not mnt single sys file systems to more than one system at a time. Iscsi allows shared tgtg and LUN access from multiple initiator nodes, requiring the use of cluster capable file systems such as GFS2. Mounting standard file systems designed for local, single sys access (e.g. btrfs, ext3, ext4, FAT32, HPFS+, NTFS, XFS, ZFS) from more than one sys concurrently will cause FS corruption.

iscsi provides for LUN masking by using ACLs to restrict LUN accessibility to specific initiators. Except when shared access is intended, ACLs can ensure that only a designated client node can login to a specific tgt. On the tgt server, ACLs can be set at the TPG level to secure groups of LUNs, or set individualy per LUN. 

### iSCSI Target Configuration
Target server config demonstration:
*targetcli* is both a cli utility and an interactive shell in which to create, delete, and config iSCSI target components. Target stack objects are grouped into a hierachical tree of objects, allowing easy navigation and contextual configuration. Familiar Linux commands are used in theis shell: cd, ls, pwd, and set. The targetcli shell also supports TAB completion.

1. Install targetcli if needed
```
yum -y install targetcli
```
2. Run targetcli w/ no options to enter interactive mode
```
targetcli
/>
/> ls
```
3. Create backing storage (backstores). 
```
/> cd /backstores
/backstores> block/ create block1 /dev/iSCSI_vg/disk1_lv
Created block storage object block1 using /dev/iSCSI_vg/disk1_lv
/backstores> block/ create block2 /dev/vdb2
Created block storage object block2 using /dev/vdb2
/backstores> fileio/ create fil1 /root/disk1_file 100M
Created fileio file1 with size 104857600
```
There are several types of backing storeage:
- block - A block device defined on the Server. A disk drive, disk partition, a logical volume, multipath device, any device files defined on the sever that are of type b.
- fileio - create a file, of a specified size, in the filesystem of the server. This method is similar to using image files to be the storage for virtual machine disk images
- pscsi - physical scsi, permits passthrough to a physical SCSI device connected to the server. This backstore is not typically used.
- ramdisk - Create a ramdisk device, of a specified size, in memory on the sever. This type of storage will not store data persistently. When the server is rebooted, the ramdisk definition will return when the target is instantiated, but all data will have been lost.
4. Create an IQN for the target. This step will also create a default TPG underneath the TQN
```
/backstores> cd /iscsi/
/iscsi> create iqn.2014-06.com.example:remotedisk1
Created target iqn.2014-06.com.example:remotedisk1
Created TPG 1
```
An admin can use the create w/o specifying the IQN to create. targetcli will generate an IQN similar to the following: iqn.2003-01.org.linux-iscsi.server0.x8664:sn.69b30d2cfd01. Specifying the IQN value provides the ability for an admin to use a meaningful namespace for their IQNs.
5. In the TPG, create an ACL for the client node to be used later. B/c the global auto_add_mapped_luns parameter is set to true (default), any existing LUNs inthe TPG are mapped to each ACL as it is created.
```
/iscsi> cd iqn.2014.com.example:remotedisk1/tpg1
/iscsi/iqn20...sk1/tpg1> acls/ create iqn.2014-06.com.example:desktop0
Created NODE ACL for iqn...:desktop0
```
This ACL configures the target to only accept initiator connections from a client presenting iqn.2014-06.com.example:desktop0 as its initiator IQN, also known as the initiator name.
6. In this TPG, create a LUN for ea existing backstores. This step also activates each backstore. B/c acls exist for the TPG they will be automatically assigned to ea LUN created.
```
/iscsi/iqn.20...:server0/tpg1> luns/ create /backstores/block/block1
Created LUN 0
Created LUN 0->0 mapping in node ACL iqn...:desktop0
/iscsi/iqn.20...:server0/tpg1> luns/ create /backstores/block/block2
Created LUN 1
Created LUN 1->1 mapping in node ACL iqn...:desktop0
/iscsi/iqn.20...:server0/tpg1> luns/ create /backstores/block/block3
Created LUN 2
Created LUN 2->2 mapping in node ACL iqn...:desktop0
```
Having 3 LUNs assigned to a target means that when the initiator connects to the target, it will receive three new SCSI devices.
7. Still inside the TPG, create a portal configuraiton to designate the listening IP addr and ports. Create a portal using the systems pub net int. W/o specifying a TCP port to use, the portal creation will default to the standard iSCSI port 3260.
```
/iscsi/iqn.20...:server0/tpg1> portals/ create myserveraddr
Using default IP port 3260
Created network portal myserveraddr:3260
```
If the IP is not specified w/ the poral creation an IP of 0.0.0.0 will be used. This will permit cons on all net ints defined on the server.
8. View the entire config, then exit targetcli. targetcli will auto save upon exit. The resulting persistent config file is stored in JavaScript Object Notation (JSON) format.
```
/iscsi/iqn.20...:server0/tpg1> cd /
/> ls
...
/> exit
```
9. Add a port exemption to the default fw for port 3260.
```
firewall-cmd --permanent --add-port=3260/tcp
firewall-cmd --reload
```
10. Enable the target.service systemd unit. The target.service will recreate the tgt config from the json file at boot. If this step is skipped, any config tgts will work until the machine is rebooted; however, after a reboot, no tgts will be offered by the server:
```
systemctl enable target
```


#### Authentication
In addition to ACL node verification, pass based auth can be implemented. Auth can be required duing the iscsi discovery phase. Auth can be unidirectional or bidirectional.

CHAP auth does not use str enc for passing of creds. While CHAP does offer an additional factor of auth besides having a correctly configure initiator name, configured in an ACL, it should not be considered secure. If security of iscsi data is a concern, controlling the net side of the protocol is a better method to assure security. Providing a dedicated, isolated net, or vlans to pass iscsi traf will be more secure implmentation of the protocol.

#### command line mode
In the demo, targetcli was run in interactive mode, but targetcli can also be used to execute a series of cmds via a cli. In the following ex, target cli will be used to create a backstore device, an IQN, and activate a potal. This is a cursory, if *incomplete*, example of the non-interactive capabilities of targetcli.
```
$ targetcli /backstores/block create block1 /dev/vdb
Created block storage object block1 using /dev/vdb
$ targetcli /iscsi create iqn...:remotedisk1
Created tgt iqn.20...:remotedisk1
$ targetcli /iscsi/iqn...:remotedisk1/tpg1/portals create myserveraddr
Using default IP port 3260
Created network portal myserveraddr:3260
$ targetcli saveconfig
```



