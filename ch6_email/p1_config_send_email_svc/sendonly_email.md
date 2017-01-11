## Config Send Only Email Svc

### Overview
Admins may want to send email from a linux server, for automatic purposes e.g. reports. Sendmail is commonly used for this provided by Postfix, which must be configured to do so. We will take a look at setting up a server to transmit email through an unathenticated SMTP gw.

A null client is a client machine that runs a local mail server which forwards all emails to an outbound mail relay for delivery. A null client does not accept local delivery for any msgs, it can only send them to the outbound mail relay. Users may run mail clients on the null client to read and send emails.

We will setup a postfix null client, using sendmail and SMTP to transmit mail msgs to the outside world through existing outgoing mail server.

### Transmission of an Email Msg
To send an email, in most cases, the mail client communicates w/ an outgoing mail server, which will help relay that msg to its final dest. The mail client transmits msgs to the mail server using the Simple Mail Transfer Protocol (SMTP).

The outgoing mail relay may requie no auth from internal clients, in which ase the server listens on port 25/TCP. In that case, the relay will restrict which hosts can relay through ip address based restrictions or fw rules.

Note: In cases where the outbound SMTP relay is reachable from the internet, it is normally configured as a mail submission agent (MSA) for sec and anti-spam reasons. An MSA listens on port 587/tcp adn reqs auth of the users mail client before accepting mail. Can be user/pass or other.

The outgoing mail relay then uses dns to look up MX record identifying the mail server that accepts delvivery for msgs sent to recipients domain. The relay then uses SMTP on port 25/tcp to transmit the email to that server. 

The recipients mail svc may provide a POP3 or IMAP server such as Dovecot or Cyrus to allow a dedicated mail client to download their messages. Frequently, the mail service provides web based int.

Email client will/can fetch email from imap server and send via smtp server.

### POSTFIX
Powerful adn easy to config mail server. It is the default on rhel systems. Postfix is provided by the postfix rpm. It is composed of several components composed of the master process.

Main config file is /etc/postfix/main.cf

Note: there are other config files present in /etc/postfix. One other important file is master.cf, which controls what subservices are started.

| Postfix Setting | Purpose |
| --- | --- |
inet_interfaces | controls net int postfix listens for inc and out msgs. If set to loopback-only postfix listens only on 127 and ::1 addrs. If set to all postfix listens on all net ints. One or more hostnames/ipaddrs separate by white space can be listed |
| myorigin | rewrite locally posted email to appear to come from this domain. This helps ensure responses ret to the correct domain mail server responsible |
| relayhost | fwd all msgs to MS specified that are supposed to be sent to foreign mail addrs. Square brackets around the host name suppress the MX record lookup |
| mydestination | config which domains the MS is an end point for. Email addressed to these domains are deliver into local mailboxes |
| local_transport | Determine how email addressed to $mydestination should be delivered. by default set to local:$myhostname, which uses local mail delivery agent to deliver inc mail to the local message store in /var/spool/mail | 
| mynetworks | allow relay thorugh this mail server from a comma separated list of IP addrs and nets in CIDR notation to anywhere w/o further auth |

AKA
relayhost --> which server is smtp server?
mydestination --> inbound server (deliver)
local_transport --> mailbox
mynetworks --> set outbound for certain nets for this server

Can edit /etc/postfix/main.cf w/ vim or postconf utility.

- Query all main.cf settings
```
postconf
```
- Query particular set of options, listing them separated by sep whitespace.
```
postconf inet_interfaces myorigin
```
Note: when value start with dollar sign, it points to value of diff setting.
- Run following to add new or change existing options in main.cf
```
postconf -e 'setting = value'
```
If new, then added to end of config file

Note: postfix svc requires a reload/restart after the changes have been made to main.cf.

Note2: When troubleshooting email, a log of al lmail related ops is kept in the sysemd journal and /var/log/maillog. The postqueue -p cmd displays a list of any outgoing mail msgs that have been queued. To attempt to deliver all queued msgs again immediately run postqueue -f cmd; otherwise postfix will attempt to resend them about once an hr until accepted or expire.

### Postfix null client config
Remember to act as null client, postfix and rhel need to be cnfigured so that the following are True:
- sendmail cmd and programs that use it fwd all emails to an existing outbound mail relay for delivery
- local Postfix svc does not accept local delivery for any email msgs
- usrs may run mail clients on the null client to read and send emails.

Note: A complete overview of all settings that are adjustable in the main.cf can be found in the postconf man pg. To display use man 5 postconf to get to the config not the regular postconf cmd.

### Config Postfix as null client
1. Adjust the relay directive to point to the corp mail server. The hostname of the corp mail server needs to be enclosed in square brackets to prevent an MX record lookup w/ the dns server.
```
postconf -e "relayhost=[smtpX.example.com]
```
2. Config the postfix mail server to only relay emails from the local system. a) let the postfix mail server listen only on the loopback int for emails to deliver and b) change the config of the null client so that mails orig from 127.0.0.0/0 ipv4 net and the [::1]/128 ipv6 net are forwarded to the relay host by the local null client.
```
a) postconf -e "inet_interfaces=loopback-only"
b) postconf -e "mynetworks=127.0.0.1/8 [::1]/128"
```
3. Config postfix so all outgoing mails have their sender domain rewriten to the co domain desktopX.example.com
```
postconf -e "myorigin=desktopX.example.com"
```
4. Postfixrohibit the postfix mail server from deliver any msgs to local accs. a) config the null client to not act as an end point for any mail domain. Mails where the recipient is a local email acc are not accpeted for local delivery. The *mydestination* option needs to be set to an empty value to achieve this. b) config the local null client to not sort any mails into mailboxes on the local syus. Local email delivery is turned off.
```
a) postconf -e "mydestination="
b) postconf -e "local_transport=error: local delivery disabled"
```
5. Restart the local postfix null client.
```
systemctl restart postfix
```

Again, here are the null client postfix settings:
| Directive | Null Client |
| --- | --- |
| inet_interfaces | inet_interfaces = loopback-only |
| myorigin | myorigin = desktopX.example.com |
| relayhost | relayhost = [smtpX.example.com] |
| mydestination | mydestination = |
| local_transport | local_transport = error: local delivery disabled |
| mynetworks | mynetworks = 127.0.0.0/8 [::1]/128 |

### Additional Reading
+ postconf
+ postconf 5 
+ mail
+ mutt

Note: To use postconfig 5, type cmd: man 5 postconf
