## Installing MariaDB

### Overview
A relational db is a mechanism that allows the persistence of data in an organized way. DBs store data items organized as a set of tables, w/ ea table representing an entity. In a given table, ea row corresponds to a record, while ea column corresponds to an attr of that record.

```
MariaDB [inventory]> SELECT * FROM product; 
```
```
MariaDB [inventory]> SELECT * FROM category; 
```
```
MariaDB [inventory]> SELECT * FROM manufacturer; 
```
The prev tables show:
- the product table has four records. ea record has six attrs: (id, name, price, stock, id_category, id_manufacturer
- x110 64GB is an SSD manufactured by SanDisk
- The seller responsible for the ThinkServer TS140 prod is Allen Scott.

There are two relational DB pkgs provided in RHEL:
- PostgreSQL - An open src db developed by the PostgreSQL Global Development Group, consisting of Postgres users (both individuals and companies) and other companies and volunteers, supervised by co.s such as RedHat and EnterpriseDB
- MariaDB - A community developed branch of MySQL built by some fo the original authors of MySQL. It offers a rich set of feat enhancements, including alternate storage engines, server optimizations and patches. The MariaDB Foundation works closely and cooperatively w/ the larger community of users and developers in the spirit of free and open src software.

### MariaDB Installation
A full MariaDB db installation requires both the *mariadb* and *mariadb-client* groups of software to be installed. 

The following pkgs will be installed w/ the mariadb grp:
- mariadb-server - The MariaDB server and related files (mandatory pkgs)
- mariadb-bench - MariaDB benchmark scripts and data (optional pkgs)
- mariadb-test - The test suite distributed w/ MariaDB (optional pkgs)

The following pkgs will be installed w/ the mariadb-client grp:
- mariadb - a community developed branch of MySQL (mandatork pkgs)
- MySQL-python - A MariaDB interface for Python (default pkg)
- mysql-connector-odbc - ODBC driver for MariaDB (default pkg)
- libdbi-dbd-mysql - MariaDB plugin for libdbi (optional pkg)
- mysql-connector-java - Native java drive fro MariaDB (optional pkg)
- perl-DBD-MySQL - A MariaDB interface for Perl (optional pkg)

The /etc/my.cnf file has default configs for MariaDB, such as the data dir, socket bindings and log and error file locs.
Note: Instead of adding new configs to the /etc/my.cnf file, a newly created file named *.cnf can be added to the /etc/my.cnf.d/ dir holdign the config of MariaDB.

### MariaDB installation demo
1. Install MariaDB on serverX w/ yum:
```
yum groupinstall -y mariadb mariadb-client
```
2. Start the MariaDB svc on serverX w/ systemctl:
```
systemctl start mariadb
systemctl enable mariadb
```
Note: The default MariaDB log file is /var/log/mariadb/mariadb.log. This file should be the first place to look when troubleshooting.
3. Verify the status of svc
```
systemctl status mariadb
```
- Loaded - shows if svc is loaded and enabled
- Active - shows if svc is activated
- Main PID - shows the main PID from this svc
- CGroup shows all processes that belong to this svc

Note: If the DB is stopped, the status option will report the last known PID and that the svc is inactive

### Improve MariaDB installation security
MariaDB provides a program to improve security from the baseline install state. Run *mysql_secure_installtion* w/o args
```
mysql_secure_installation
```

This program enables improvement of MariaDB sec in the following ways:
- Set a passwd for root accounts
- Removes root accounts that are accessible from outside localhost
- Removes anonymous-user accounts
- Removes the test database

The script is full interactive, and will prompt for ea step in the process

### MariaDB and networking
MariaDB can be configured to be accessed remotely or limited to just local cons.

In the first scenario, the db can only be accessed locally. Security is greatly improved b/c the records will only be accessed from applications that are on the same server. The disadvantage is that the server will share the same resources w/ other svcs, and this may impact perf in the db server.

In the second scenario, the DB can be accessed remotely. In this case, safety decs bc another port is opened on the server; which, may result in an attack. On the other hand, the perf of the server icnreases by not having to share resources. 

When MariaDb is access remotely by default, the server listenes for TCP/IP cons on all avail ints. on port 3306.

Note: Although the MariaDB svc listens on all itns by default, no users have remote access perm also by default.

#### Configuring MariaDB Networking
MariaDB net config directives are found in the /etc/my.cnf file under the [mysqld] section.

*bind-address*
Choose one:
- Hostname
- IPv4 addr
- IPv6 addr
- :: or 0.0.0.0 for all ipv4/ipv6 addrs

*skip-networking* - if set to 1, the sefver will listen only for local clients. All interaction w/ the server will be through a socket, located by default at */var/lib/mysql/mysql.sock*. This loc can be changed w/ a *socket* value in /etc/my.cnf.

Note: Be aware that if networkign is shutoff in this manner, this disables cons via localhost as well. The MySQL client can still make local cons through the socket file automatically.

*port* - port to listen on for TCP/IP cons

Note: For remote acces the fw needs to be modified like so:
```
firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload
```

### References
- mysql_secure_installation
- mysql.server
- mysqld_selinux

