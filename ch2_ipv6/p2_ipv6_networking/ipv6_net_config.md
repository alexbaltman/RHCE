## IPV6 Net Config

### Adding ipv6 net con
```
nmcli con add con-name eno2 type ethernet ifname en02
```
This cmd will add a new con to the int eno2, which will autoconnect at startup, getting ipv4 net info using dhcpv4. It will also get ipv6 net setttings by listening for router advertisements on the local link.
```
nmcli con add con-name eno2 type ethernet ifname eno2 ip6 2001:db8:0:1::c000:207/64 gw6 2001:db8:0:1::1 ip4 192.0.2.7/24 gw4 192.0.2.1
```
Configures eno2 statically w/ ipv6 and ipv4. All set in the usual /etc/sysconfig/network-scripts/ifcfg-

### Mod net con ipv6
```
nmcli con mod myprofile ipv6.address "2001:db8:0:1::a00:1/64 2001:db8:0:1::1"
```
Note: if a con that got its ipv6 info via slaac or dhcp6 server is being changed to get it from static config files only, the setting ipv6.method should be changed from auto or dhcp to manual, otherwise, the con may hang or not complete successfully when it is activated or it may get wrong ip.
```
nmcli con mod myprofile ipv6.method manual
```

Add DNS server to con
```
nmcli con mod myprofile +ipv6.dns 2001:4860:4860::8888
```
Note:
Static ipv4 and ipv6 DNS settings all end up a nameserver directives in /etc/resolv.conf, it is preferable to have one for each static (ipv4 and ipv6) for connectivity issues.

### Mapping of nmcli and ifcfg-
| nmcli con mod | ifcfg- file | Effect |
| --- | --- | --- |
| ipv6.method manual | IPV6_AUTOCONF=no | ipv6 addr.s config.d statically |
| ipv6.method auto | IPV6_AUTOCONF=yes | will config net using slaac from router advert | 
| ipv6.method dhcp | IPV6_AUTOCONF=no, DHCPV6=yes | will config net using dhcpv6, but not slaac |
| ipv6.addresses ... | IPV6ADDR=..., IPV6_DEFAULTGW=... | static setup, if other addrs can use IPV6_SECONDARIES, which takes a double quoted list of space delimited arrs/prefix def.s |
| ipv6.dns ... | DNS0=... | mod.s resolv.conf to use this nameserver | 
| ipv6.dns-search ex.com | DOMAIN=ex.com | mod.s resolv.conf to use this search domain | 
| ipv6.ignore-auto-dns true | IPV6_PEERDNS=no | Ignore DNS server info from DHCP |
| connection.autoconnect yes | ONBOOT=yes | auto activate this con at boot |
| connection.id eth0 | NAME=eth0 | name of con |
| connection.interface-name eth0 | DEVICE=eth0 | con is bound to the net int w/ this name |
| 802-3-ethernet.mac-addr ... | HWADDR=... | con is bound to net int /w this mac |

### Viewing ipv6 net info
- Check ipv6 for a dev
```
ip addr show eth0
```
There should be two lines with inet6 showing ipv6 addr.s. The first inet6 is the global scope addr and is normally used. The second inet6 starting w/ fe80 is the link local addr. 
- Check ipv6 routes
```
ip -6 route show
```
Unreachable routes are routes to net.s that are never to be used, which leaves 3 routes; the global addr route, the link local route (fe80::/64) for ea int/dev, and a default route to all net.s (::/0 net).
```

### IPv6 Troubleshooting tools
```
ping6 someipv6addr
```
Must specify what dev to use if not using link local, otherwise you will see **connect: Invalid arguemnt**. the c argument is for count, so the following cmd sends just 1 test packet.
```
ping6 -c 1 someaddr%eth1
```
```
ssh someipv6addr%eth1
```
```
tracepath6 someipv6addr%eth1
```
```
tracepath -6 someipv6addr%eth1
```
Dislay information about network sockets via ss or the netstat commands.
```
ss -A inet -n
or
netstat -46n
```

Netstat and ss options:
| Option | Description |
| --- | --- | 
| -n | Show #s instead of names for ints and ports |
| -t | Show TCP sockets |
| -u | Show UDP sockets |
| -l | Show only listening sockets |
| -a | Show all (listening and established) sockets |
| -p | Show the process using the socket | 
| -A inet | Display active cons, but not listening for the inet addr family, ignoring local domain sockets |

For ss both ipv4 and ipv6 cons will be displayed for the A cmd. Netstat needs inet6 or dash 46 for both.

### Procedure to change net settings w/ nmcli
1. Create net mgr profile
```
nmcli con add con-name myprofile type ethernet ifname eth1
```
2. Set method to acquire ip addr and ip addr
```
nmcli con mod myprofile ipv6.addresses "myip/prefix mygw"
nmcli con mod myprofile ipv6.method manual
```
3. Test it
```
ping6 myip
ping6 mygw
ping6 another ipv6addr
ip -r route
```
4. (optional) discover other local ipv6 nodes
```
ip -6 ne
ping6 ff02::1%eth1 #Link local all-nodes multicast group
```
5. (optional) check the /etc/sysconfig/network-scripts/ifcfg-...
