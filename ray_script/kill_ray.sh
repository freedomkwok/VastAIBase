#!/bin/bash

# Script to kill all Ray processes
# This script finds and terminates all Ray-related processes safely

set -e  # Exit on any error

echo "🔍 Searching for Ray processes..."

# Function to kill processes by name pattern
kill_processes_by_pattern() {
    local pattern="$1"
    local process_name="$2"
    
    # Find PIDs of processes matching the pattern
    local pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "📋 Found $process_name processes: $pids"
        echo "🔄 Terminating $process_name processes..."
        
        # Send SIGTERM first (graceful shutdown)
        echo "$pids" | xargs -r kill -TERM 2>/dev/null || true
        
        # Wait a bit for graceful shutdown
        sleep 2
        
        # Check if processes are still running and force kill if needed
        local remaining_pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            echo "⚠️  Some $process_name processes didn't terminate gracefully, force killing..."
            echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
        fi
        
        echo "✅ $process_name processes terminated"
    else
        echo "ℹ️  No $process_name processes found"
    fi
}

# Function to kill processes by exact name
kill_processes_by_name() {
    local process_name="$1"
    
    # Find PIDs of processes with exact name
    local pids=$(pgrep -x "$process_name" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "📋 Found $process_name processes: $pids"
        echo "🔄 Terminating $process_name processes..."
        
        # Send SIGTERM first (graceful shutdown)
        echo "$pids" | xargs -r kill -TERM 2>/dev/null || true
        
        # Wait a bit for graceful shutdown
        sleep 2
        
        # Check if processes are still running and force kill if needed
        local remaining_pids=$(pgrep -x "$process_name" 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            echo "⚠️  Some $process_name processes didn't terminate gracefully, force killing..."
            echo "$remaining_pids" | xargs -r kill -KILL 2>/dev/null || true
        fi
        
        echo "✅ $process_name processes terminated"
    else
        echo "ℹ️  No $process_name processes found"
    fi
}

# Main Ray processes to kill
echo "🎯 Killing main Ray processes..."

# Kill Ray processes by pattern
kill_processes_by_pattern "raylet" "Raylet"
kill_processes_by_pattern "gcs_server" "GCS Server"
kill_processes_by_pattern "plasma_store_server" "Plasma Store"
kill_processes_by_pattern "ray_client_server" "Ray Client Server"
kill_processes_by_pattern "dashboard" "Dashboard"
kill_processes_by_pattern "monitor" "Monitor"
kill_processes_by_pattern "log_monitor" "Log Monitor"
kill_processes_by_pattern "runtime_env_agent" "Runtime Env Agent"
kill_processes_by_pattern "metrics_agent" "Metrics Agent"

# Kill specific Ray processes by name
kill_processes_by_name "raylet"
kill_processes_by_name "gcs_server"
kill_processes_by_name "plasma_store_server"
kill_processes_by_name "ray_client_server"
kill_processes_by_name "dashboard"
kill_processes_by_name "monitor"
kill_processes_by_name "log_monitor"
kill_processes_by_name "runtime_env_agent"
kill_processes_by_name "metrics_agent"

# Kill Python processes that might be running Ray
echo "🐍 Killing Python Ray processes..."
kill_processes_by_pattern "python.*ray" "Python Ray"

# Kill any remaining Ray-related processes
echo "🔍 Killing any remaining Ray-related processes..."
kill_processes_by_pattern "ray" "Ray-related"

# Clean up Ray temporary files and sockets (optional)
echo "🧹 Cleaning up Ray temporary files..."

# Remove Ray session directories
if [ -d "/tmp/ray" ]; then
    echo "🗑️  Removing /tmp/ray directory..."
    rm -rf /tmp/ray 2>/dev/null || echo "⚠️  Could not remove /tmp/ray (may be in use)"
fi

# Remove Ray socket files
find /tmp -name "ray_*" -type s -delete 2>/dev/null || true
find /tmp -name "*ray*" -type s -delete 2>/dev/null || true

echo "✅ Ray cleanup completed!"

# Final check for any remaining Ray processes
echo "🔍 Final check for remaining Ray processes..."
remaining=$(pgrep -f "ray" 2>/dev/null || true)
if [ -n "$remaining" ]; then
    echo "⚠️  Warning: Some Ray processes may still be running:"
    echo "$remaining" | xargs -r ps -o pid,comm,args 2>/dev/null || true
else
    echo "✅ No Ray processes found running"
fi

echo "🎉 Ray cleanup script completed!" 

