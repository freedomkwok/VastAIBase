#!/usr/bin/env python3
"""
Script to wait for external ports to become available and update the configuration.
This should be run after the container is running and caddy has started.
"""

import os
import sys
import time
import yaml
import subprocess

# Add the caddy_manager directory to the path
sys.path.insert(0, '/opt/portal-aio/caddy_manager')

from caddy_config_manager import (
    get_available_internal_ports, 
    get_external_port_for_internal,
    wait_for_external_ports,
    generate_caddyfile
)

def update_config_with_external_ports():
    """
    Update the portal configuration with external port mappings once they're available.
    """
    yaml_path = '/etc/portal.yaml'
    if not os.path.exists(yaml_path):
        print("Portal configuration file not found")
        return False
    
    # Load current configuration
    with open(yaml_path, 'r') as file:
        yaml_data = yaml.safe_load(file)
        config = yaml_data['applications']
    
    internal_ports = get_available_internal_ports()
    if not internal_ports:
        print("No internal ports found")
        return False
    
    updated_count = 0
    
    # Check each internal port for external mapping
    for internal_port in internal_ports:
        external_port = get_external_port_for_internal(internal_port)
        if external_port:
            # Update configuration if this port is in the config
            app_name = f"auto_port_{internal_port}"
            if app_name in config:
                if config[app_name]['external_port'] != external_port:
                    config[app_name]['external_port'] = external_port
                    updated_count += 1
                    print(f"Updated {app_name}: Internal {internal_port} -> External {external_port}")
    
    if updated_count > 0:
        # Save updated configuration
        yaml_data = {"applications": config}
        with open(yaml_path, "w") as file:
            yaml.dump(yaml_data, file, default_flow_style=False, sort_keys=False)
        
        # Regenerate caddy configuration
        caddyfile_content, username, password = generate_caddyfile(config)
        with open('/etc/Caddyfile', 'w') as f:
            f.write(caddyfile_content)
        
        # Reload caddy configuration
        try:
            subprocess.run(['/opt/portal-aio/caddy_manager/caddy', 'reload', '--config', '/etc/Caddyfile'], 
                         check=True, capture_output=True)
            print("Caddy configuration reloaded successfully")
        except subprocess.CalledProcessError as e:
            print(f"Warning: Could not reload caddy config: {e}")
            print("You may need to restart the caddy service manually")
        
        print(f"Updated {updated_count} port mappings and regenerated caddy configuration")
        return True
    else:
        print("No external port mappings found or no updates needed")
        return False

def main():
    print("Waiting for external ports to become available...")
    
    # Wait for external ports with a 5-minute timeout
    if wait_for_external_ports(timeout=300, check_interval=10):
        print("\nExternal ports found! Updating configuration...")
        success = update_config_with_external_ports()
        
        if success:
            print("\nExternal port mappings updated successfully!")
            print("The caddy service has been reloaded with the new mappings.")
        else:
            print("\nNo updates were needed.")
    else:
        print("\nTimeout reached. External ports not available.")
        print("You can run this script again later to check for updates.")

if __name__ == "__main__":
    main() 