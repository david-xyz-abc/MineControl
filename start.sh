#!/bin/bash

# Minecraft Server Startup Script
# Run this script with sudo/root privileges to start the server manually

# Exit on error
set -e

echo "Starting Minecraft Server..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "/opt/minecraft-server/docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found in /opt/minecraft-server"
    echo "Please run the deployment script first"
    exit 1
fi

# Navigate to server directory
cd /opt/minecraft-server

# Start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Start Nginx
echo "Starting Nginx..."
systemctl start nginx

# Check services status
echo "Checking services status..."
sleep 5

# Verify Minecraft container
if docker ps | grep -q "mc-server"; then
    echo "Minecraft server container is running!"
else
    echo "Warning: Minecraft server container failed to start"
    echo "Check logs with: docker logs mc-server"
fi

# Verify web UI container
if docker ps | grep -q "mc-web-ui"; then
    echo "Web UI container is running!"
else
    echo "Warning: Web UI container failed to start"
    echo "Check logs with: docker logs mc-web-ui"
fi

# Check Nginx status
if systemctl status nginx | grep -q "active (running)"; then
    echo "Nginx is running!"
else
    echo "Warning: Nginx failed to start"
    echo "Check logs with: tail -f /var/log/nginx/error.log"
fi

# Verify web UI accessibility
echo "Checking if web UI is accessible..."
if curl -s http://localhost > /dev/null; then
    echo "Web UI is accessible at http://your-server-ip"
    echo "Minecraft server is available on port 25565"
else
    echo "Warning: Web UI might not be accessible"
    echo "Check nginx logs with: tail -f /var/log/nginx/error.log"
fi

echo "Server startup complete!"
