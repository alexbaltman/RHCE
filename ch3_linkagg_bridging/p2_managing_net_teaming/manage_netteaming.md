## Mange Net Teaming

### Overview
NetworkManager creates config files for net teaming in the normal ifcfg- spot for ea int; the team and the ports. Important attr.s for teaming:
- DEVICETYPE: set to Team for the team int, informs init scripts this is net team int
- DEVICETYPE: set to TeamPort for the team ports
- TEAM_CONFIG: set w/ json to the parameters for the config of the team int
- TEAM_MASTER: set to team int (e.g. team0)

### Set/adjust team config
Default runner is roundrobin, which you can change w/ the team.config subcommand. You can change the runner with the nmcli con mod command. Changes take effect only on the next time the team int is brought up. link_watch setting is used to determine how the port is monitored, defaults to ethtool. Another method is arp_ping to check for remote connectivity. 

Can modify a team int via a file too like so:
```
nmcli con mod team0 team.confg /tmp/blah
```
You can view all the config for a team like this:
```
teamdctl team0 config dump > /tmp/blah
```

### Troublehsooting net teams
- View team ports
```
teamnl team0 ports
```
- View the currently active port of a team. Can also use setoption.
```
teamnl team0 getoption activeport
```
- View current state of a team
```
teamdctl team0 state
```
- View current state of a team in json format
```
teamdctl team0 config dump
```
