## SQL and MariaDB Basics

### Creating a DB
The installation of the mariadb-client grp provides cmd *myql*. You can then connect to local or remote DBs.
```
mysql -u root -h localhost -p
```
mysql - Client to con to MariaDB
u - option to specify the username for this con
root - username for this con
h - Option to specify the hostname for this con. If not, defaults to localhost
localhost - hostname for this con
p - option to prompt for password (alt. --password=xyz)

```
MariaDB [(none)]> SHOW DATABASES;
```
Note: The only default db that can be erased is test
Note2: Unlike the shell, MariaDB like most relational db sys, is not case-sensitive for simple cmds i.e show; however, table and db names are case-sensitive. Many dbs are set up using all lowercase for the db names, so common practice is to use uppercase for the cmds to differentiate the cmd itself from the tgt of the cmd (more examples follow). The important part of these cmds and of most cmds entered at the prompt, is to terminate the cmd w/ a simicolon. 

To create a new DB, run the cmd:
```
CREATE DATABASE inventory;
```
After the creation fo the new db, the next step is to connect to this db so that it can be populated w/ tables and data.
```
USE inventory;
```
MariaDB (like all relational DB sys) can have multiple tables per db.
```
MariaDB [(none)]> USE mysql;
MariaDB [(none)]> SHOW TABLES;
```
To list attrs or the column names from a table use:
```
MariaDB [(none)]> DESCRIBE servers;
```

This output completly describes the data in the servers table in the mysql db. The port attr is stored as an int, using a max of 4 digits and defaults to 0. 

The key value is null for most of these attrs. Only the server_name has a value: PRI. This sets the attr as the primary key for the table. This sets the attr as the primary key for the table. Primary keys are unique ids for the data in the table. No two entries can have the same primary key, and only one attr may be set as the primary key. Primary keys are often used to link tables together, and are an important concept when designing complex dbs. There are also seconday keys and composite keys (where multiple attrs together form the unique key). A deeper discussion of keys is beyond the scope of this course. 

The extra value is uesd to show any additional features of the attr. This value can be complex, but a common one is auto_increment, which states that the value of this column will be incremented by 1 for ea new entry made into the table. It is a common value for the primary key to have, as seen in later examples.

### Using SQL: Structured Query Language
SQL is a special programming lang designed for managing data held in relational dbs. Some common 
QL cmds include: insert, update, delete, and select.

Note: These four basic cmds are often referred to by the generic term "CRUD operations." CRUD stands for create (insert), read (select), update (update), and delete (delete).

To insert data into a table, the first step is to figure out the attrs of the table.
```
DESCRIBE product;
```
In this case all attrs are required and may look like:
```
INSERT INTO product (name,price,stock,id_category,id_manufacturer) VALUES ('SDSSDP-1286-625',82.04,30,3,1);
```
product - table name
name,price... - attributes (cols) that will be inserted
VALUES - values to be inserted by order related to attrs above.

Note: The attr ID was not specified, even though it was required. When inserting a new record, MariaDB will auto assign a sequential value for that col. This is b/c this col is marked as auto_increment.
```
Delete a record w/ the delete statement:
```
DELETE FROM product where id = 1;
```
product - table name
where - clause that imposes a condition on the cmd execution
id equal to 1 - Condition for the record to be deleted; oftent the primary key-value pair is used

Note: If the where clause is not specified all records in the table will be erased. This is the db equiv of running rm -rf

To update a record use an update statement:
```
UPDATE product SET price=89.90, stock=60 WHERE id = 5;
```
product - table name
attr/value combinations
where - clause that imposes a condition on cmd execution
id equal 5 - condition for the record to be updated

Note: If the where clause is not specified all records will be updated.

To read data records from the db, use the select statement:
```
SELECT name,price,stock FROM product;
```
name,pr... - attrs to be selected
product - table name

To select all attrs:
```
SELECT * FROM product;
```
Filter results with where clause:
```
SELECT * FROM product WHERE price > 100;
```

Common Operators for the where clause
| operator | description |
| --- | --- |
| = | Equal |
| <> | Not equal, in some versions that is written as != |
| > | Greater Than |
| < | Less Than |
| >= | Greater than or eqaul to |
| <= | Less than or equal to |
| BETWEEN | Between an inclusive range |
| LIKE | Search for a pattern |
| IN | To specify multiple possible values for a col |

### Practice
Match the following to their couterparts
a. DELETE FROM table_name WHERE attr = value;
b. DESCRIBE table_name;
c. SELECT * FROM table_name;
d. SHOW DATABASES;
e. SHOW TABLES;
f. UPDATE table_name SET attr=value WHERE attr > value;
g. USE database_name;


1. Describe a table
2. Update a record in the table
3. Connect to a specific db
4. List dbs avail in MariaDB
5. List tables avail in a db
6. Select data records from table
7. Delete records from table

---
Answers: a7,b1,c6,d4,e5,f2,g3
