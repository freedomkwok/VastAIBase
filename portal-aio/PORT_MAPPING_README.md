# Port Mapping Functionality

This document explains how to use the automatic port mapping functionality in VastAIBase.

## Overview

The port mapping system automatically generates internal ports based on environment variables and can automatically add them to the portal configuration. External port mappings are assigned by Vast.ai infrastructure after the container starts.

## Environment Variables

### Required Variables

- `NUM_OF_PORTS` (default: 20): Number of internal ports to generate
- `START_PORT` (default: 10000): Starting port number for internal ports

### Optional Variables

- `AUTO_ADD_GENERATED_PORTS` (default: true): Whether to automatically add generated ports to portal configuration
- `INTERNAL_PORTS`: Automatically set with comma-separated list of generated internal ports

## How It Works

1. **Initial Generation**: When the caddy config manager starts, it generates internal ports from `START_PORT` to `START_PORT + NUM_OF_PORTS - 1`
2. **Environment Variable**: Sets `INTERNAL_PORTS` with all generated internal ports
3. **Configuration**: If `AUTO_ADD_GENERATED_PORTS` is true, adds these ports to the portal configuration
4. **External Mapping**: External ports are assigned by Vast.ai and available as `VAST_TCP_PORT_*` environment variables

## Usage Examples

### Basic Usage

```bash
# Generate 20 ports starting from 10000
export NUM_OF_PORTS=20
export START_PORT=10000

# The system will generate ports 10000-10019 and set INTERNAL_PORTS="10000,10001,...,10019"
```

### Custom Configuration

```bash
# Generate 50 ports starting from 20000
export NUM_OF_PORTS=50
export START_PORT=20000

# Disable auto-adding to portal configuration
export AUTO_ADD_GENERATED_PORTS=false
```

### Checking External Mappings

After the container is running and external ports are assigned:

```bash
# Check current external port mappings
python /opt/portal-aio/update_external_ports.py
```

## Generated Files

- `INTERNAL_PORTS` environment variable: Contains comma-separated list of generated internal ports
- Portal configuration entries: Auto-generated entries named `auto_port_<internal_port>`
- Caddy configuration: Automatically updated with external port mappings

## Manual Updates

If you need to manually update external port mappings:

```bash
cd /opt/portal-aio
python update_external_ports.py
```

This will:
1. Check for available external port mappings
2. Update the portal configuration
3. Regenerate the caddy configuration
4. Apply the changes

## Troubleshooting

### No External Ports Available

This is normal if the container just started. External ports are assigned by Vast.ai infrastructure and may take a few minutes to become available.

### Ports Not Added to Configuration

Check that `AUTO_ADD_GENERATED_PORTS` is set to `true` (default).

### Configuration Not Updated

Run the update script manually:
```bash
python /opt/portal-aio/update_external_ports.py
```

## Integration with Existing Applications

The generated ports can be used by any application that needs to bind to a specific port. The `INTERNAL_PORTS` environment variable provides a list of available ports that have been configured for external access.

Example usage in an application:
```python
import os

internal_ports = os.environ.get('INTERNAL_PORTS', '').split(',')
if internal_ports:
    # Use the first available port
    port = int(internal_ports[0])
    # Start your application on this port
``` 