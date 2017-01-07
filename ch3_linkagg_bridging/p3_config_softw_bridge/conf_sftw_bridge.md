## Configuring Software Bridges

### Overview
A net bridge is a link layer device (layer 2 of OSI model) that fwd.s traffic /bw nets based on mac addr.s. It learns what hosts are connected to ea net, builds a table of mac addr.s, then makes packet forwarding decisions based on that table. A softw bridge can be used in a Linux env to emulate a hw bridge. The most common app for softw bridges is in virt app.s for sharing an hw nic among 1+ virt nics. 

### Config Softw Bridges
nmcli can be used to config softw bridges persistently. 
- Create Bridge
```
nmcli con add type bridge con-name br0 ifname br0
```
- Add Existing int.s to Bridge
```
nmcli con add type bridge-slave con-name br0-port1 ifname eth1 master br0
nmcli con add type bridge-slave con-name br0-port2 ifname eth2 master br0
```

Note: NetworkManager can only attach Ethernet int.s to a bridge. It down NOT SUPPORT aggregate int.s such as a teamed or bonded int. These must be configured by manipulating the config files in /etc/sysconfig/network-scripts.


#### Software bridge config files
Important ifcfg-br1 lines:
- TYPE=Bridge: Defines that this is a softw bridge
- BRIDGING_OPTS=priority=32768: defines additional bridge options. 
- IPADDR0=myipaddr: You may (or may not) assign a static ip to a bridge.

Important bridge port lines (ifcfg-br1-port0):
- DEVICE=eth1
- BRIDGE=br1: This ties the int to the softw bridge br1

Note: To implement softw bridge on an existing teamed or bonded net int managed NetworkManager, NetworkManager will ahve to be disabled since it onoly supports bridges on simple Ethernet int.s. Config files for the bridge will have to be created by hand and the ifup/ifdown utils can be used to manage the softw bridge and net ints.

- List software bridges and their interfaces
```
brctl show
```
