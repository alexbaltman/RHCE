## MariaDB Backups

### Creating Backups
It is very important to back up bus critical dbs. The db often contains most of the cos mission critical data i.e. sales, clients, etc. Performing backups enables a sys admin to recover data after several types of events:
- OS crash
- FS crash
- HW problems
- Sec breach
- DB corruption
- Data Poisoning

There are two logical ways to backup MariaDB:
- Logical
- Physical(raw)

Logical backups export info and records in plain txt files, while phys backups consist of copies of files and dirs that store content. 

Logical backups have these characteristics:
- The db struct is retrieved by querying the db
- Logical backups are highly portable, and can be restared to another db provider (like psotgres) in some cases
- Backup is slower b/c the server must access db info and convert it to a logical format
- Performed while server is onlin
- Backups do not include log or config files

Physical backups have these characteristics:
- consist of raw copies of the db dirs and folders
- output is more compact
- backups can includ log and config files
- Portable only to other machines w/ similar hw and software
- Faster than logical backups
- Should be performed while the server is offline or while all tables in the db are locked, preventing changes during the backup


### Performing Logical Backups
A logical backup can be done with the *mysqldump* cmd:
```
mysqldump -u root -p inventory >/backup/inventory.dump
```
inventory=selected db for backup and the shell redirection is final output file of db

Note: To logically backup all the dbs:
```
mysqldump -u root -p --all-databases >/backup/mariadb.dump
```
A dump of this kind will include the mysql db, which includes all user info.


The out put of a logical backup will appear to be a series of SQL statements. User passwords will be encrypted, but visible. Also, indiv tables are locked and unlocked by default as they are read during a logical backup.

Note: mysqldump requires at least the *select* priv for dumped tables. SHOW VIEW for dumped views, and TRIGGER for dumped triggers.

Useful options:
| Option | Description |
| --- | --- |
| --add-drop-table | Tels MariaDB to add a DROP TABLE statement before ea CREATE TABLE statement |
| --no-data | Dumps only the db structure not the contents |
| --lock-all-tables | No new record can be inserted anywhere in the db while copy is finished. This options is very important to ensure backup integrity |
| --add-drop-database | Tells MariaDB to add a DROP DATABASE statement before ea CREATE DATABSE statement |


### Performing physical backups
Several tools are avail to perf phys backups such as *ibbackup*, *cp*, *mysqlhotcopy*, and *lvm*.

A MariaDB physical backup task can use the known benefits of LVM snapshots. The following process will back up MariaDB using LVM.

Note: The key benefit of this methodology is that it is very quick and keeps the downtime of the db short. This is a great argument for putting the db files on a dedicated LVM parition.

Verify where mariaDB files are stored:
```
mysqladmin variables | grep datadir
```
Verify which logical volume hosts this location:
```
df /var/lib/mysql
```
This shows that the vol grp is vg0 adn the logical vol name is mariadb.
Verify how much space is avail for the snapshot:
```
vgdisplay vg0 | grep Free
```
This shows that 61.29GB are avail for a snapshot.
Connect to MariaDB, flush the tables to disk, and lock them (alternatively shut down the mariadb svc). This is so that new records are not inserted during snapshot, possibly corrupting the DB:
```
$ mysql -u root -p
Mariadb [(none)]> FLUSH TABLES WITH READ LOCK;
```
Note: Do NOT close this session. As soon as the client disconnects, this lock is lifted. The db must remain locked until the LVM snapshot is created

In another terminal session, create LVM snapshot:
```
lvcreate -L20G -s -n mariadb-backup /dev/vg0/mariadb
```
Note: The snapshot needs to be large enought to hold the backup.

In the orig MariaDB session, unlock the tables (or bring the mariadb svc up):
```
Mariadb [(none)]> UNLOCK TABLES;
```
The snapshot can now be mounted to an arbitrary location:
```
mkdir /mnt/snapshot
mount /dev/vg0/mariadb-backup /mnt/snapshot
```
From here any standard file sys backup can be used to store a copy of /var/lib/mysql as mounted under /mnt/snapshot.
Note: Do not forget to delete the snapshot once it has been backed up.
```
umount /mnt/snapshot
lvremove /dev/vg0/mariadb-backup
```

### Restoring a backup
#### Logical Restore
A logical restore can be done w/ the cmd mysql:
```
mysql -u root -p inventory </backup/mariadb.dump
```

#### Physical restore
Turn off mariadb
```
systemctl stop mariadb
```
Verify where mariaDB files are stored:
```
mysqladmin variables | grep datadir
```
Remove the actual content:
```
rm -rf /var/lib/mysql/*
```
From here, any standard file system restore can be used to restre a copy from backup to /var/lib/mysql.
