## Rich Rules

### Overview
Apart from regular zones and svc syntax that firewalld offers there is; rich rules and direct rules.

### Direct Rules
These all you to insert hand-coded ip,ip6,eb tables rules into the zones managed by firewalld. While powerful and exposing feats fo the kern netfilter subsystem, these rules can be hard to manage. Direct rules also offer less flex than standard rules and rich rules. Config direct rules is NOT COVERED in this course. You can view docs at firewalld.direct and firewall-cmd man pages. Direct rules are parsed before firewalld rules.

Two Examples:
```
firewall-cmd --direct --permanent --add-rule ipv4 raw PREROUTING 0 -s 192.168.0.0/24 -j blacklist
firewall-cmd --direct --permanent --add-rule ipv4 raw blacklist 0 -m limit --limit 1/min -j LOG --log-prefix "blacklisted "
```

### Rich Rules
An expressive lang to customize firewall rules that are not covered by the basic firewalld syntax. Rich rules can be used to express basic allow/deny rules, but can also config logging to syslog/auditd, port forward, masquerade, and rate limit. 

Basic rich rule syntax:
```
rule
  [source]
  [destination]
  service|port|protocol|icmp-block|masquerade|forward-port
  [log]
  [audit]
  [accept|reject|drop]
```
And then each can typically take option=value settings.

Full syntax at firewalld.richlanguage

#### Rule ordering
Once multiple rules have been aded to a azone or fw in general, the order of rules can have a big impact on final behavior. Basic ordering is same for all zones:
1. Any port fwd and masquerade rules set for that zone
2. Any logging rules set for zone
3. Any deny rules set for zone
4. Any allow rules set for zone

In all cases first match wins. If a packet has not been matched by any rule in a zone, it will typically be denied, but zones might have a diff default; for ex, the trusted zone will accept any unmatched packet. Also, after matching a logging rule a packet will cont to be processed as normal.

Direct rules are an exception. Most direct rules will be parse before any other processing is done, but their syntax allows an admin to insert any rule anywhere in any zone.

#### Testing and debugging
To make testing and debugging easier, almost all rules can be added to the runtime config w/ a timeout. The moment the rule w/ a timeout is added to the fw, when ticks down to zero, that rule is removed from the runtime config.

### Working w/ Rich Rules
| Option | Explanation |
| --- | --- |
| --add-rich-rule='myrule' | Add rule in single quotes to a zone or default zone |
| --remove-rich-rule='myrule' | Remove quoted rule from zone or default |
| --query-rich-rule='myrule' | Query if rule has been added to zone or default. Rets 0/1 |
| --list-rich-rules | Outputs all rich rules for the zone or default |


#### Rich Rule Examples
- Rejects all traffic from ip 192.168.0.11 in the classroom zone
```
firewall-cmd --permanent --zone=classroom --add-rich-rule='rule family=ipv4 source address=192.168.0.11/32 reject'
```
Note: When using src or dest w/ an addr option, the family= option of rule must be set to either ipv4 or 6

- Allow two new connections to ftp per min in default zone
```
firewall-cmd --add-rich-rules='rule serice name=ftp limit value=2/m accept'
```
Note: this change is only being made at runtime b/c it lacks --permanent option

- Drop all inc IPsec esp protocol packets from anywhere in default zone
```
firewall-cmd --permanent --add-rich-rule='rule protocol value=esp drop'
```
Note: the diff w/ reject and drop lies in the fact that reject will send back an ICMP packet detailing that and why. A drop just drops the packet and does nothing else. Normally reject is for friendly and drop for hostile nets.

- Accept all TCP packets on ports 7900 up to and including 7905 in the vnc zone for 192.168.1.0/24 subnet
```
firewall-cmd --permanent --zone=vnc --add-rich-rule='rule family=ipv4 source address=192.168.1.0/24 port port=7900-7905 protocol=tcp accept'
```

### Logging w/ rich rules
When debugging or mintoring a fw it can be useful to have a log of accepted or rejected cons. firwalld can ccomplish this in two ways; by logging to syslog, or by sending msgs to the kernel audit subsystem, managed by auitd.

In both cases logging can be rate limited. Rate limiting ensures that system log files do not fill up with messages at a rate such that the system cannot keep up or fills all its disk space.

Basic syslog syntax using rich rules:
```
log [prefix="myprefix"] [level=myloglevel] [limit value="therate/theduration"]
```
log levels are: emerg, alert, crit, error, warning, notice, info, or debug 
Duration: s for secs, m for mins, h for hours, or d for days --> ex: 3/m - 3 per min

Basic auditd syntax using rich rules:
```
audit [limit value="therate/theduration"]
```

#### Logging Examples
- Accept new cons to ssh from work zone, log new cons to syslog at the notice lvl, w/ a max of 3 msgs per min
```
firewall-cmd --permanent --zone=work --add-ruch-rule='rule service name="ssh" log prefix="ssh " level="notice" limit value="3/m" accept'
```
- New IPv6 cons from the subnet 2001:db8::/64 in the default zone to DNS are rejected for the next 5 mins and rejected cons are logged to the audit system w/ a max of 1 msg per hr.
```
firewall-cmd --add-rich-rule='rule family=ipv6 source address="2001:db8::/64" service name="dns" audit limit value="1/h" reject' --timeout=300
