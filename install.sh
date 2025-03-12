#!/bin/bash

# Update package list and install nginx
sudo apt update
sudo apt install -y nginx

# Get the server's IP address
IP_ADDRESS=$(ip addr show | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)

# Output the access information
echo "Nginx installation complete!"
echo "You can access the default page at: http://$IP_ADDRESS/"
