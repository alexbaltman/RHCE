#!/bin/bash

sed -i 's/# interface: 0.0.0.0$/interface: 0.0.0.0/g' /etc/unbound/unbound.conf
sed -i 's/# access-control: 127.0.0.0\/8 allow/access-control: 192.168.6.0\/24 allow/g' /etc/unbound/unbound.conf
sed -i 's/# domain-insecure: "example.com"/domain-insecure: "example.com"/g' /etc/unbound/unbound.conf
# Change only the first occurrence
sed -i '0,/# forward-zone:/{s/# forward-zone:/forward-zone:/}' /etc/unbound/unbound.conf
sed -i 's/# \tname: "example.com"/ \tname: "example.com"/g' /etc/unbound/unbound.conf
sed -i 's/# \tforward-addr: 192.0.2.68/ \tforward-addr: 8.8.8.8/g' /etc/unbound/unbound.conf

firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

unbound-checkconf 
#Caution: unbound listen interface not changed on reload, only on restart
systemctl start unbound
systemctl enable unbound
