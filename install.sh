#!/bin/bash

IP=$1

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ./scripts/* "root@$IP:/install"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t "root@$IP" 'cd /install; exec $SHELL'
