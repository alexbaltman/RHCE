## SELinux Port Labeling

### Overview
SELinux does more than just file and process labeling. Net traffic is also tightly enfored by the selinux policy. One of the methods that selinux uses for controlling net traf is labeling net ports; for example, in the targeted policy, port 22/tcp has the label ssh_port_t associated with it.

Whenever a process wants to listen on a port, selinux will check to see if the label associated with that process (the domain) is allowed to bind that port label. This can stop a rogue service from taking over ports otherwise used by other legitimate net svcs.

### Managing selinux port labeling
Whenever an admin decides to run a svc on a nonstandard port, then there is a high change that selinux port labels will need to be updated. In some cases, the targeted policy has already labeled the policyort with a type that can be used; for ex, since port 8080/tcp is often used for web aps that port is already labled w/ http_port_t, the default port type for the web server.

Use the port subcommand of the semanage cmd to list port labels:
```
semanage port -l
```
-l returns in the  form
```
port_label_t tcp|udp comma,separated,list,of,ports
```
Note: a port label can appear twice in the output, once for tcp and once for udp.
Note2: You may use graphical tool, system-config-selinux, using pkg policycoreutils-gui

Semanage can also be used to assign new port labels, remove port labels, or modify exissting ones. Other useful cmds: getenforce, ls -ldz.

- Add a port to an existing port label (type), use:
```
semanage port -a -t port_label -p tcp|udp PORTNUMBER
```
Ex - allow gopher svc to listen on 71/tcp:
```
semanage port -a -t gopher_port_t -p tcp 71
```
Note: targeted policy ships w/ a larget number of port types. Per svc doc on selinux types, booleans, and port types can be found in the service specific selinux man pages found int he selinux-policy-devel package, you can install by: yum -y install selinux-policy-devel; mandb; man -k _selinux

- To remove a port label (swap -a to -d):
```
semanage port -d -t gopher_port_t -p tcp 71
```

- Modify port bindings - mod port 71 from gopher_port_t to http_port_t:
```
semanage port -m -t http_port_t -p tcp 71
```

Additonal Docs:
+semanage
+semanage-port
+xxxxx_selinuxd
+system-config-selinux 
