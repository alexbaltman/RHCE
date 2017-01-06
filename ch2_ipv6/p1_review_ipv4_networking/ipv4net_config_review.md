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
```
nmcli dev disconnect device
nmcli dev dis eth0
```
Use nmcli dev dis device to deactivate a net int. The cmd "nmcli con down *name*" is normally not the best way to deactivate the net in b/c by default most wired system con.s are configured with autoconnect enabled and once you bring it down NetworkManager will bring it back up again unless the con is entirely disconnected from the int. 

#### Modify net con settings
NetworkManager con.s have two kinds of settings, there are the static cons properties which are configured by the admin and stored in the /etc/sysconfig/network-sciprts/ifcfg- and there may also be active con data, which the con gets from DHCP and do not store persistently.

To list the current settigns for a con, run
```
nmcli con show static-eth0
```
Settings in lowercase are static properties the admin can bchange; settings in all caps are active settings in temp use for the intance of the con. 

```
nmcli con mod static-eth0 ipv4.addresses "192.0.2.2/24 192.0.2.254"
```
This will change the settings for a con. These changes will also be saved. For all settings view nm-settings man page.


Note: If a con that got its IPv4 from DHCPv4 server is being changed from static files oly, the setting ipv4.method should also be changed from auto to manual otherwise the con may hang or not complete when it is activated or it could get addr from DHCP in addition to the static addr.

A number of settings may have multiple values. A specific value can be added to the list or deleted from the list for a setting by adding a + or - symbol to the start of the setting name.
```
nmcli con mod static-eth0 +ipv4.dns 192.0.2.1
```

By default, change made w/ nmcli con mod *name* are automatically saved, which can be manually edited afterwhich you should run 
```
nmcli con reload
```
This will result in NetworkManager rereading the config changes. 

For backward compatibility reasons, the directives saved in that file have diff names and syntax than the nm-setrtings. The following table maps some of them to ifcfg settings.

| nmcli con mod | ifcfg- file | Effect |
| --- | --- | ---| 
| ipv4.method manual | BOOTPROTO=none | ipv4 addr config statically |
| ipv4.method auto |  BOOTPROTO=dhcp | use dhcp for ipv4 addr then static if present |
| ipv4.addresses mycidr mygw | IPADDR0=myip, PREFIX0=24, GATEWAY0=mygw | sets sttic addr, net prefix and default gw. |
| ipv4.dns 8.8.8.8 | DNS0=8.8.8.8 | mod resolv.conf to use this nameserver |
| ipv4.dns-search example.com | DOMAIN=ex.com | mod resolv.conf to use this search domain |
| ipv4.ignore-auto-dns true | PEERDNS=no | ignore DNS server info from DHCP |
| connection.autoconnect yes | ONBOOT=yes | auto activate con at boot |
| connection.id eth0 | NAME=eth0 | the name of the con |
| connection.interface-name eth0 | DEVICE=eth0 | con is bound to named net int |
| 802-3-ethernet.mac-address ... | HWADDR=... | con is bound to net int w/ this mac addr |


Note: b/c NetworkManager tends to directly mod the resolv.conf direct changes may be overwritten. To change settings in that file it is better to set DNSn and DOMAIN directives in ifcfg files.

#### Deleting Net con
```
nmcli con del *name*
```
The con del cmd will delete the con named, disconnecting it from the dev and removing the ifcfg file.

### Mod sys hostname
The hostnname cmd displays or temp mod.s the sys. fqdn and a static hostname may be specified in the /etc/hostname file. The hostnamectl cmd is used to mod this file and may be used to view the status of the fqdn of the system
```
hostnamectl set-hostname blahblah.ex.com
```

### Summary of commands
| Command | Purpose |
| --- | --- |
| nmcli dev status | Show NetworkManager status of all net int.s | 
| nmcli con show | List all con.s | 
| nmcli con show *name* | List current settings for con of *name* |
| nmcli con add con-name *name* | Add a new con name *name* | 
| nmcli con mod *name* ... | Mod a con |
| nmcli con reload | Tell NetworkManager to reread the config files (for when editing files by hand) |
| nmcli con up *name* | Activate a con |
| nmcli dev dis *dev* | Deactivate and disconnect the current con on the net int dev |
| nmcli con del *name* | Delete the con and its config file |
| ip addr show | Show the current net int addr config |
| hostnamectl set-hostname *name* | Persistently set hostname |

### Ipv4 config procedures
Assumptions:
1. No pre-existing profile in nmcli
2. No pre-existing file in /etc/sysconfig/network-scripts

Steps:
1. sudo su -
2. Inspect system:
```
ip link
nmcli con show
```
3. Create nmcli profile
```
nmcli con add con-name myprofile type ethernet ifname mysysinterface
```
4. Add ipv4 addr to profile
```
nmcli con mod myprofile ipv4.addresses "myipcidr"
```
5. Make method of acquiring ip static (jic it is dhcp)
```
nmcli con mod myprofile ipv4.method manual
```
6. Restart int (can alt use ifdown/ifup w/ the int instead of the profile))
```
nmcli con down myprofile
nmcli con up myprofile
```
7. Check it
```
ip addr show dev eth1
```
8. Ping from it
```
ping 192.168.7.66
```
9. (Optional) Check profile's file
```
cat /etc/sysconfig/network-scripts/ifcfg-myprofile
```

Vagrant Assumptions:
1. Interface is already configured
2. Int is set to NM_CONTROLLED=no
3. No nmcli profile exists
4. Using eth1

Steps in Vagrant:
1. For the int you want to use, change nmcontrolled in /etc/sysconfig/network-scripts/ifcfg-eth1
```
NM_CONTROLLED=yes
```
2. Set IPADDR/IPADDR0 in the file or use nmcli
```
IPADDR=192.168.7.66
or
nmcli con mod "System eth1" ipv4.addresses "mycidr"
```
3. Set to manual if using nmcli method
```
nmcli con mod "System eth1" ipv4.method manual
4. Restart int (can alt use ifdown/ifup w/ the int instead of the profile)
```
nmcli con down "System eth1"
nmcli con up "System eth1"
```
5. Check it
```
ip addr show dev eth1
```
6. Ping from it
```
ping 192.168.7.66
```
7. (Optional) Check profile's file
```
cat /etc/sysconfig/network-scripts/ifcfg-eth1
```
