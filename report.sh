#!/bin/bash

# NOT WORKING NEED TO FIX

# Get worker IP from Terraform output as JSON-like string
worker_ips_json=$(terraform output -json worker_ip)

vm_username="docker"
vm_password="@test12345"

# Extract individual IP addresses from JSON-like string
worker_ips_array=($(echo "$worker_ips_json" | jq -r '.[]'))

for worker_ip in "${worker_ips_array[@]}"; do
   sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$worker_ip 'docker logs $(docker ps -aqf \"name=loadtest\")'
done
