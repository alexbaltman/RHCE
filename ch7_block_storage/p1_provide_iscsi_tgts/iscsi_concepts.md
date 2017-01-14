## ISCSI Conecpts

### Overview
Internet sm comp sys interface (iSCSI) is a tcp/ip protocol for emulating a SCSI high perf local stor bus over IP networks, providing data transfer and mgmt to remote blk stor devs. As a storage area network (SAN) protocol, iSCSI extends SANs across local and wide area networks (LANs, WANs, adn the internet), providing location indep data storage retrieval w/ distrib servers and arrays.

The SCSI protocol suite provides the Command Descriptor Block (CDB) cmd set over a dev bus com protocol. The original SCSI topology used physical cabling with a 20 meter limitation for all devs per channel (cabled bus). Devs used unique numeric tgt IDs (0-7, or 0-15 w/ dual channel). Physical SCSI disks and cabling were obsoleted by popular implementation of Fibre Channel (FC), which retained the SCSI CDB cmd set but replaced the disk and bus com w/ protocols for longer and faster optical cabling.

The iSCSI protocol also retained the CDB cmd set, performing bus com b/w iSCSI systems that is encapsulated over standard tcp/ip. iscsi servers emulate scsi devs using files, logical vols, or disks of any type as the underlying storage (backstore) presented as **targets**. An iscsi server is typically implemented in soft above either an OS tcp/ip stack or a TCP offload engine (TOE), a specialized Ethernet net int card (NIC), that includes tcp/ip network layers to inc perf. iscsi can also be hw implemented as a host bus adapter (HBA) for greater perf.

Enterprise grade SANs req dedicated traf infra. FCs indep optical cabling and switches guarantees isolation. iscsi should also be implemented on cabling that is indep of standard LAN traf, since perf can degrade due to bandwidth congestion on shared networks. Both Ethernet and FC now offer copper and optical cabling options, allowing net consolidation combined w/ traf classification. 

Stor area net traf is typically unencrypted since phys server to stor cabling is normally enclosed w/in secure data centers. For WAN security, iscsi and FCoE (Fiber channel over ethernet) can utilize Internet Protocol Security (IPSec), a protocol suite for securing IP net traf. Selec networking hw (preferred NICs, TOEs, and HBAs) can provide encyption. iscsi offers challenge-handshake auth protocol (CHAP) usernames/pass as an auth mechanism to limit connectivity b/w chosen initiators and tgts.

Until recently, iscsi was not considered an enterprise grade sto option, primarily due to the use of slower 100 and 1000Mb/s Ethernet, compared to FC's 1 and 4 Gb/s optical infra. With current 10 or 40 Gb/s Ethernet and 8, 10, 16, 0r 20 Gb/s FC and pending 100 Gb/s Ehternet and 32 or 128 Gb/s FC, bandwidth avail is now similar for both.

The use of iscsi extends a SAN beyond the limits of cabling, facilitating stor consolidation in local or remote DCs. B/c iscsi structures are logical, new sto allocations are made using only soft config, w/o the need for additional cable or phys disks. iscsi also simplifies data replication, migration and disaster recovery using multiple remote DCs.

### iSCSI Fundamentals
The iSCSI protocol functions in a familiar client-server config. Client systems config initiator soft to send SCSI commands to remote server storage targets. Accessed iscsi targets appear on the client sys as local, unformatted scsi block dev.s, identical to devs connected w/ scsi cabling, FC direct attached, or FC switched fabric.

iscsi component Terminology:
| Term | Description |
| --- | --- |
| initiator | An iscsi client, as soft/hw. Initiators must be given unique names (see IQN) |
| target | An iscsi storage resource configured for connection from an iscsi server. Targets must be given unique names (see IQN). A tgt provides one or more numbered blk devs called logical units (LUN) An iscsi server can provide many tgts concurrently |
| ACL | An access control list, an access restriction using the node IQN, commonly the iscsi initiator name to validate access perms for an initiator |
| discovery | querying a tgt server to list configured tgts. Target use requires an additional access steps (see login) |
| IQN | An iscsi qualified name, a worldwide unique name used to id both initiators and tgts in form: iqn.YYYY-MM.com.reversed[:optional_string]. iqn signify that this name will use a domain as its identifier. YYYY-MM - the first month in which the domain name was owned. |
| login | Authenticating to a tgt or LUN to begin client blk dev use. |
| LUN | A logical unit number, numbered blk devs attached to and avail through a tgt. One or more LUNs may be attached to a single tgt, although typically a tgt provides only one LUN. |
| node | any iscsi initiator or iscsi tgt, identified by its IQN |
| portal | An ip addr and port on a tgt or initiator used to establish cons. Some iscsi implementations use portal and node interchangeably |
| TPG | Target portal grp, the set of interface ip addrs and TCP ports to which a specific iscsi tgt will listen. Tgt config (e.g ACLs) can be added to the TPG to coordinate settings for multiple LUNs |


iscsi uses ACLs to perform LUN masking, managing the accessibility of appropriate tgts and LUNs to initiatros. Access to tgts may also be limited with CHAP auth. iscsi acls are similar to fc use of dev worldwide numbers (WWNs) for soft zoning mgmt restrictions. Although FC switch level compulsory port restriction (hard zoning) has no comparabile iscsi mechanism, ethernet vlans could provide similar isolation security. 

Unlike local blk devs, iscsi net accessed blk devs are discoverable from many remote initiators. Typically local file systems (eg ext4, xfs, btrfs) do not support concurrent multisystem mounting, which can result in significant file system corruption. Clustered systems resolve multiple sys access by use of the Global File System (GFS2), designed to provide distributed file locking and concurrent multinode file system mounting.

An attached iscsi blk dev appears as a local scsi blk dev (sdx) for use underneath a local fs, swap space or a raw DB installation.


---
### Quick Practice
Match the following letters to the numbers below:
a. IQN
b. LUN
c. WWN
d. initiator
e. node
f. portal
g. target


1. Unique name to identify indiv iscsi targets and initiators
2. Unique number to id indiv FC port and nodes
3. Storage resource on an iscsi server
4. Storage resource blk dev on an iscsi server
5. iscsi client implemented in either soft or hw
6. A single iscsi initiator or target
7. A single IP con addr on an initiator or tgt



---

Answers: 
a1,c2,g3,b4,d5,e6,f7
