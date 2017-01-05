## Intro to systemd
Systemd replaces init as pid 1
New feat.s
    parallelization to inc boot speeds
    On-demand starting od daemons w/o requiring a separate svc
    Svc dependency  mgmt
    Tracking related processes together using lnux control groups

List Available systemd objects (units). 
```
systemctl -t help
systemctl -t help -l  # prevent ellipsize
```

1. Service units have .service extension and represent system services
2. Socket units have a .socket extension and represent IPC sockets - these are used to delay the start of a servie at boot time and to start less frequently used services on demand similar to xinetd. 
3. Path units have a .path extension and are used to delay the activation of a service until a specific file system change occurs e.g. spool dirs

### systemctl status <name.type>

| Keyword | Description |
| --- | --- |
| loaded  | Unit config file has been processed |
| active (runnning) | Running w/ one or more continuing processes |
| active (exited) | Successfully completed a one time config |
| active (waiting) | Running but waiting for an event |
| inactive | Not running |
| enabled | persistent | 
| disabled | not persistent |
| static | cannot be enabled, but may be started by an enabled unit |

- Query state of all units 
```
systemctl
```
- Query the state of only the service units
```
systemctl --type=service
```
- Investigate any units which are in a failed or maintenance state
```
systemctl status <mysvc.servic> -l
```
- List the active state of all loaded units. Optionally, limit the type of unit. The --all option will add inactive units.
```
systemctl list-units -type=service
systemctl list-units -type=service -all
```
- View the enabled and disabled settings for all units. Optionally, limit the type of unit
```
systemctl list-unit-files --type=service
```
- View only faiiled services
```
systemctl --failed --type=service
```
- View status of pid
```
ps <pid #>
```
- Have svc read and reload its config w/o restarting
```
systemctl reload <mysvc>
```

Services may be started as dependencies of other services or as a file system cndition is met via a path unit trigger. --reverse will show what units need to have the specified unit started in order to run.
- View dependencies of a unit
```
systemctl list-dependencies <unit>
systemctl list-dependencies <unit> --reverse
```

A masked systemctl service cannot be started manually or automatically.
- Mask a unit
```
systemctl mask <myunit> 
```
- Unmask a unit
```
systemctl unmask <myunit> 
```

References
- systemd
- systemd.unit
- systemd.service
- systemd.socket
- systemctl

