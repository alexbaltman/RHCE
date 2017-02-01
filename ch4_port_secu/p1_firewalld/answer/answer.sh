#!/bin/bash
firewall-cmd --set-default=dmz
firewall-cmd --permanent --zone=work --add-source=192.168.6.0/24
firewall-cmd --permanent --zone=work --add-service=https
