#!/bin/bash

# Get manager IP from Terraform output as JSON-like string
manager_ips_json=$(terraform output -json manager_first_node_private_ip)

# Remove quotes from the string
manager_ip=${manager_ips_json//\"/}

# Get manager IP from Terraform output as JSON-like string
manager_ips_json=$(terraform output -json manager_ip)

# Extract individual IP addresses from JSON-like string
manager_ips_array=($(echo "$manager_ips_json" | jq -r '.[]'))

# Get worker IP from Terraform output as JSON-like string
worker_ips_json=$(terraform output -json worker_ip)

# Extract individual IP addresses from JSON-like string
worker_ips_array=($(echo "$worker_ips_json" | jq -r '.[]'))

manager_external_ip=${manager_ips_array[0]}
manager_internal_ip=$manager_ip

echo "Manager external IP: $manager_external_ip"
echo "Manager internal IP: $manager_internal_ip"

vm_username="docker"
vm_password="@test12345"

# Function to initialize Docker swarm on the first manager
initialize_swarm() {
  echo "Initializing swarm on $manager_external_ip"

  # Connect to the manager node and initialize Docker swarm
  # ssh-keygen -f "/home/bb/.ssh/known_hosts" -R "$manager_external_ip"
  local cmd="docker swarm init --advertise-addr $manager_internal_ip"
  echo "Executing command: $cmd"
  sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$manager_external_ip "$cmd"
}

# Function to join a manager to the swarm
join_manager_to_swarm() {
  local mip=$1
  local token=$2

  # Connect to the manager node and join the swarm as manager
  # ssh-keygen -f "/home/bb/.ssh/known_hosts" -R "$mip"
  # ssh-keygen -f "/home/bb/.ssh/known_hosts" -R "$manager_internal_ip"
  sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$mip "docker swarm join --token $token $manager_internal_ip:2377"
}

# Initialize the Docker swarm on the first manager node
initialize_swarm "${manager_ips_array[0]}"

# Retrieve the manager join token from the first manager node
manager_token=$(sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$manager_external_ip 'docker swarm join-token manager -q')

echo "Manager token: $manager_token"

# Connect the other manager nodes to the swarm
for mip in "${manager_ips_array[@]:1}"; do
  echo "Joining manager $mip to the swarm"
  join_manager_to_swarm "$mip" "$manager_token"
done

# Function to join a worker to the swarm
join_worker_to_swarm() {
  local worker_ip=$1
  local manager_ip=$2

  # Connect to the worker node and join the swarm using sshpass
  # ssh-keygen -f "/home/bb/.ssh/known_hosts" -R "$worker_ip"
  # ssh-keygen -f "/home/bb/.ssh/known_hosts" -R "$worker_ip"

  local worker_token=$(sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$manager_external_ip 'docker swarm join-token worker -q')
  echo "Worker token: $worker_token"

  local cmd="docker swarm join --token $worker_token $manager_internal_ip:2377"
  echo "Executing command: $cmd"
  sshpass -p "$vm_password" ssh -o StrictHostKeyChecking=no $vm_username@$worker_ip "$cmd"
}

# Connect the worker nodes to the swarm using the first manager node's IP
for worker_ip in "${worker_ips_array[@]}"; do
  echo "Joining worker $worker_ip to the swarm at $manager_ip"
  join_worker_to_swarm "$worker_ip" "$manager_ip"
done
