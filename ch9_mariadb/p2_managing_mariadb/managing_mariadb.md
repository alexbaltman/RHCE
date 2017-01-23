## Managing MariaDB

### Creating user accounts w/ MariaDB
By default, MariaDB handles authentication and authorization through the user table in the mysql db. This means that the root passwd for the db is persisted in the user table and not in the OS.

Note: Recent versions of MariaDB can use PAM for auth on nix.

The CREATE USER statement creates new accounts. This statement will create a new row in the mysql.user table that has no privs.

Note: information_schema and test db allows some privs for all users. This is the main reason why the test db is often deleted.
Note2: To create a new user the con user must have the global CREATE USER priv or the INSERT priv for the mysql db.

Acc names are specified as *'user_name'@'hostname'*. This makes it possible to create multiple user accounts w/ the same name, but w/ diff privs according to the src host (that is, the host from which the user is connecting).
```
MariaDB [(none)]> CREATE USER mobius@localhost IDENTIFIED BY 'redhat';
```
- username/hostname for this account
- redhat - password

This user acc can only con from localhost, w/ the pass redhat, and has no privs. Passwords are enc in the user table:
```
MariaDB [(none)]> SELECT host,user,password FROM user WHERE user = 'mobius';
```
When using this acc, before granting any privs, access will be denied for almost any action:
```
$ mysql -u mobius -p
enter password: redhat
MariaDB [(none)]> create database inventory;
ERROR 1044 (42000): Access denied for user...
```
Note: If the hostname is not provided, it is assumed to be "%". This means that this user can access from any src host.


Account Examples:
| Account | Description |
| --- | --- |
| mobius@'localhost' | User mobius can con just from localhost |
| mobius@'192.168.1.5' | User mobius can con from 192.168.1.5 host |
| mobius@'192.168.1.%' | user mobius can con from any host on net 192.168.1.0 |
| mobius@'%' | User mobius can can from any host |
| mobius@'2000:472:18:b5t:c32:a21' | User mobius can con from the ipv6 addr listed |


### Granting and reboking privs for user accs
Privs are the perms that the user may have w/in MariaDB. The privs are organized as:
- Global privs, such as CREATE, USER, and SHOW DATABASES, for admin of the db server itself
- DB privs, such as CREATE for creating dbs and working w/ dbs on the server at a high lvl
- Table privs, such as CRUD cmds, for creating and manipulating data in the db
- Column privs, for granting table-like cmd usage, but on a particular col (generally rare)
- Other, more granular privs which are discussed in detail in the MariaDB docs

The GRANT statement can be used to grant privs to accs. The con user must have the GRANT OPTION priv (a special priv tht exists at several levels) to grant privs. A user may only grant privs to others that have already been granted to that user (for ex, mobius cannot grant SELECT privs on a db table unless he already has that priv and the GRANT OPTION table priv).
```
$ mysql -u mobius -p 
Enter pasword: redhat
MariaDB [(none)]>  use inventory;
MariaDB [(inventory)]> select * from category;
ERROR SELECT cmd denied
MariaDB [(inventory)]> exit

$ mysql -u root -p
Enter pasword: redhat
MariaDB [(none)]> use inventory;
MariaDB [(inventory)]> GRANT SELECT, UPDATE, DELETE, INSERT on inventory.category to mobius@localhost;

$ mysql -u mobius -p 
Enter pasword: redhat
MariaDB [(none)]>  use inventory;
MariaDB [(inventory)]> select * from category;
SUCCESS
```

Grant is formed via define the privs to be granted (in this case CRUD capabilities are being granted). Define which table the privs will be granted for. The user/host to be granted privs.


Grant examples:
| Grant | Description |
| --- | --- |
| GRANT SELECT ON database.table TO username@hostname | Grant select priv for specific table in a specifif db to specific user |
| GRANT SELECT ON database.* TO username@hostname | Grant select priv for all tables in a specific db to a specific user |
| GRANT SELECT ON *.* TO username@hostname | Grant select priv for all tables in all dbs to specific user |
| GRANT CREATE, ALTER, DROP ON database.* to username@hostname | Grant priv to create, alter, and drop tables in a specific db to specific user |
| GRANT ALL PRIVS ON *.* TO username@hostname | Grant all avail privs for all dbs to a specific user |

The REVOKE statement allows for the revoking of privs from accs. The con user must have the GRANT OPTION priv and have th eprivs that are being revoked to revoke a priv.
```
REVOKE SELECT, UPDATE, DELETE, INSERT on inventory.category from mobius@localhost;
```
3 major parts of cmd:
- privs to be revoked
- define which table the priv/s will be revoked for
- user/hostname to revoke priv/s from

---
*IMPORTANT*
Note: After granting or revoke a priv, reload all privs from the privs table in mysql db:
```
MariaDB [(none)]> FLUSH PRIVILEGES;
```
---

In order to revoke privs, the list of privs granted to a user will be needed. The simple cmd SHOW GRANTS FOR username; will provide the list of privs for that user:
```
SHOW GRANTS FOR root@localhost
```

When a user is no longer required, it can be del from the db using DROP USER username;. The username should use the same 'user@host format CREATE USER did.
Note: If an acc that is currently connected is DROPped, it will not be deleted until con is closed. The con will *NOT* be automatically closed.

### Troubleshooting DB access
Some common DB access issues:
| Issue | Solution |
| --- | --- |
| User has been granted access to con from any host, but can only con on localhost using mysql cmd (apps he/she uses cannot con, even on localhost). | Remove the skip-networking directive from my.cnf and restart the svc |
| User can con w/ any app on localhost, but not remotely | Check the bind-address config in my.cnf to ensure the db is accessible. Ensure that the user table includes an entry for the user fromthe hsot he is trying to con from |
| User can con, but cannot see any db other than information_schema and test | Common prob when a user has just been created, as they have no privs by default, though they can con and use those default dbs. Add grant for the db the user requires | 
| User can con, but cannot create any dbs | Grant the user the global CREATE priv (this also grants DROP privs) |
| User can con, but cannot rw any data | Grant the user the CRUD privs for only the db he/she will use |
