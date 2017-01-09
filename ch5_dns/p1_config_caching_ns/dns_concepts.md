## DNS Concepts

### Overview
Doamin name system (DNS)is a hierarchical naming systems that serves as a directory of networked hsots and resources. Info in that dir maps net names to data and is maintained in logical entries known as resoruce records. The DNS hierarchy starts w/ the root doamin "." at the top and branches downward to multiple next level domains, delineated by ".".

Second level domains are com, net, and org, which all fall underneath ".". And example.com and redhat.com occupy the third level and so on.

#### Domain
A domain is a collection of resource records that ends in a common name and representsa an entire subtree of DNS name space such as example.com. The largest possible domain is the root domain ".", which contains the whole DNS namespace.

A top level domain (TLD) is a domain that has only one component, like generic TLDs including com, edu, net OR country code TLDS (ccTLDS) including .us, .uk, .cn, .ru, etc.


#### Subdomain
A subdomain is a domain that is a subtree of another domain. e.g. lab.example.com is a subdomain of example.com


### Anatomy of a DNS lookup
When a system needs to perform name resolution using a DNS server, it begins by sending queries to the servers listed in the resolv.conf in order, until it gets a response or runs out of servers. The host or dig cmds cna be used to manually look up DNS names. 

#### Local authoritative data
When the query arrives at a DNS server, the server first determines whether trhe information being queried resides in a zone that is authoritative for. If the server is an authority for the zone that the name or address being queried belongs to, then the server responds to the client w/ the info contained in its local zone file. This type of response is referred to as an authoritative answer (*aa*), since the server providing the response is authoritative for the data provided. Authoritative answers from a nameserver have the *aa* flag turned on in the header of the DNS response. 

#### Local cached non-auth data
If the DNs server is not an auth for that record in question and it does not posses the record in its cache, then the server will then recurse attempting to find it.  A DNS server w/ an empty cache beings the recursion process by querying of the the root nameservers by ip addr retrieved from its local, prepopulated root hints file. The root nameserver will then likely respond with a *referral*, which indicated the nameservers that are auth for the TLD that contains the name being queried.

Upon receiving the referral, the dns server will then perf another iterative query to the TLD auth NS it was referred to. Depending on whether there are further remaining delegations in the name being queried, this auth ns will either send an auth answ or yet another referral. This continues until an auth server reached and responds with an aa.

The final answ, along w/ all the intermediate answers obtained prior to it, are cahced by dns server to improve perf. If during a lookup for www.example.com the dns server finds out that the example.com zone has auth nameservers, it will then query those servers directly for any future queries for info in the example.com zone, rather than starting recursion again at the root ns. 

### DNS records
dns resource records (*rr*) is an entry specifying info about a name/object in the zone. An rr contains a type, a TTL, and data elements:
| Field name | Content |
| --- | --- |
| owner-name | The name for the rr |
| TTL | time to live in seconds, specified how long to cache for dns resolvers |
| class | the class of the record, almost always IN ("internet") |
| type | the type indicates the sort of info stored by this record, for example A record maps hostname to ipv4 addr |
| data | data stored by this record |

Some important rr types:
A (ipv4 addr) records
AAAA (ipv6) records
CNAME (canonical name) records - aka alias records for an A or AAAA record

CNAME rr aliases one name to another (the canonical name). When a DNS resolver receives a cname in response to a query, it will reissue the query using the canonical name instead of the original name (the alias). The data field of cname can point to a name anywhere in DNS, whether internal or external to the zone.

Cname records are useful, but should be used w/ some care. In general don't point a cname to antoher cname. The cname chain should end in A/AAAA record. There are legitimate reasons to use a CNAME chain when using a CDN to improve the speed and reliability of data deliver over the internet. Likewise, NS and MX records must not be pointed at CNAME records.

PTR (pointer) records (reverse dns)
These records code the ip addr in a special format that acts like a hostname. For ipv4 addrs the addr is reversed, most specific part first and the result is treated as a host in a subdomain of the special domain in-addr.arpa. For ipv6 addrs the addr is split into subdomains on nibble boundaries (every hexadecimal digit) and set up as a subdomain of the special domain ip6.arpa.

