#!/bin/bash

# Exit on error
set -e

echo "Starting Minecraft Server Deployment..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y \
    docker.io \
    docker-compose \
    nginx \
    curl \
    git

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Create directory structure and clone repository
echo "Cloning repository and setting up directory structure..."
mkdir -p /opt/minecraft-server
cd /opt/minecraft-server

# Clone the repository
git clone https://github.com/david-xyz-abc/MineControl.git .

# Create data directories if they don't exist
mkdir -p data/minecraft
mkdir -p data/web-ui

# Copy web UI files
mkdir -p data/web-ui/public
cp -r web-ui/* data/web-ui/

# Copy configuration files
echo "Setting up configuration files..."
cp nginx.conf /etc/nginx/conf.d/minecraft.conf

# Set proper permissions
chown -R 1000:1000 data/minecraft

# Start the services
echo "Starting services..."
docker-compose up -d

# Configure and restart Nginx
systemctl enable nginx
systemctl restart nginx

echo "Deployment complete!"
echo "You can access the web UI at http://your-server-ip"
echo "Minecraft server is running on default port 25565" 
