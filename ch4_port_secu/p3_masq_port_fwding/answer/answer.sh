#!/bin/bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.7.66/32" forward-port port="443" protocol="tcp" to-port="22"'
firewall-cmd --reload
