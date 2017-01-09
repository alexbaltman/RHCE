## Masquerading and Port Forwarding

### Overview
Firewalld supports two types of NAT: masquerading and port forwarding. They will both modify certain aspects of a pack, e.g. source/destination, before sending it on.

### Masquerading
Changes src addr. With masquerading a system will forward packets that are not directly addressed to itself to trhe inteded recipient, while changing the source address of the packets that go through to its own p9ublic IP address. When answers to those packets come in, the firewall will then modify the destination address to the address of the original host and send the packets on. This is usually used on the edge of a network to provide internet access to an internal network. Masquerading is a form of Network Address Translation (NAT).

Note: masquerading can only be used w/ ipv4 not ipv6

#### Example of masquerading
1. One of the machines behind the firewall sends a packet to an address outside of the local network. The packet has a source addr of 10.0.0.100 (addr of the machine) and a dest addr of 2.17.39.214.
2. Since the dest is not on the local subnet, the packet will be routed to the default gateway configured on the src machine; in this case 10.0.0.1, the ip addr of the fw.
3. The fw accpets the packet, chagne the src addr to 1.2.3.4 (ext ip for the fw), stores a ref to this con in its con state table, then packetasses it to a router on the internet based on its routing table.
4. An answer to the packet comes back from the internet. The router looks up the con in its con state table, then chagneanges the dest addr to 10.0.0.100 (the orig sender) and passes the packet on.

#### Configuring masquerading
To config masq for a zone w/ reg firewall-cmd cmds use the following syntax:
```
firewall-cmd --permanent --zone=myzone --add-masquerade
```

This will masq any packets sent to the fw from clients defined in the srcs for that zone (both interfaces and subnets) that are not addressed to the fw itself. 

To gain more control over what clients will be masq, a rich rule can be used as well:
```
firewall-cmd --permanent --zone=myzone --add-rich-rule='rule family=ipv4 source address=192.168.0.0/24 masquerade'
```

### Port Forwarding
Another form of NAT is port forwarding. With port forwarding traffic to a single port is forwarded either to a diff port on the same machine or to a port on a diff machine. This mechanism is typically used to "hide" a server behind another machine or provide access to a svc on an alt port.

Note: When a port fwd is configured to fwd packets to a diff machine, any replies from that machine will normally be sent directly to the orig client from that machine. Since this will result in an invalid con on most configs, the machine that is forwaded to will have to be masq through the fw that perf the port fwd. --> A common config is to fwd a port from the fw machine to a machine that is already masq behind the fw. 

#### Example of Port Forwarding
1. A client from the internet sends a packet to port 80/tcp on the ext int of the fw.
2. The fw changes the dest addr and port of this packet to 10.0.0.100 and 8080/tcp and forwards it on. The src addr and port remain unchanged. 
3. The machine behind the fw sends a response to this packet. Since this machine is being masqueraded (and the fw is configed as the default gw), this packet is sent to the orig client, appearing to come from the ext int of the fw. 

#### Config Port Forwarding
Using firewall-cmd, use the following syntax:
```
firewall-cmd --permanent --zone=myzone --add-forward-port=port=myportnum:proto=myprotocol:[toport:myportnum][:toaddr=myipaddr] 
```
Both the toport and toaddr parts are optional, but at least one of those two will need to be specified.

As an example:
```
firwall-cmd --permanent --zone=public --add-forward-port=port=513:proto=tcp:toport=132:toaddr=192.168.0.254
```
This will forward inc cons on port 513/tcp on the fw to port 132/tcp on the machine w/ the ip addr 192.168.0.254 for clients from the public zone.

You may also use rich rules like this:
```
forward-port port=portnum protocol=tcp|udp [to-port=portnum] [to-addr=myaddr]
```
Rich rule ex:
```
firewall-cmd --permanent --zone=work --add-rich-rule='rule family=ipv4 source address=192.168.0.0/26 forward-port port=80 protocol=tcp to-port=8080
```
This will forward traffic from 192.168.0.0/26 in the work zone to port80/tcp to port 8080/tcp on the fw machine itself.
