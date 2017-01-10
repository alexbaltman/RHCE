## Troubleshooting DNS

### Overview
Due to the client server arch of DNS, properly working DNS name resolution on a system is almost always dependent on proper config and op of dns and on resolving nameservers as the recursion propagates. There are often numerous behind the scenes interations b/w auth NSs, ea of which is a possible point for failure.

Cachign NS reduces DNS workloads and improves perf; however, the cache f(x) adds another layer of failure potential where data could be present, but no longer accurate of the auth NS. 

Domain Internet Groper (dig) is a good tool to investigate DNS issues. 

#### Name resolution methods
B/c DNS svc is oftent he most widely used method it often bears blame whenever unexpected name resolution results occur. Sometimes this is not the case when the server or svc is using /etc/hosts, or WINS (Windows Internet Name Service).

On linux the order of name resolution is provided by the /etc/nsswitch.conf. The getent cmd from glibc-common pkg as well as the gethostip cmd from syslinux package can both be used to perf name resolution, mirroring the process used by most apps as dictated by nsswitch.conf.
```
getent hosts example.com
```
```
gethostip example.com
```

If getent or gethostip differs from dig then it is an indication that something besides DNS is responsible. Consult nsswitch.conf. 

#### Client-server net connectivity
For DNS to work a system must be able to conduct client-server interactions, which means firewalls need to be open and network connectivy needs to exist from client to server and up the auth chain. Also, config on client(resolv.conf - wrong dns server or search domain) server(unbound.conf - forward-zone(?)) could be wrong.

Port 53 via UDP needs to be open on the firewall or TCP for responses exceed 512 bytesor, 4096 if extension mechanism for DNS is supported - otherwise, you will get truncation error.

To test tcp:
```
dig +tcp A example.com
```

For reg/standard network issues you can use tcpdump, nmap, netcat(nc), or telnet.

### DNS response codes
dig
| Code | Meaning |
| --- | --- |
| SERVFAIL | NS encountered a prob while processing query |
| NXDOMAIN | The queried name does not exist in the zone |
| REFUSED | The NS refused the clients DNS request due to policy |

#### SERVFAIL
Common cause is the failure of the dns server to communicate w/ the SN auth for the name being queried. Could be due to authoritative NS being unavailable. It could be a network or fw problem.

To determine why try to see results of iter query:
```
dig +trace
```

#### NXDOMAIN
Indicates that no records were found assoc w/ the name queried. If not expected, the query is directed at server that is non auth for the name, then the servers cache may contain a neg cache for the name. The user can then eithr wait for the server to expire it or submit request to flush the name. Once removed, the server will query the auth NS to receive current resource records for the name.

The other scenario is when querying a CNAME containing an orphaned CNAME b/c it is no longer resolvable w/o a canonical name.

#### REFUSED
dns server has policy restriction, which keeps it from fulfilling the clients query. Some common causes of an unexpected refused return code are clients configured to query the wrong dns servers or dns server misconfig causing valid client request to be refused.

### Other common DNS issues
#### Outdated cache
A dns ret code of NOERROR signifies that no errors were encountered in resolving a query. it does not guarantee that there are no DNS issues present. There are situations where the DNS records in the DNS response may not match the expected result. The most common cause for an incorrect answer is that the answer originated from cached data, whic is no longer current. 

In these situations, first confirm that the rsposne is indeed nonauthoritative cached data. This can be easily determined by looking at the flags section of dig output. If it is auth it will indicate it by the aa flag. If non-auth you can see the counting down of the TTL by repeating the dig cmd.

#### Nonexistant records
If a record has been removed from a zone and a response is still received when querying for the record, first confirm the queries are not being answered from cached data. If the answer is aa then a possible cause is the presence of a wildcard record in the zoen.
```
*.example.com IN A 172.25.254.254
```
Wildcard record is a catchall for all queries of a given type for a nonexistent name as a backup option to the name.

#### non-fqdn errors
non-fqdn queries are auto expanded to fqdns by appending the name of the zone. To indicate that a name is an fqdn in a zone file. It must be ended with a "." i.e. www.example.com. A failure to do so can lead to diff issues depending on the type of record that the mistake is made in. Such a mistake in type-specific data portion of NS records have the potential of incapacitating an entire zone, while a mistake made in MX records could cause a complete halt of email deliver for a domain.

#### Looping CNAME records
CNAME records that point to CNAME records should be avoided to reduce DNS lookup inefficiency. It creates the possibility of creating unresolvable CNAME loops - returned as NOERROR.

#### Missing PTR records
Absence of a record causes various problems depending ont he svc. SSHD by default will perform reverse lookups of connecting client IP.s - the absence of a PTR records will lead to delays in the establishment of these cons.

Many MTAs incorporate reverse DNS lookups of connecting client IPs as a defence against malicious email clients. Many are in fact config.ed to reject client cons for IPs which cannot be resolved with a PTR query to DNS. 

#### Roundrobin DNS
A name can have multiple A/AAAA records in DNS. This is known as roundrobin DNS and is often used as a simple low cost LB across multiple hosts. When a DNS client queries fora  name that contains multiple A/AAAA records, all records are returned as a set; however, the order that the records are returned in the set permutates for ea query since clients typically use the first. 

When inadvertently created, for instance an A record is added instead of modified, then round robin is created. 

### Additional Docs
+ dig
+ getent
+ gethostip
