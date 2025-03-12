#!/bin/bash

# Update package list and install nginx
sudo apt update
sudo apt install -y nginx php-fpm

# Get the server's IP address
IP_ADDRESS=$(ip addr show | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)

# Create minecontrol.php file
sudo bash -c "cat > /var/www/html/minecontrol.php" << 'EOF'
<?php
echo "This is Minecontrol page running at IP: " . $_SERVER['SERVER_ADDR'];
?>
EOF

# Set proper permissions
sudo chown www-data:www-data /var/www/html/minecontrol.php
sudo chmod 644 /var/www/html/minecontrol.php

# Configure Nginx to serve PHP files
sudo bash -c "cat > /etc/nginx/sites-available/default" << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index minecontrol.php index.php index.html index.htm;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Test Nginx configuration and reload
sudo nginx -t
sudo systemctl reload nginx

# Output the access information
echo "Nginx and PHP installation complete!"
echo "You can access minecontrol.php at: http://$IP_ADDRESS/minecontrol.php"
