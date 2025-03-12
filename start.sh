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

echo "Waiting for services to initialize..."
# Increase initial wait time to allow for proper initialization
sleep 15

# Verify Minecraft container with more thorough checks
echo "Checking services status..."
MAX_ATTEMPTS=12
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if docker ps | grep -q "mc-server"; then
        # Check if server is actually ready by looking for "Done" in logs
        if docker logs mc-server 2>&1 | grep -q "Done"; then
            echo "Minecraft server is fully initialized!"
            break
        fi
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "Warning: Minecraft server initialization timed out"
        echo "Check logs with: docker logs mc-server"
        exit 1
    fi
    
    echo "Waiting for Minecraft server to initialize... (Attempt $ATTEMPT/$MAX_ATTEMPTS)"
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

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

# Verify web UI accessibility with retry mechanism
echo "Checking if web UI is accessible..."
ATTEMPT=1
while [ $ATTEMPT -le 6 ]; do
    if curl -s http://localhost > /dev/null; then
        echo "Web UI is accessible at http://your-server-ip"
        echo "Minecraft server is available on port 25565"
        break
    fi
    
    if [ $ATTEMPT -eq 6 ]; then
        echo "Warning: Web UI is not accessible after multiple attempts"
        echo "Check nginx logs with: tail -f /var/log/nginx/error.log"
        exit 1
    fi
    
    echo "Waiting for web UI to become accessible... (Attempt $ATTEMPT/6)"
    sleep 5
    ATTEMPT=$((ATTEMPT + 1))
done

echo "Server startup complete!"
