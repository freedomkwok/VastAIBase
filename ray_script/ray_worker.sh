#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <head_node_address:port>"
  exit 1
fi

HEAD_ADDRESS="$1"
PUBLIC_IP=$(curl -s ifconfig.me)

# Set default values if not provided
LOCAL_IP=${LOCAL_IP:-127.0.0.1}
NODE_MANAGER_PORT=${NODE_MANAGER_PORT:-6379}
OBJECT_MANAGER_PORT=${OBJECT_MANAGER_PORT:-8265}

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



