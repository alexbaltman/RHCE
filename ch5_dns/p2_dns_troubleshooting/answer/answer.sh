#!/bin/bash
# force refresh of dhcp since resolv.conf was manually changed
systemctl restart NetworkManager
# Also could do something like this if you add in a forward-zone to 8.8.8.8 in unbound.conf
#sed -i '/nameserver.*/nameserver 192.168.6.6/g' /etc/resolv.conf
