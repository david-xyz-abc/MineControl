# Docker Minecraft Server with Web UI

This project provides a complete setup for running a Minecraft server using Docker, with a web-based control panel.

## Features

- Minecraft server running in Docker
- Web-based control panel
- Nginx reverse proxy
- RCON support for server commands
- Automatic server status monitoring

## Prerequisites

- Debian-based Linux system
- Root access
- Internet connection

## Quick Installation

Just download and run the deployment script:

```bash
curl -sSL https://raw.githubusercontent.com/david-xyz-abc/MineControl/main/setup_minecontrol.sh | tr -d '\r' | sudo bash
```

The script will automatically:
- Install all required dependencies
- Clone the repository
- Set up the directory structure
- Configure and start all services

## Configuration

### Minecraft Server
- The Minecraft server data is stored in `/opt/minecraft-server/data/minecraft`
- Server configuration can be modified in `docker-compose.yml`
- Default memory allocation is 2GB (can be changed in `docker-compose.yml`)

### Web UI
- Access the web UI at `http://your-server-ip`
- The web interface allows you to:
  - Monitor server status
  - Send commands to the server
  - View player list

### Security
- Remember to change the RCON password in both `docker-compose.yml` and `data/web-ui/server.js`
- Consider setting up SSL/TLS for the web interface
- Configure firewall rules to only allow necessary ports (25565 for Minecraft, 80 for web UI)

## Usage

### Starting/Stopping the Server
```bash
# Start services
cd /opt/minecraft-server
docker-compose up -d

# Stop services
docker-compose down
```

### Accessing the Web UI
1. Open your web browser
2. Navigate to `http://your-server-ip`
3. Use the interface to monitor and control your server

### Server Commands
Enter Minecraft server commands directly in the web UI's command input field.

## Troubleshooting

1. If the web UI shows "offline":
   - Check if the Minecraft container is running
   - Verify RCON password matches in both configuration files
   - Check the logs: `docker-compose logs`

2. If Nginx fails to start:
   - Check if port 80 is already in use
   - Verify Nginx configuration: `nginx -t`

3. If deployment fails:
   - Check your internet connection
   - Verify GitHub repository is accessible
   - Check system requirements and permissions

## Maintenance

- Backup the `/opt/minecraft-server/data` directory regularly
- Monitor server logs: `docker-compose logs -f`
- Update images: `docker-compose pull`
- Update code: `cd /opt/minecraft-server && git pull` 
