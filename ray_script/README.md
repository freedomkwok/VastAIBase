# Ray Cluster Setup with Proxy Port Mapping

This repository is a fork of [Ray](https://github.com/ray-project/ray) that includes enhanced features for proxy address and port mapping, enabling Ray clusters to connect across different VM machines, particularly optimized for Vast.ai infrastructure.

> **Important Note:** All ports are defined in the Vast.ai template configuration and are **not** generated after the container spawns. The external port mappings (`VAST_TCP_PORT_*` variables) are pre-configured in the template and available immediately when the container starts.

> **Networking Note:** For better connectivity, use machines within the same country/region. Machines in the same geographical location are more likely to connect successfully. Use `telnet ip_address port` to check if machines can connect to each other before starting Ray clusters.

## Overview

Ray is a unified framework for scaling AI and Python applications. This fork extends Ray's capabilities with automatic port mapping and proxy configuration, making it easier to set up distributed Ray clusters across multiple virtual machines.

## Features

- **Manual Port Mapping**: Automatically detects and maps internal ports to external ports using Vast.ai's `VAST_TCP_PORT_*` environment variables
- **Proxy Configuration**: Handles proxy node IP addresses and port mappings automatically

## Quick Start

### 1. Start the Ray Head Node

On your head node VM, run:

```bash
bash ray_head.sh
```

This will:
- Start a Ray head node
- Display the complete command being executed
- Show the head node's external URL and dashboard URL

**Example Output:**
```
Normal mode: Running ray
Complete command: ray start --head --port=6379 --dashboard-port=8265 --dashboard-host=0.0.0.0 --node-ip-address=0.0.0.0 --verbose
Running Ray Head on 192.168.1.100:42392 (external) - internal: 192.172.0.2:6379
Dashboard: http://192.168.1.100:42627 (external) - internal: 192.172.0.2:8265
```

**Note:** You'll need the `[head node external url]` (e.g., `192.168.1.100:42392`) for connecting worker nodes. The external port is assigned by Vast.ai, while the internal port is the standard Ray port (6379).

### 2. Connect Worker Nodes

On each worker VM, run:

```bash
bash ray_worker.sh [head node external url]
```

**Example:**
```bash
bash ray_worker.sh 192.168.1.100:XXXXX
```

## Configuration

### Environment Variables

#### For `ray_head.sh`:

- `RAY_PORT` (default: `6379`): Main Ray communication port
- `RAY_DASHBOARD_PORT` (default: `8265`): Ray dashboard port
- `LOCAL_IP` (default: `0.0.0.0`): IP address to bind to

#### For `ray_worker.sh`:

- `RAY_NODE_MANAGER_PORT` (default: `8077`): Node manager port
- `RAY_OBJECT_MANAGER_PORT` (default: `8076`): Object manager port
- `NUM_OF_PORTS` (default: `15`): Number of worker ports to generate
- `START_FROM_PORT` (default: `17000`): Starting port for worker ports
- `LOCAL_IP` (default: `127.0.0.1`): Local IP address

### Debug Mode

Both scripts support debug mode with the `--debug` flag:

```bash
# Head node with debug
bash ray_head.sh --debug

# Worker with debug
bash ray_worker.sh [head_url] --debug
```

## Port Mapping

The worker script automatically:

1. **Generates Internal Ports**: Creates ports from `START_FROM_PORT` to `START_FROM_PORT + NUM_OF_PORTS - 1`
2. **Checks External Mappings**: Looks for `VAST_TCP_PORT_[internal_port]` environment variables
3. **Detects Port Conflicts**: Skips ports that are already in use
4. **Sets Environment Variables**: Creates `INTERNAL_PORTS` and `EXTERNAL_PORTS` with comma-separated lists

**Example Port Mapping:**
```
✓ Mapping: Internal 17000 -> External 42339
✓ Mapping: Internal 17001 -> External 42397
⚠️  Skipping used port: Internal 17002 is in use
✓ Mapping: Internal 17003 -> External 42410
```

## Troubleshooting

### Port Conflicts

If you encounter port conflicts like:
```
Ray component worker_ports is trying to use a port number 10001 that is used by other components.
```

**Solutions:**
1. **Manual Port Exclusion**: Remove conflicting ports from the generated range
2. **Adjust START_FROM_PORT**: Change the starting port to avoid conflicts
3. **Reduce NUM_OF_PORTS**: Use fewer ports if not all are needed

**Example:**
```bash
# Use different port range
START_FROM_PORT=18000 NUM_OF_PORTS=10 bash ray_worker.sh [head_url]

# Use fewer ports
NUM_OF_PORTS=5 bash ray_worker.sh [head_url]
```

### Connectivity Issues

1. **Check Head Node**: Ensure the head node is running and accessible
2. **Verify External URL**: Use the correct external IP and port from head node output
3. **Network Configuration**: Ensure VMs can communicate with each other
4. **Firewall Settings**: Check if ports are blocked by firewalls

### Debugging

Use debug mode to get more detailed output:

```bash
bash ray_worker.sh [head_url] --debug
```

This will show:
- Complete command being executed
- All environment variables
- Detailed Ray startup logs


## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `RAY_PORT` | `6379` | Main Ray communication port |
| `RAY_DASHBOARD_PORT` | `8265` | Ray dashboard port |
| `RAY_NODE_MANAGER_PORT` | `8077` | Node manager port |
| `RAY_OBJECT_MANAGER_PORT` | `8076` | Object manager port |
| `NUM_OF_PORTS` | `15` | Number of worker ports |
| `START_FROM_PORT` | `17000` | Starting port for workers |
| `LOCAL_IP` | `0.0.0.0` (head), `127.0.0.1` (worker) | Local IP address |

## Contributing

This is a fork of the [Ray project](https://github.com/ray-project/ray). For issues specific to this fork's proxy mapping features, please open an issue in this repository. For general Ray issues, please refer to the [main Ray repository](https://github.com/ray-project/ray).

## License

This project inherits the Apache-2.0 license from the original Ray project. 