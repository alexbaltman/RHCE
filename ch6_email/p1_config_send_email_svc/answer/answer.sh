#!/bin/bash
postconf -e "relayhost=[192.168.6.66]"
postconf -e "inet_interfaces=loopback-only"
postconf -e "mynetworks=127.0.0.0/8 [::1]/128"
postconf -e "myorigin=example.com"
postconf -e "mydestination="
postconf -e "local_transport=error: local delivery disabled"
systemctl restart postfix
