## Configuring Apache

### Overview
Apache httpd is one of the most used web servers on the internet. A web server is a daemon that speaks the http(s) protocol, a text based protocol for sending and receiving objects over a net con. The http protocol is sent over the wire in clear text, using port 80/TCP by default (though other ports can be used). There is also a TLS/SSL encrypted version of the protocol called https that uses port 443/TCP by default.

A basic http exchange has the client connecting to the server and then requesting a resource using the GET cmd. Other cmds, like head and post exist, allowing clients to request just metadata for a resource or send the server more information.

The client starts by requesting a resource (the GER cmd) and then follows up w/ some extra headers telling the server what types of encoding it can accept, what lang it would prefer etc. The request is ended w/ an empty line.

The server then replies w/ a status code (HTTP/1.1 200 OK) followed by a list of headers. The Content-Type header is a mandatory one, telling the client what type of content is being sent. After the headers are done, the server sends an empty line, ollowd by the requested content. The length of this content must match the length indicated in the Content-Length header.

While the http protocol seems easy at first, implementing all the protocol along w/ security measures, support for clients not adhering fully to the standard and support for dynamically generated pages is not an easy task. That is why most application developers do not write their own web servers, but instead write their applications to be run behind a web server like Apache HTTPD.

#### About Apache HTTPD
Apache HTTPD sometimes just called Apache or httpd implements a fully configurable and extendable web server w/ full http support. The functionality of httpd can be extended w/ modules, sm pieces of code that plug into the main web server framework and extend its functionality.

On RHEL Apache HTTPD is provided in the httpd pkg. The web-server pkg grp will install not only the httpd pkg itself, but also the *httpd-manual* pkg.Once httpd-manual is isntalled and the httpd.service vc is started, the full apache httpd manual is avail on http://localhost/manual. This manual has a complete reference of all the config directives for httpd, along w/ examples. This makes it invaluable resource while configuring httpd.

RHEL also ships an env grp called web-server-environment. This env grp pulls in the web-server grp by default, but has a number of other grps, like backup tool and db clients marked as optional.

A default dep of the httpd pkg is the httpd-tools pkg. This pkg includes tools to manipulate passwd maps and dbs, tools to resolve IP addresses in logfiles to hostnames, and a tool (ab) benchmark and stress test web servers.

### Basic httpd config
After installing the web server pkg grp, or the httpd pkg, a default config is written to /etc/httpd/conf/httpd.conf.

This config serves out the contents of /var/www/html for requests coming in to any hostname over plain http.

The basic syntax of the httpd.conf is comprised of two parts: key value config directives and html like <blockname parameter> blocks w/ other config directives embedded in them. key/value pairs outside of a block affect the entire server config while directives inside a block typically only apply to a part of the config indicated by the block or when the req set by the block is met.

```
1. ServerRoot "/etc/httpd"
2. Listen 80
3. Include conf.modules.d/*.conf
4. User apache
5. Group apache
6. ServerAdmin root@localhost
7. <Directory />
  AllowOverride none
  Require all denied
</Directory
8. DocumentRoot "/var/www/html"
 <Directory "/var/www">
  AllowOverride none
  Require all granted
 </Directory>
<Directory "/var/www/html">
  Options Indexes FollowSymLinks
  AllowOverride None
  Require all granted
</Directory> 
9. <IfModule dir_module>
  DirectoryIndex index.html
</IfModule>
10. <Files ".ht">
  require all denied
</Files>
11. ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
  LogFormat "%h %1 %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
  LogFormat "%h %1 %u %t \"%r\" %>s %b" common
  <IfModule logio_module> 
    LogFormat "%h %1 %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
  </IfModule>
12. CustomLog "logs/access_log" combined
</IfModule>

13. AddDefaultCharset UTF-8
14. IncludeOptional conf.d/*.conf
```

