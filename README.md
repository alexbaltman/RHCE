# RHCE on RHEL-7 - Study Guide

## How to use

## Need to study from notes after first take of exam
- ch2 p3 - Config IPv6
- ch3 p1 - Config Network Teaming
- ch4 p1 - Config firewall
- ch4 p2 - Manage Rich Rules
- ch4 p3 - Masq. and Port forwarding
- ch5 p2 - Config caching Nameserver
- ch6 p1 - Config send only email

## Known issues
ch2 p2: ipv6 setup is a bit wonky still. First, w/ vagrant version 1.8.1 ipv6 was not booting the vm and it gave static ipv6 template error from embedded gem. After upgrading 10 1.9.1 I was able to at least boot it.
ch2 p2: Booting host1 and host2 vagrant/virtualbox inconsistently bring up eth1 w/ ipv6 addr. I had to manually configure both one time, another time host2 came up fine but host1 did not. Originally, I was just going to have someone setup ipv6 on host1 from scratch, but b/c of the inconsistent networking I expanded it to setting up both. Vagrant/virtualbox at least seem to consistently bring up the backend plumbing so it should theoretically work once yo properly setup ipv6 on both nodes. 
