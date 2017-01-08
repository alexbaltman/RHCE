## Managing Firewalld

### Overview
firewalld service manages the kernel netfilter subsystem using the low level iptables, ip6tables, and ebtables commands.

Note: It may be useful to prevent any of the table service variants from starting by masking them so they do not wipe out the firewalld config
```
systemctl mask iptables.service 
systemctl mask iptables6.service 
systemctl mask ebtables.service 
```

Firewalld separates all inc traffic into zones, w/ ea zone having its own set of rules. To check which zone to use for an inc con, firewalld uses this logic, first matching wins:
1. If the src addr of an inc packets matches a src rule setup for a zone that packet will be routed through that zone
2. Inc int for a packet matches a filter setup for a zone, that zone will be sued
3. default zone will be used. The default zone is not a separate zone; instead, it points to one of the other zones defined on the sys.

Default zone is the public zone.

Predefined zones shipped w/ firewalld:
| Zone name | Default config |
| --- | --- |
| trusted | allow all inc traffic |
| home | reject inc traffic unless related to outgoing traffic or matching the ssh, mdns, ipp-client, samba-client, or dhcpv6-client predefined services | 
| internal | reject inc traffic unless related to outgoing traffic or matching ssh, mdns, ipp-client, samba-client, or dhcpv6-client (same as home zone to start) |
| work | reject inc traffic unless related to outgoing traffic or matching ssh, ipp-client, or dhcpv6-client |
| public | reject inc traffic unless related to outgoing or matching the ssh or dhcpv6-client svcs |
| external | reject inc traf unless related to outgoing or matching ssh. Outgoing ipv4 traf fwd through this zone is masqueraded to look like it originated from the ipv4 addr of the outgoing net int |
| dmz | reject inc traf unless related to outgoing traf or matching ssh svc |
| block | reject inc traf unless related to outgoing traf |
| drop | drop all inc traf unless related to outgoing traf (do not respond to even ICMP) |

### Managing Firewalld
1. use firewall-cmd
2. use graphical firewall-config
3. use the config files in /etc/firewalld

#### Config using firewall-cmd
Comes w/ the firewalld package. Almost all cmds work on the runtime config unless the --permanent option is specified.  Many of the cmds take --zone=myzone, if omitted it will affect the default zone.

Activate perm changes using firewall-cmd --reload. While working on potentially dangerous cmds an admin can work on the runtime config by omitting the perm option. If extra caution is needed you can add --timeout=someseconds so it will remove the rule after the specified time.

firewall-cmds:
| Command | Explanation |
| --- | --- |
| --get-default-zone | query current default zone |
| --set-default-zone=myzone | changes both runtime and perm config |
| --get-zones | view all zones |
| --get-services | list all predefined svcs |
| --get-active-zones | view all zones in current use (have int or src tied to them) - int/src |
| --add-source=mycidr --zone=myzone | route all traf coming from cidr to zone listed or default |
| --remove-source=mycidr --zone=myzone | remove the rule routing traf from the ip from the zone or default |
| --add-interface=int --zone=myzone | route all traf from int to zone or default |
| --change-int=int --zone=myzone | assoc int w/ zone instead of current zone or change to default if none specified |
| --list-all --zone=myzone | list all config ints srcs, svcs, ports, etc for zone or for default zone |
| --list-all-zones | retried all info for all zones (ints, srcs, ports, svcs, etc.) | 
| --add-service=mysvc | allow traf to mysvc. if no --zone option then add to default |
| --add-port=myport/myprotocol | allow traf to port/protocol port on zone or default |
| --remove-service=mysvc | remove mysvc from allowed list of zone or default |
| --remove-port=myport/myprotocol | remove port/protocol port from allowed list for zone or default |
| --reload | drop the runtime config and apply the persistent config |
