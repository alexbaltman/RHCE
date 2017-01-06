## Net Teaming

### Overview
Net teaming is a method for linking NICs together logically to allow for failover or higher throughput. Temaing is a new implementation that does not affect the older bonding driver in the linux kernel; it offers an alternative implementation. RHEL7 supports channel bonding for backward compatability. Network temaing provides better performance and is more extensible b/c of its modular design. 

Network teaming in RHEL7 is is done via a sm kernel driver and a user space daemon, *teamd*. The kernel handles network packets efficiently and teamd handles logic and int processing. Software, called runners, implement load balancing and active-backup logic, such as roundrobin. The following runners are available to teamd:
- broadcast: a simple runner which trasmits ea packet from all ports
- roundrobin: a simple runner which transmits packets in round robin fashion from ea of the ports
- activebackup: this is a failover runner which watches for link changes and selects an active port for data transfers
- loadbalance: this runner monitors traffic and uses a hash func to try to reach a perfect balance when selecting ports for packets transmission
- lacp: implements 802.3ad link aggreg control protocol. Can use the same transmit port selection as loadbalance runner.

All net interaction is done through a team int, composed of multiple net portort ints using NetworkManager and esp when fault finding. Keep in mind:
+ Starting the net team int does not auto start the port int.s
+ Starting a port int always starts the teamed int
+ Stopping the teamed int also stops the port int.s
+ A teamed int w/o ports can start static IP cons
+ A team w/o ports waits for ports when starting DHCP cons
+ A team w/ a DHCP con waiting of rports completes when a port w/ a carrier is added
+ A team w/ a DHCP con waiting for ports continues waiting when a port w/o a carrier is added

### Config net teams
1. Create the team interface
```
nmcli con add type team con-name team0 ifname team0 config '{"runner": {"name": "loadbalance"}}'
```
2. Set ipv4 and/or ipv6 attr.s. Note: that the ipv4.addresses have to be assigned before the ipv4.method can be set to manual.
```
nmcli con mod team0 ipv4.addresses 1.2.3.4/24
nmcli con mod team0 ipv4.manual
```
3. Assign the port int.s to the team. ifname here is the name of an existing interface. Also, the default name will be team-slave-IFACE if unset or you can set with "con-name myslave"
```
nmcli con add type team-slave con-name team0 ifname eth1 master TEAM
```
4. Bring the team and port int up/down
```
nmcli dev dis eth1
nmcli con up myteamcon
```
5. Check state
```
teamdctl team0 state
```
