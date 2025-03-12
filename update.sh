#!/bin/bash

# Exit on error
set -e

echo "Starting Minecraft Server UI Update..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Check if directory exists
if [ ! -d "/opt/minecraft-server" ]; then
    echo "Error: /opt/minecraft-server directory not found"
    echo "Please run deploy.sh first"
    exit 1
fi

# Navigate to server directory
cd /opt/minecraft-server

# Backup current files
echo "Creating backups..."
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/$timestamp
cp -r data/web-ui/public/index.html backups/$timestamp/ 2>/dev/null || true
cp -r data/web-ui/server.js backups/$timestamp/ 2>/dev/null || true
cp docker-compose.yml backups/$timestamp/ 2>/dev/null || true

# Copy updated files
echo "Updating files..."
cp index.html data/web-ui/public/
cp server.js data/web-ui/
cp docker-compose.yml .

# Set proper permissions
echo "Setting permissions..."
chown -R 1000:1000 data/web-ui

# Restart web-ui container
echo "Restarting web-ui container..."
docker-compose restart web-ui

echo "Update complete!"
echo "You can access the updated web UI at http://your-server-ip"
echo "Note: If you experience any issues, backups are available in /opt/minecraft-server/backups/$timestamp/" 
