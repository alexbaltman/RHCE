#!/bin/bash
sed -i 's/# interface: 127.0.0.1$/interface: 0.0.0.0/g' /etc/unbound/unbound.conf
sed -i 's/access-control: 192.168.6.11 allow/access-control: 192.168.6.0\/24 allow/g' /etc/unbound/unbound.conf
systemctl restart unbound
