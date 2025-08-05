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

# Connectivity check
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
LOCAL_IP=$(hostname -I | awk '{print $1}')
OBJECT_MANAGER_PORT=${RAY_OBJECT_MANAGER_PORT:-8076}
NODE_MANAGER_PORT=${RAY_NODE_MANAGER_PORT:-8077}
NUM_OF_PORTS=${NUM_OF_PORTS:-15}
START_FROM_PORT=${START_FROM_PORT:-17000}

echo "Generating ports: NUM_OF_PORTS=$NUM_OF_PORTS, START_FROM_PORT=$START_FROM_PORT"

available_internal_ports=()
available_external_ports=()

# === BEGIN PORT CHECK ===
is_port_in_use() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -iTCP:$port -sTCP:LISTEN -t >/dev/null 2>&1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -an | grep -q ":$port .*LISTEN"
    else
        echo "Warning: Cannot check ports (missing lsof/netstat)"
        return 1
    fi
}
# === END PORT CHECK ===

for ((i=0; i<NUM_OF_PORTS; i++)); do
    internal_port=$((START_FROM_PORT + i))
    external_port_env="VAST_TCP_PORT_${internal_port}"
    external_port="${!external_port_env:-}"

    if [[ -n "$external_port" ]]; then
        if is_port_in_use "$internal_port"; then
            echo "⚠️  Skipping used port: Internal $internal_port is in use"
        else
            available_internal_ports+=($internal_port)
            available_external_ports+=($external_port)
            echo "✓ Mapping: Internal $internal_port -> External $external_port"
        fi
    fi
done

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
    echo "No usable port mappings found"
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
    "PROXY_NODE_MANAGER_PORT=${!NODE_MGR_PROXY_PORT_VAR:-}"
    "PROXY_OBJECT_MANAGER_PORT=${!OBJ_MGR_PROXY_PORT_VAR:-}"
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

echo "Complete command: $COMPLETE_COMMAND"
eval $COMPLETE_COMMAND