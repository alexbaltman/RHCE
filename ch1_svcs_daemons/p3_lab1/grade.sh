#!/bin/bash
ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory -e 'ansible_su_pass=agent007' gradeit.yaml 

if [ $? -ne 0 ]; then
    echo "---------------------"
    echo "Incorrect root password"
    echo "Did you correctly recover and set the root password to agent007?"
    echo "---------------------"
    exit 1;
fi
