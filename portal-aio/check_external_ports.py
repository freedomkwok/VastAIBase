#!/usr/bin/env python3
"""
Script to generate internal ports, check for external mappings, and update INTERNAL_PORTS.
This should be run after the container is running and external ports are available.
"""

import os
import time

def generate_internal_ports():
    """Generate internal ports based on NUM_OF_PORTS and START_PORT environment variables."""
    num_of_ports = int(os.environ.get('NUM_OF_PORTS', '20'))
    start_port = int(os.environ.get('START_PORT', '10000'))
    
    # Generate internal ports
    internal_ports = list(range(start_port, start_port + num_of_ports))
    print(f"Generated {len(internal_ports)} internal ports: {internal_ports}")
    
    return internal_ports

def check_external_port_mapping(internal_port):
    """Check if an internal port has an external port mapping."""
    external_port_env = f"VAST_TCP_PORT_{internal_port}"
    external_port = os.environ.get(external_port_env)
    return int(external_port) if external_port else None

def wait_for_external_ports(internal_ports, timeout=300, check_interval=10):
    """Wait for external ports to become available."""
    print(f"Waiting for external ports to become available (timeout: {timeout}s)...")
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        # Check which internal ports have external mappings
        mapped_ports = []
        for internal_port in internal_ports:
            external_port = check_external_port_mapping(internal_port)
            if external_port:
                mapped_ports.append((internal_port, external_port))
        
        if mapped_ports:
            print(f"Found {len(mapped_ports)} external port mappings:")
            for internal_port, external_port in mapped_ports:
                print(f"  Internal {internal_port} -> External {external_port}")
            return mapped_ports
        
        print(f"Waiting... ({int(time.time() - start_time)}s elapsed)")
        time.sleep(check_interval)
    
    print(f"Timeout reached ({timeout}s). No external ports found.")
    return []

def update_internal_ports(mapped_ports):
    """Update INTERNAL_PORTS environment variable with only ports that have external mappings."""
    if mapped_ports:
        internal_ports_with_mappings = generate_internal_ports()
        internal_ports_str = ','.join(internal_ports_with_mappings)
        external_ports_str = ','.join([str(external_port) for _, external_port in mapped_ports])
        os.environ['INTERNAL_PORTS'] = internal_ports_str
        os.environ['DEFAULT_INTERNAL_PORTS'] = internal_ports_str
        os.environ['EXTERNAL_PORTS'] = external_ports_str
        os.environ['DEFAULT_EXTERNAL_PORTS'] = external_ports_str

        print(f"Updated INTERNAL_PORTS: {internal_ports_str}")
        return True
    else:
        os.environ['INTERNAL_PORTS'] = ''
        print("No external port mappings found. INTERNAL_PORTS set to empty.")
        return False

def main():
    print("Starting external port mapping check...")
    
    # Step 1: Generate internal ports
    internal_ports = generate_internal_ports()
    
    # Step 2: Wait for external ports to become available
    mapped_ports = wait_for_external_ports(internal_ports)
    
    # Step 3: Update INTERNAL_PORTS with only ports that have external mappings
    success = update_internal_ports(mapped_ports)
    
    if success:
        print("\nExternal port mapping check completed successfully!")
        print("INTERNAL_PORTS environment variable has been updated.")
    else:
        print("\nNo external port mappings found.")
        print("You can run this script again later to check for updates.")

if __name__ == "__main__":
    main() 