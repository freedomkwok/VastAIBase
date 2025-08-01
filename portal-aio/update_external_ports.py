#!/usr/bin/env python3
"""
Script to update external port mappings once they're available from Vast.ai infrastructure.
This should be run after the container is running and external ports have been assigned.
"""

import os
import sys
import subprocess

# Add the caddy_manager directory to the path
sys.path.insert(0, '/opt/portal-aio/caddy_manager')

from caddy_config_manager import refresh_config_with_external_ports

def main():
    print("Checking for external port mappings...")
    success = refresh_config_with_external_ports()
    
    if success:
        print("\nExternal port mappings updated successfully!")
        print("Caddy configuration has been regenerated with the new mappings.")
        print("The caddy service should automatically pick up the changes.")
    else:
        print("\nNo external port mappings available yet.")
        print("This is normal if the container just started.")
        print("You can run this script again later to check for updates.")

if __name__ == "__main__":
    main() 