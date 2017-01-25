## Configuring Vhost

### Virtual Host Overview
Virtual hosts allow a single httpd server to serve content for multiple domains. Based on either the IP address of the server that was connected to, the hostname requested by the client in the http request, or a combo of both, httpd can use diff config settings, including a diff DocumentRoot.

Virtual hsots are typically used when it is not cost effective to spin up multiple virtual machines to serve out many low-traffic sites; for ex, in a shared hosting env.

### Configuring Virtual hosts
Virtual hosts are configured using <BirtualHost> blocks inside the main config. To ease admin, these virtual host blocks are typically not defined inside /etc/httpd/conf/httpd.conf but rather in separate .conf files in /etc/httpd/conf.d.

Example /etc/httpd/conf.d/site1.conf:
```
1. <Directory /srv/site1/www>
     Require all granted
     AllowOverride None
   </Directory>

2. <VirtualHost 192.168.0.1:80>
     3. DocumentRoot /srv/site1/www
     4. ServerName site1.example.com
     5. ServerAdmin webmaster@site1.example.com
     6. ErrorLog "logs/site1_error_log"
     7. CustomLog "logs/site1_access_log" combined
   <VirtualHost>
```

#1. This block provides access to the DocumentRoot defined further down
#2. This is the main tag of the block. The 192.168.0.1:80 part indicates to httpd that this block should be considered for all cons coming in on that IP/port combo. If using a hostname then it should be in DNS/resolvable.
#3. Here the DocumentRoot is being set, but only for within this virtual host.
#4. This setting is used to configure name-based virtual hosting. If multiple <VirtualHost> blocks are declared for the same IP/port combo, the block that matches ServerName w/ the hostname: header sent in the client http request will be used. There can be exactly zero or one ServerName directives inside a single <VirtualHost> block. If a single virtual host needs to be used for more than one domain name, one or more ServerAlias statements can be used. 
#5. To help w/ sorting mail msgs regarding the diff websites, it is helpful to set unique ServerAdmin addrs for all vhosts.#5. To help w/ sorting mail msgs regarding the diff websites, it is helpful to set unique ServerAdmin addrs for all vhosts.#5. To help w/ sorting mail msgs regarding the diff websites, it is helpful to set unique ServerAdmin addrs for all vhosts.#5. To help w/ sorting mail msgs regarding the diff websites, it is helpful to set unique ServerAdmin addrs for all vhosts.#5. To help w/ sorting mail msgs regarding the diff websites, it is helpful to set unique ServerAdmin addrs for all vhosts.
#6. The loc for all error msgs related to this vhost.
#7. The loc for all access msgs regarding this vhost.

If a setting is not made explicitly for a vhost, the same setting from the main config will be used.

#### Name-based vs IP-based Virtual Hosting
By default, every vhost is ip based, sorting traffic to the vhosts based on what ip addr the client had connected to. If there are multiple vhosts declared for a single ip/port combo, the *ServerName* and *ServerAlias* directives will be consulted, effectively enabling name-based virt hosting.

#### Wildcards and Priority
The IP addr part of a <VirtualHost> directive can be replaced w/ one of two wildcards: _default_ and star. Both have exactly the same meaning: "Match Anything".

when a request comes in, httpd will first try to match against virtual hosts that have an explicit IP addr set. If those matches fail, virtual hosts w/ a wildcard IP addr are inspected. If there is still no match the "main" server config is use.

Note: A <VirtualHost *:80> will always match the regular http traf on port 80/TCP, *effectively disabling the main server config* from ever being used for traffic on port 80/TCP.

If no exact match has been found for a ServerName or ServerAlias directive, and ther are multiple virtual hosts defined for the IP/port combination the request came in on, the first virtual host tht matches an IP/port is used, w/ first being seen as the order in which virtual hosts are defined in the config file.

When using multiple *.conf files, they will be included in alphanumeric sorting order. To create a catch-all (default) virtual host, the config file should be named something like 00-default.conf to make sure that it is included before any others.

### Troubleshooting Virtual Hosts
When troubleshooting virtual hosts there are a number of approaches that can help:
- Config a separate DocumentRoot for ea virtual host w/ identifying content
- Config separate logfiles, both for error logging and access logging for ea vhost
- Eval the order in which the vhost defs are parsed by httpd, included files are read in alphanumeric sort order based on their filenames
- Disable vhosts one by one to isolate the prob. Vhost defs can be commented out of the config files, and include files can be temp renamed to something that does not end in .conf.
- journalctl UNIT=httpd.service can isolate log msgs from just the httpd.service service