#1. This directive specifies where httpd will look for any files referenced in the config files w/ a relative path name.
#2. This directive tells htpd to start listening on port 80/TCP on all interfaces. To only listen on select ints, the syntax "Listen 1.2.3.4.:80" can be used for ipv4 or "Listen [2001:db8::1]:80" for IPv6.
#3. This directive includes other files, as if they were inserted into the config file in place of the Inlcude statement. When multiple files are specified, they will be sorted by filename in alphanumeric order before being included. Filenames can either be absolute or relative to ServerRoot and include widcards such as star. Note: Non-existant files result in fatal htpd error.
#4/5. These two directive specify the user and group the httpd daemon should run as. httpd is always started as root, but once all actions that need root privs are done, for ex binding to a port under 1024, the privs will be dropped and exec continued as a nonpriv user as a sec measure.
#6. Some err pgs generated by httpd can include a link where users can report a problem setting this directive to a valid email addr will make the webmaster easier to contact for users, leaving it blank will default to root@localhost is not recommended.
#7. A <Directory> block sets config directives for a specified directory and all descendent dirs. Common directives inside this type of block include:
- AllowOverride None: .htaccess files will not be consulted for per-directory config settings. Setting this to any other setting will have a performance penalty, as well as sec ramifications. 
- Require All Denied: httpd will refuse to server content out of this dir, returning a HTTP/1.1 403 Forbidden error when requested by a client. 
- Require All Granted: Allow access to this dir. Setting this on a dir outside of the normal content tree can have sec implications.
- Options +/-: Turn on or off certain options for a dir. For example, the Indexes option will show a dir listing if a dir is requested and no index.html file exists in that dir.
#8. This setting determines where httpd will search for requested fles. It is important that the dir specified here is both readable by httpd (both regular perms and SELinux), and that a corresponding <Directory> block has been declared to allow access.
#9. This block only applies its contents if the specifed extension module is loaded. In this case, the dir_module is loaded, so the DirectoryIndex directive can be used to specify what file should be used when a dir is requested. 
#10. A <Files> block works just as a <Directory> block, but here options for indiv wildcarded files is used. In this case the block prevents httpd from serving out any sec-sensitive files like .htaccess and .htpasswd.
#11. This specifies to what file httpd should log any errors it encounters. Since this is a relative pathname, it will be prepended w/ the ServerRoot directive. In a default config, /etc/httpd/logs is a sym link to /var/log/httpd.
#12. The CustomLog directive takes two parameters: a file to log to, and a log format defined with the LogFormat directive. Using these directives, admins can log exactly the info they need or want. Most log parsing tools will assume that the default combined format is used.
#13. This setting adds a charset part to the Content-Type header for text/plain and text/html resources. This can be disabled with AddDefaultCharset Off.
#14. This works the same as a regular include, but if no files are found, err is generated.

### Starting httpd
Can start httpd like so:
```
systemctl start httpd
systemctl enable httpd
```

Once httpd is started, status info can be requested w/ systemctl status -l httpd. If httpd has failed to start for any reason thsi output will typically give clear indication of why.

Network Security can be modifed like this, depending on SSL/TLS is enabled or not:
```
firewall-cmd --permanent --add-service=http --add-service=https
firewall-cmd --reload
```

In a default config, SELinux only allows httpd to bind to a specific set of ports. This full list can be requested w/ the cmd *semanage port -l | grep '^http_'*. For a full overview of the allowed port contexts and their intended usage, consult the httpd_selinux man page from the selinux-policy-devel pkg.

#### Using an alt document root
Content does not need to be served out of /var/www/htm, but when changing the DocumentRoot setting, a number of other changes must be made as well:
- File system perms: any new DocumentRoot must be readable by the apache user or the pache group. In most cases, the DocumentRoot should never be writable by the apache user/grp.
- SELinux: default SELinux policy is restrictive as to what contexts can be read by httpd. The default context for web server content is *httpd_sys_content_t*. Rules are already in plce to relabel /srv/*/www with this context as well. To serve content from outside of these standard locs, a new context rule must be added w/ semanage:
```
semanage fcontext -a -t httpd_sys_content_t '/new/location(/.*)?' 
```
Consult the httpd_selinux man page from the selinux-policy-devel pkg for additional allowed file contexts and their intended usage.

#### Allowing write access to DocumentRoot
In a default config only root has w access to the standard DocumentRoot. To allow web devs to write into DocumentRoot, a number of approaches can be taken.

- Set a default ACL for the web developers on the DocumentRoot. For example, if all web developers are part of the webmasters grp, and /var/www/html is used as DocumentRoot, the following cmds will give them write access:
```
setfacl -R -m g:webmasters:rwX /var/www/html
setfacl -R -m d:g:webmasters:rwx /var/www/html
```
Note: The uppercase X bit sets the executable bit only on dirs instead of dirs and reg files. This is esp relevant when done in conjunction w/ a recursive action on a dir tree.

- Create a new DocumentRoot owned by the webmasters grp, the SGID bit set:
```
mkdir -p -m2775 /new/docroot
chgrp webmasters /new/docroot

- A combination of the prev, w/ other perms closed off and an ACL added for the apache grp.
