#!/bin/bash

# this script will run load test on swarm cluster

# Get manager IP from Terraform output as JSON-like string
manager_ips_json=$(terraform output -json manager_ip)

# Extract individual IP addresses from JSON-like string
manager_ips_array=($(echo "$manager_ips_json" | jq -r '.[]'))

manager_external_ip=${manager_ips_array[0]}

vm_username="docker"
vm_password="@test12345"

sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$manager_external_ip "git clone https://github.com/wuttinanhi/1-million-connection-challenge.git && cd 1-million-connection-challenge && docker build -t 1m-connection . && docker stack deploy -c docker-compose.yml my-stack"
