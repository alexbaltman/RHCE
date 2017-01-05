#!/bin/bash
ansible-playbook -e 'host_key_checking=False' -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory  gradeit.yaml