Example:
```
host -v -t PTR 172.25.0.10
--> question section --> 10.0.25.172.in-addr.arpa in PTR
--> answer section --> 10.0.25.172.in-addr.arpa in PTR desktop0.example.com
```

NS(name server) records
A *NS* record maps a domain name to a DNS name server which is authoritative for its DNS zone. Everypublic auth ns for the zone must have an ns record.

SOA (start of auth) records.
An SOA record provides ifo about how a DNS zone works.

There will be exactly one SOA record for a zone. It specifies which of the zones name servers is the primary one (the master), info on how secondary (slave) ns should update their copy of the info, and the zones mgmt contact. Its data field contains:
| Data Element | Content | 
| --- | --- | 
| master ns | the hostname of the ns which is the orig src of domain info and which may accept dynamic dns updates if the zone supports them |
| rname | the email addr of the person responsible for the dns zone |
| serial num | the version num of the zone, which is inc when there is any change to zone records |
| refresh | how freq the slave servers should check for zone updates in seconds |
| retry | how long a slave server should wait before retrying a failed refresh attempt in seconds |
| expiry | if refreshes have been failing, how long a slave server should wait before it stops using its old copy of the zone to respond to queries in seconds | 
| min | if a resolver lookus up a name and it does not exist (gets a nonexistent domain (NXDOMAIN) response) how long it should cahce the info that the record does not exist in secs |

MX (mail exchange) records
An MX record maps a domain name to a mail exchange which will acceptr email for that na e. The data for this record type is a pref number (lowest preferred) used to determine the order in which to pick b/w multiple mx records and a hostname for a mial exchange for that name.

TXT (text) record
Used to map a name to an arbitrary human readable text. These are commonly used to supply data used by Sender Policy Framework (SPF), DomainKeys Identified Mail (DKIM), Domain based message authentication, rporting and conformance (DMARC), etc.

SRV (service) records
An SRV record is used to locate the hosts which support a particular svc for a domain. Using the domain name formatted to include a service and a protocol name, _service._protocol.domain, SRV records provide the names of the hosts that provide that svc for the domain, as well as the port num that the svc listens on. SRV records also include priority and weight values to indicate the order in which hosts should be used when multiple hosts are avail for a particular service.

Example ldap service:
```
host -v -t SRV _ldap._tcp.server0.example.com
Question section:
_ldap._tcp.server0.example.com IN SRV
Answer section:
_ldap._tcp.server0.example.com 86400 IN SRV 0 100 389 server0.example.com
```

### Hosts and rr
A typical host, whether a client or a server wil lhave the following records:
- One or more A/AAAA records mapping its hostname to its ip addr.s
- A PTR record for ea of its ip addr.s, reverse mapping them to its hostname
- Optionally one or more CNAME records mapping alt names to its canonical host name

A DNS zone will typically have, in addition to the records for the hosts in the zone:
- A NS record for ea of its auth ns
- One or more MX records mapping the domain name to the mail exchange which receives email for addr.s ending in the domain name
- Optionally one or more txt records for functions like SPF or Gogole site verification
- Optionally, one or more SRV records to loc svcs in the domain

---
### Practice DNS RRs
Match the following to the desc in the table:
a. A 
b. AAAA
c. CNAME
d. MX
e. NS
f. PTR
g.SOA
h.SRV
i.TXT

1. Contains auith info for zone, such as email contact and several values that config interactions b/w slave and master
2. Maps hostname to ipv4 addr.s
3. Ids the auth nameserver for a zone
4. used to publish loc of net svcs for a domain
5. id.s the mail exchanges responsible for accepting emails for a domain
6. Maps hostnames to ipv6 addr.s
7. enables reverse dns lookups of ip addrs to hostnames
8. Aliases a name to a canonical name
9. used to publish arbitrary human readable text 

---
Answers: a2, b6, c8, d5, e3, f7, g1, h4, i9
