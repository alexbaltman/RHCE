## Config Caching Nameserver

### Overview
Caching ns store dns query results in a local cache and remove rr from cache when TTLs expire. it is common to set up caching ns to perform queries on behalf of clients on the local net. This greatly improves the efficiency of dns name resolutions by reducing DNS traf across the network. As the cache grows, dns performance improves as the caching ns answers more and more client queries from its local cache.

#### DNSSEC validation
Give the stateless anture of udp, dns txns are prone to spoofing and teampering. Caching ns have historically been favored targets of attackers looking to redirect or hijack net traf. This is often achieved by exploiting vulnerabilities in dns server sfot to fool a dns server into accpeting and populating malicious data into its cache, a technique called cache poisoning. Once the attacker succeeds in poisoning dns servers cache they effectively compromise the dns data received by the numerous clients utilizing the caching name service on the dns server and can consequently redirect or hijack the clients net traf. 

While a caching ns can greatly improve dns perf on the local net, they can also provide improved sec by perf domain name system sec extensions (DNSSEC). DNSSEC validation enabled at the caching ns allows the auth and integrity of rr to be validated prior to bein gplaced in the cache for use by clients and therefore protects clients against the consequences of cache poisoning.


### Config and admin unbound as a caching NS
Severl dns packages for caching: bind, dnsmasq, and unbound. In this ex we will use unbound as a secure, caching NS with DNSSEC validation enabled.

1. Install unbound
```
yum install -y unbound
```
2. Start service
```
systemctl start unbound
systemctl enable unbound
```
3. Config the net int to listen on
By default, unbound only listens on localhost net int. To change this use the *interface* option in the server clause of the /etc/unbound/unbound.conf to specify the net ints to listen on. 0.0.0.0 for all ints.
```
interface: 0.0.0.0
```
4. Config client access
By default, unbound refuses recursive queries from all clients. In the server clause of /etc/unbound/unbound.conf, use the access-control option to specify which clients are allowed to make recursive queries.
```
access-control: 172.25.0.0/24 allow
```
5. Config fwding
In unbound.conf create a forward-zone clause to specify which dns servers to fwd queries to. Dns servers can be specified by hostname using the forward-host option or by ip adress using the forward-addr option. For a cachign nameserver, forward all queries by specifying a forward-zone of ".":
```
forward-zone:
  name: "."
  forward-addr: 172.25.254.254
```
6. If desired bypass DNSSEC validation for select unsigned zones.
By default unbound is enabled to perf dnssec validation to verify all dns responses received. The domain-insecure option in the server clause of the unbound.conf can be used to specify a domain for which DNSSEC validation should be skipped. This is often desirable when dealing w/ an unsigned internal domain that would otherwise fail trust chain validation.
```
domain-insecure: example.com
```
7. If desired, install trust anchors for select signed zones w/o complete chain fo trust.
Since not all ccTLDs have complete implementatiion of DNSSEC, the subdomains of these ccTLDs can be DNSSEC-signed but still have a broken chain of trust. This problem can overcome by using the *trust-anchor* option in the server clause of unbound.conf to specify a trust anchor for the zone. Obtain the DNSKEY record for the key signing key (KSK) of the zone using dig and input it as the value for the trust-anchor option.
```
$ dig +dnssec DNSKEY example.com
trust-anchor: "example.com. 3600 in DNSKEY 257 3 8 AwEAAawt7...
```
8. Save changes to unbound.conf
9. Check unbound.conf for syntax errors
```
$ unbound-checkconf
unbound-checkconf: no errors in /etc/unbound/unbound.conf
```
10. Restart unbound.service
```
systemctl restart unbound.service
```
11. Config the fw to allow DNS traf
```
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload
```

#### Dumping and loading unbound cache
Admins of caching ns need to dump out cache data when troubleshooting DNS issues, such as those resulting from stale rrs. With an unbound dns server the cache can be dumped by running the *unbound-control* utility in conjunction with the dump_cache subcmd
```
unbound-control dump_cache
```
Executing unbound-control w/ the dump_cache cmd dumps out the cache to stdout in a text format. This output can be directed to a file for storage and be loaded back into cache later with unbound-control load_cache. If desired unbound-control load_cache reads from stdin to populate the cache
```
unbound-control load_cache < dump.out
```

#### Flusing unbound cache
Admin of caching ns need to purge outdated resource records from cache from time to time. 
```
unbound-control flush www.example.com
```
If all rrs belonging to a domain need to be purged from the cache of an unbound dns server, then you can exec:
```
unbound-control flush_zone example.com

#### Updating local cache unbound config w/ dnssec-trigger
In addition to providing caching name svc for a local subnet, unbound can also be useful as a local caching NS to provide secure DNS name resolution for local use on an indiv system. For a local caching NS setup, the NS entry in resolv.conf will be configured to point to *localhost* where unbound is listening. The unbound config will forward DNS requests to upstream NS to validate their responses.

For DHCP systems running local caching name service the upstream NS specified in unbounds config may become outdated if DNS servers provided by DHCP change. The dnssec-trigger tool suppled by the pkg of the same name cab be leveraged to auto update fwd settings in unbound config file to point to the new DNS servers. The use of the dnssec-trigger tool in conjuction w/ unbound is mostly useful for secure DNS name resolution on roaming client machines.

### Additional Reading
+ unbound
+ unbound-checkconf
+ unbound.conf
+ unbound-control
+ dnssec-trigger
