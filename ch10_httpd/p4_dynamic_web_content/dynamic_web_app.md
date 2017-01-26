## Integrating Dyanmic Web Content

### Overview
Most modern websites do not consist of purely static content. Most content served out is actually generated dynamically, on demand. Integrating dynamic content w/ httpd can be done in numerous ways. This section describe a few common ways, but more exist.

### Common Gateway Interface
One of the oldest forms of generating dynamic content is by using Common Gateway Interface (CGI). When a CGI resource is requested, httpd does not simply read the resoruce and serve it out; instead, it executes the resource as a process, and serves the stdout of that process. Although CGI resources are mostly written in scripting languages like Perl, it is also quite common for CGI resources to be compiled C programs or Java executables.

Info from the request (including client info) is made avail to the CGI program using env vars.

#### Configuring httpd for CGI
To have httpd treat a loc as CGI executables, the following syntax is used in the httpd config
```
ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
```
This instucts httpd to redirect any request for files under the /cgi-bin URL to the /var/www/cgi-bin dir and treat files in that directory as executable scripts.

A number of caveats exist when using CGI:
- CGI scripts will be executed as the apache user and group
- CGI scripts should be executable by the apache user and group
- CGI scripts should have the httpd_sys_script_exec_t SELinux context
- CGI dir should have Options None and access should be granted using a normal <Directory> block

### Serving dynamic PHP content
A popular method of providing dynamic content is using the PHP scripting lang. While PHP scripts can be served using old-fashioned CGI both perf and sec can be improved by having httpd run a PHP interpreter internally.

By instaling the php pkg a special mod_php module is added to httpd. The default config for this module adds the following lines to the main httpd config:
```
<FilesMatch \.php$>
  SetHandler application/x-httpd-php
<FilesMatch>
DirectoryIndex index.php
```
The <FilesMatch> block instructs httpd to use mod_php for any file w/ a name ending in .php and the DirectoryIndex directive adds index.php to the list of files that will be sought when a directory is requested. 

### Serving dynamic phython content
Also popular is generating dynamic content using python scripts. Python scripts can be served out using reg CGI, but both python and httpd also support a newer protocol: Web Server Gateway Interface (WSGI).

WSGI support can be added to httpd by installing the *mod_wsgi* pkg. Unlike the mod_php or CGI approach, WSGI does not start a new script/interpreter for every request. Instead, a main app is started and all requests are routed into that app.

Configuring httpd to support a WSGI app takes two steps:
1. Install the mod_wsgi pkg.
2. Add a WSGIScriptAlias line to a virtual host definition

The following is an ex of a WSGIScriptAlias directive, which sends all requests for http://servername/myapp and any resources below it to the WSGI application /srv/myapp/www/myapp.py:
```
WSGIScriptAlias /myapp/ /srv/myapp/www/myapp.py
```

WSGI applications should be executable by the apache user and group and their SELinux contexts should be set to *httpd_sys_content_t*.

### Database connectivity
Most web apps will need to store and retrieve persistent data. A common approach to this is to store the data in the db such as maria or postgresql.

When the database is running on the same host as the web server and the db is using a standard network port, SELinux will allow the net con from the web app to happen.

When a db on a remote host is used the SELinux Boolean *httpd_can_network_connect_db must be set to 1 to allow the con.

When a net con to another needs to be made from w/in the web app, and the tgt is not a well known db port, the SELinux boolean httpd_can_network_connect must be set to 1.

Various other selinux booleans can also affect the way in which web apps are executed by httpd.
