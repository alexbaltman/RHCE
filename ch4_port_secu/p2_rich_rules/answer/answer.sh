#!/bin/bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.6.66" service name="http" log prefix="NEW HTTP " level="notice" limit value="3/s" accept'
