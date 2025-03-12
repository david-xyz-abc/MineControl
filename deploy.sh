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
    curl

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/minecraft-server
cd /opt/minecraft-server
mkdir -p data/minecraft
mkdir -p data/web-ui/public

# Remove default Nginx configuration
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/default.conf

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  minecraft:
    image: itzg/minecraft-server
    container_name: mc-server
    ports:
      - "25565:25565"
    environment:
      - EULA=TRUE
      - MEMORY=2G
      - TYPE=PAPER
      - ENABLE_RCON=true
      - RCON_PASSWORD=your_secure_password
    volumes:
      - ./data/minecraft:/data
    restart: unless-stopped
    tty: true
    stdin_open: true

  web-ui:
    image: node:16-alpine
    container_name: mc-web-ui
    working_dir: /app
    volumes:
      - ./data/web-ui:/app
    ports:
      - "3000:3000"
    command: sh -c "npm install && npm start"
    restart: unless-stopped
    depends_on:
      - minecraft
EOL

# Create nginx configuration
cat > /etc/nginx/conf.d/minecraft.conf << 'EOL'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOL

# Test Nginx configuration
nginx -t || {
    echo "Nginx configuration test failed"
    exit 1
}

# Create package.json
cat > data/web-ui/package.json << 'EOL'
{
  "name": "minecraft-web-ui",
  "version": "1.0.0",
  "description": "Web UI for Minecraft Server Control",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.17.1",
    "rcon-client": "^4.2.3",
    "socket.io": "^4.4.1"
  }
}
EOL

# Create server.js
cat > data/web-ui/server.js << 'EOL'
const express = require('express');
const { Rcon } = require('rcon-client');
const path = require('path');

const app = express();
const port = 3000;

app.use(express.static('public'));
app.use(express.json());

const rcon = new Rcon({
    host: "localhost",
    port: 25575,
    password: "your_secure_password"
});

async function connectRcon() {
    try {
        await rcon.connect();
        console.log('Connected to Minecraft RCON');
    } catch (error) {
        console.error('Failed to connect to RCON:', error);
    }
}

app.get('/api/status', async (req, res) => {
    try {
        const response = await rcon.send('list');
        res.json({ status: 'online', players: response });
    } catch (error) {
        res.json({ status: 'offline', error: error.message });
    }
});

app.post('/api/command', async (req, res) => {
    const { command } = req.body;
    try {
        const response = await rcon.send(command);
        res.json({ success: true, response });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
    console.log(`Web UI running on port ${port}`);
    connectRcon();
});
EOL

# Create index.html
cat > data/web-ui/public/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minecraft Server Control</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .status {
            margin-bottom: 20px;
            padding: 10px;
            border-radius: 5px;
        }
        .online {
            background-color: #d4edda;
            color: #155724;
        }
        .offline {
            background-color: #f8d7da;
            color: #721c24;
        }
        input[type="text"] {
            width: 70%;
            padding: 8px;
            margin-right: 10px;
        }
        button {
            padding: 8px 15px;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 3px;
            cursor: pointer;
        }
        button:hover {
            background-color: #0056b3;
        }
        #response {
            margin-top: 20px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Minecraft Server Control</h1>
        <div id="serverStatus" class="status">Checking server status...</div>
        
        <h2>Server Control</h2>
        <div>
            <input type="text" id="command" placeholder="Enter server command...">
            <button onclick="sendCommand()">Send Command</button>
        </div>
        <div id="response"></div>
    </div>

    <script>
        function checkStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    const statusDiv = document.getElementById('serverStatus');
                    statusDiv.className = `status ${data.status}`;
                    statusDiv.textContent = `Server Status: ${data.status.toUpperCase()} ${data.players || ''}`;
                })
                .catch(error => {
                    console.error('Error:', error);
                    const statusDiv = document.getElementById('serverStatus');
                    statusDiv.className = 'status offline';
                    statusDiv.textContent = 'Server Status: ERROR';
                });
        }

        function sendCommand() {
            const commandInput = document.getElementById('command');
            const command = commandInput.value;
            
            fetch('/api/command', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ command }),
            })
            .then(response => response.json())
            .then(data => {
                const responseDiv = document.getElementById('response');
                responseDiv.textContent = data.success ? data.response : `Error: ${data.error}`;
                commandInput.value = '';
            })
            .catch(error => {
                console.error('Error:', error);
                const responseDiv = document.getElementById('response');
                responseDiv.textContent = 'Error: Failed to send command';
            });
        }

        checkStatus();
        setInterval(checkStatus, 30000);
    </script>
</body>
</html>
EOL

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
echo "IMPORTANT: Remember to change the RCON password in both docker-compose.yml and data/web-ui/server.js" 
