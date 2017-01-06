## IPV6 Net Concepts

### Overview
- 128 bit num expressed in 8 colon separated groups of 4 hex "nibbles" (aka half-bytes)
- Ea. nibble rep.s 4 bits of the ipv6 addr, so ea grp rep.s 16 bits of the ipv6 addr
```
2001:0db8:0000:0010:0000:0000:0000:0001
```
- /64 is default netmask instead of /24 for ipv4 
- When writing, you may strip leading zeros in ea grp, writing at least 1 nibble in ea field.
```
2001:db8:0:10:0:0:0:1
```
- One or more grp.s of consec zeros may be combined w/ exactly one :: block
```
2001:db8:0:10::1
or
2001:db8::0010:0:0:0:1
```

Some tips to reduc confusion when there are 2+ ways to shorten an addr:
1. Always, suppress Leading zeros in a grp 
2. Use :: to shorten as much as possible
3. Do not use :: to shorten one grp of zeros, use :0: instead, saving :: for runs
4. Always use lowercase letters for hex numbers a-f
5. Additionally, when including tcp or udp network port after an ipv6 addr, ALWAYS enclose the ipv6 addr in square brackets tso the port does not look like it is part of the addr
```
[2001:db8:0:10::1]:80
```

### IPv6 Subnets
A normal unicast addr is divided into two parts, the network prefex and the int ID. The network prefix id.s the subnet. No two net int.s on the same subnet can have the same int ID; the int ID indentifies a particular int on the subnet.

Unlike ipv4, ipv6 has a standard subnet mask, which is used for almsot all normal addr.s, /64. In this case, half of the addr is the network prefix and half of it is the int ID. This means that a single subnet can hold as many hosts as necessary.

Typically, the network provider will allocate a shorter prefix to an org, such as /48. This leaves the rest of the net part for assigning subnets from that allocated prefix. For a /48, that leaves 16 bits for subnets (up to 65536 subnets).

### IPv6 Addr alloc
| IPv6 addr or net | Purpose | Description |
| --- | --- | --- |
| ::1/128 | localhost | IPv6 equiv to 127.0.0.1/8 set on loopback |
| :: | The unspecified addr | Equiv to 0.0.0.0 for a net svc, could indicate it is listening on all addr.s |
| ::/0 | Default route (ipv6 internet) | ipv6 equiv to 0.0.0.0/0. The default route in the routing table matches this net; the router for this net is where traffic is sent for which there is not a better route |
| 2000::/3 | Global unicast addr.s (The internet) | Normal ipv6 addr.s currently being alloc from this space by IANA. This is equiv to all net.s ranging from 2000::/16 through 3fff::/16 |
| fd00/8 | unique local addr.s (RFC 4193) | IPv6 has no equiv to RFC1918 - a site can use these to self-alloc a prvt routable ip addr space inside org, but these net.s cannot be used on global internet |
| fe80::/64 | Link-local addr | all ipv6 int auto config.s a link local addr that only works on local link on this net. | 
| ff00::/8 | Multicast | The ipv6 equiv to 224.0.0.0/4. Multicast is used to transmit to multiple hosts at the same time, and is particularly important b/c ipv6 has no broadcast addr.s |

#### Link local addr.s
A link local addr in IPv6 is an unroutable addr, which is used only to talk to hosts on a specirfic net link. Every net int on a sys is auto config w/ a link local on fe80:: net. To ensure that it is unique, the int ID of the link local addr is constructed form the net int.s eth hw addr. 

The usual procedure is to convert the 48 bit mac addr to 64 bit int ID is to set bit 7 of the mac addr and insert ff:fe b/w its two middle bytes.

Ex:
- net prefix: fe80::/64
- mac addr: 00:11:22:aa:bb:cc
- link local then equals fe80::211:22ff:feaa:bbcc/64

The link local addr.s of other machines can be used like normal addr.s by other hosts on the same link. Since every link has a fe80::/64 net on it, the routing table cannot be used to select the outbound int correctly. The link to ue when talking to a link local addr must be specified w/ a scope identifier at the end fo the addr. The scope identifier consists of % followed by the name of the net int.

Ex:
```
ping6 fe80::211:22ff:feaa:bbcc%eth0
```

Note: Scope identifiers are only needed when contacting addr.s that have link scope. Normal global addr.s are used just like they are in ipv4 and select their outbound int.s from the routing table.

#### Multicast
Multicast plays a larger role in ipv6 than in ipv4 b/c there is no broadcast addr in ipv6. One key multicast addr in ipv6 is ff02::1, the all-nodes link local addr. Pining this addr will send traffic to all nodes on the link. Link scope multicast addr.s (starting ff02::/8) need to be specified w/ a scope identifier, just like a link local addr.
```
ping6 ff02::1%eth0
```

### IPv6 addr config concepts
ipv4 has two ways in which addr.s get config.d on the net int.s - dhcp or static. IPv6 supports; dhcp6, static, AND SLAAC.

#### Static
You may select ipv6 addr.s at will w/ the exception of 2 addr.s
- The all zero identifier: 0000:0000:0000:0000 ("subnet router anycast") used by all routers on the link (for 2001:db8::/64 this woudl be the addr 2001:db8::)
- The identifiers fdff:ffff:ffff:ff80 through fdff:ffff:ffff:ffff

#### DHCP6
There is no broadcast so a host sends a dhcp6 request from its link local addr to port 547/UDP on ff02::1:2, the all dhcp servers link local multicast grp, which the server then responds on port 546/UDP on client's link local.

#### SLAAC
Stateless addr autoconfig. The host can bring up its int w/ a link local addr as normal and then sends a router solicitation to ff02::2, the all routers link local multicast grp. An ipv6 router on local link responds to the host's link local ddr w/ a net prefix and other info. The host then uses that net prefix w/ an int ID that it normally constructs in the same way that link local addr.s are constructed. The router periodically sends multicast updates (router advertisements) to confirm or update the info it provided.

The radvd package in rhel7 allows to use slaac. 

Note: A typical rhel7 machine configured to get ipv4 addr through dhcp is usually also config.d to u se slaac to get ipv6 addr.s. This can result in machines unexpectedly obtaining ipv6 addr.s when an ipv6 router is added to the network. 
Note2: Some ipv6 deployments combine slaac and dhcp6 using slaac to only provide network addr info and dhcp6 to provide other info, such as which dns server and search domains to config.

### Quick practice
Match the following with the table below:
a. 2000::1
b. 2001:3:700::2
c. 2001:3::7:0:2
d. 2001:db8:0:7::2
e. 2001:db8::7::2
f. 2::1
g. ::
h. ff02::1:0:0


| IPv6 Addr | Compressed IPv6 addr |
| --- | --- |
1. 20000:0000:0000:0000:0000:0000:0000:001
2. 0002:0000:0000:0000:0000:0000:0000:0001
3. 2001:0db8:0000:0007:0000:0000:0000:0002
4. 2001:0003:0000:0000:0000:0007:0000:0002
5. 2001:0003:0700:0000:0000:0000:0000:0002
6. ff02:0000:0000:0000:0000:0001:0000:0000
7. 0000:0000:0000:0000:0000:0000:0000:0000
8. Not valid ipv6 addr

---
Answers:
a1,b5,c4,d3,e8,f2,g7,h6

