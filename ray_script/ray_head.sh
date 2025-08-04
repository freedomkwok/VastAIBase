#!/bin/bash
PUBLIC_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Set default values if not provided
RAY_PORT=${RAY_PORT:-6379}
RAY_DASHBOARD_PORT=${RAY_DASHBOARD_PORT:-8265}

PROXY_PORT_VAR="VAST_TCP_PORT_${RAY_PORT}"
PROXY_DASHBOARD_PORT_VAR="VAST_TCP_PORT_${RAY_DASHBOARD_PORT}"

# Base environment variables
ENV_ARRAY=()

if [[ "$*" == *"--debug"* ]]; then
    echo "Debug mode detected: Running ray with RAY_LOG_TO_STDERR=1"
    ENV_ARRAY+=("RAY_LOG_TO_STDERR=1")
else
    echo "Normal mode: Running ray"
fi

ENV_STRING=$(IFS=' '; echo "${ENV_ARRAY[*]}")
COMPLETE_COMMAND="$ENV_STRING ray start --head --port=$RAY_PORT --dashboard-port=$RAY_DASHBOARD_PORT --dashboard-host=$LOCAL_IP --node-ip-address=$LOCAL_IP --verbose"

# Print the complete command
echo "Complete command: $COMPLETE_COMMAND"

# Execute the command
eval $COMPLETE_COMMAND

echo "Running Ray Head on ${PUBLIC_IP}:${!PROXY_PORT_VAR}"
echo "Dashboard: http://${PUBLIC_IP}:${!PROXY_DASHBOARD_PORT_VAR}"
