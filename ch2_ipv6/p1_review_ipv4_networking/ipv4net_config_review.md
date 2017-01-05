## IPV4 Net Config Review

### Overview
- A device is a network interface
- A connection is a collection of settings that can be configured for a device
- only one connection is active fo any one device at a time
- The persistent config for a con is in /etc/sysconfig/network-scripts/ifcfg-<name>, where name is the name of the con w/ spaces swapped for underscores. The file can be edited by hand as needed or by nmcli for cli control.

### Basics
- View status of net dev.s
```
nmcli dev status
```
- View con.s
```
nmcli con show
nmcli con show "System eth0"
nmcli con show --active
```
- ip addr to desply the current config of net int.s
```
ip addr show eth0
```
Resulting in four primary pieces of information:
1. An active interface is "UP" an inactive is likely "DOWN"
2. the link/ether line specifies the mac addr
3. the inet lines shows an ipv4 addr, net prefix len, and scope
4. the inet6 lines shows an ipv6 addr, net prefix len, and scope

#### Adding a con
Assuming the name of the net con being added is not already use you can
```
nmcli con add con-name eno2 type ethernet ifname eno2
```
This command will add a new connection to the int eno2, which will get ipv4 networking information using DHCP and will autoconnect on startup. The config will be saved in /etc/sysconfig/network-scripts/ifcfg-eno2 b/c the con-nmae is eno2.
```
nmcli con add con-name eno2 type ethernet ifname eno2 ipv4 192.168.0.5/24 gw4 192.168.0.254
```
This command config.s the eno2 interface statically instead, using the IPv4 addr and network prefex 192.168.0.5/24 , but still autoconnects at startup and saves its config int9ot he same file. 

#### Controlling net con.s
```
nmcli con up static-eth0
```
This command will activate the con name on the net int it is bound to. Note that the cmd takes the name of con, not the name of the net int. Remember that nmcli con show can be used to list the names of all avail con.s.
```nmcli dev disconnect device```

