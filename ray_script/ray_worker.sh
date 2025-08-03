#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <head_node_address:port>"
  exit 1
fi

HEAD_ADDRESS="$1"

# Check if HEAD_ADDRESS is provided
if [[ -z "$HEAD_ADDRESS" ]]; then
    echo "Error: HEAD_ADDRESS is required"
    echo "Usage: $0 <head_address> [--debug]"
    echo "Example: $0 192.168.1.100:6379"
    exit 1
fi

# Parse HEAD_ADDRESS
HEAD_IP=$(echo "$HEAD_ADDRESS" | cut -d: -f1)
HEAD_PORT=$(echo "$HEAD_ADDRESS" | cut -d: -f2)

echo "Connecting to Ray head at: $HEAD_ADDRESS"
echo "Head IP: $HEAD_IP"
echo "Head Port: $HEAD_PORT"

# Test connectivity to head
echo "Testing connectivity to head..."
if command -v nc >/dev/null 2>&1; then
    if nc -z "$HEAD_IP" "$HEAD_PORT" 2>/dev/null; then
        echo "✓ Connection to head successful"
    else
        echo "✗ Connection to head failed - check if head is running and accessible"
    fi
else
    echo "Note: nc (netcat) not available, skipping connectivity test"
fi

PUBLIC_IP=$(curl -s ifconfig.me)

# Set default values if not provided
LOCAL_IP=${LOCAL_IP:-127.0.0.1}
NODE_MANAGER_PORT=${NODE_MANAGER_PORT:-6379}
OBJECT_MANAGER_PORT=${OBJECT_MANAGER_PORT:-8265}

# Generate internal ports based on NUM_OF_PORTS and START_FROM_PORT
NUM_OF_PORTS=${NUM_OF_PORTS:-20}
START_FROM_PORT=${START_FROM_PORT:-10000}

echo "Generating ports: NUM_OF_PORTS=$NUM_OF_PORTS, START_FROM_PORT=$START_FROM_PORT"

# Generate internal ports and check for external mappings
available_internal_ports=()
available_external_ports=()

for ((i=0; i<NUM_OF_PORTS; i++)); do
    internal_port=$((START_FROM_PORT + i))
    external_port_env="VAST_TCP_PORT_${internal_port}"
    external_port="${!external_port_env}"
    
    if [[ -n "$external_port" ]]; then
        available_internal_ports+=($internal_port)
        available_external_ports+=($external_port)
        echo "Found mapping: Internal $internal_port -> External $external_port"
    fi
done

# Set environment variables
if [[ ${#available_internal_ports[@]} -gt 0 ]]; then
    INTERNAL_PORTS=$(IFS=','; echo "${available_internal_ports[*]}")
    EXTERNAL_PORTS=$(IFS=','; echo "${available_external_ports[*]}")
    export INTERNAL_PORTS
    export EXTERNAL_PORTS
    echo "INTERNAL_PORTS: $INTERNAL_PORTS"
    echo "EXTERNAL_PORTS: $EXTERNAL_PORTS"
else
    export INTERNAL_PORTS=""
    export EXTERNAL_PORTS=""
    echo "No external port mappings found"
fi

NODE_MGR_PROXY_PORT_VAR="VAST_TCP_PORT_${NODE_MANAGER_PORT}"
OBJ_MGR_PROXY_PORT_VAR="VAST_TCP_PORT_${OBJECT_MANAGER_PORT}"

echo "Node Manager Port: $NODE_MANAGER_PORT"
echo "Object Manager Port: $OBJECT_MANAGER_PORT"
echo "Internal Node Manager Port: $NODE_MANAGER_PORT"
echo "Internal Object Manager Port: $OBJECT_MANAGER_PORT"
echo "External Node Manager Port: $(eval echo \$$NODE_MGR_PROXY_PORT_VAR)"
echo "External Object Manager Port: $(eval echo \$$OBJ_MGR_PROXY_PORT_VAR)"

ENV_ARRAY=(
    "PROXY_NODE_IP_ADDRESS=$PUBLIC_IP"
    "PROXY_NODE_MANAGER_PORT=${!NODE_MGR_PROXY_PORT_VAR}"
    "PROXY_OBJECT_MANAGER_PORT=${!OBJ_MGR_PROXY_PORT_VAR}"
    "INTERNAL_PORTS=${INTERNAL_PORTS}"
    "EXTERNAL_PORTS=${EXTERNAL_PORTS}"
)

if [[ "$*" == *"--debug"* ]]; then
    echo "Debug mode detected: Running ray with RAY_LOG_TO_STDERR=1"
    ENV_ARRAY+=("RAY_LOG_TO_STDERR=1")
else
    echo "Normal mode: Running ray"
fi

ENV_STRING=$(IFS=' '; echo "${ENV_ARRAY[*]}")
COMPLETE_COMMAND="$ENV_STRING ray start --address=\"$HEAD_ADDRESS\" --node-ip-address=$LOCAL_IP --node-manager-port=\"$NODE_MANAGER_PORT\" --object-manager-port=\"$OBJECT_MANAGER_PORT\" --worker-port-list=$INTERNAL_PORTS"

# Print the complete command
echo "Complete command: $COMPLETE_COMMAND"

# Execute the command
eval $COMPLETE_COMMAND



