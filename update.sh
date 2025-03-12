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

# Update index.html
echo "Updating index.html..."
cat > data/web-ui/public/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minecraft Server Control Panel</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #2c3e50;
            color: #ecf0f1;
        }
        /* ... rest of the CSS ... */
EOL

# Continue with the rest of the HTML content
cat >> data/web-ui/public/index.html << 'EOL'
        .container {
            max-width: 1200px;
            margin-top: 2rem;
        }
        /* ... rest of the styles ... */
    </style>
</head>
<body>
    <!-- ... rest of the HTML ... -->
</body>
</html>
EOL

# Update server.js
echo "Updating server.js..."
cat > data/web-ui/server.js << 'EOL'
const express = require('express');
const { Rcon } = require('rcon-client');
const path = require('path');

const app = express();
const port = 3000;
const debug = true;

app.use(express.static('public'));
app.use(express.json());

const rcon = new Rcon({
    host: "minecraft",
    port: 25575,
    password: "your_secure_password"
});

async function connectRcon() {
    try {
        await rcon.connect();
        console.log('Connected to Minecraft RCON');
    } catch (error) {
        console.error('Failed to connect to RCON:', error);
        setTimeout(connectRcon, 5000);
    }
}

rcon.on('end', () => {
    console.log('RCON connection closed, attempting to reconnect...');
    setTimeout(connectRcon, 5000);
});

app.get('/api/status', async (req, res) => {
    if (debug) console.log('Status check requested');
    try {
        if (!rcon.connected) {
            if (debug) console.log('RCON not connected, attempting to connect...');
            await connectRcon();
        }
        const response = await rcon.send('list');
        if (debug) console.log('RCON response:', response);
        res.json({ status: 'online', players: response });
    } catch (error) {
        if (debug) console.error('Status check error:', error);
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

# Update docker-compose.yml
echo "Updating docker-compose.yml..."
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  minecraft:
    image: itzg/minecraft-server
    container_name: mc-server
    ports:
      - "25565:25565"
      - "25575:25575"
    environment:
      - EULA=TRUE
      - MEMORY=2G
      - TYPE=PAPER
      - ENABLE_RCON=true
      - RCON_PASSWORD=your_secure_password
      - RCON_PORT=25575
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
    environment:
      - MINECRAFT_HOST=minecraft
      - RCON_PASSWORD=your_secure_password

networks:
  default:
    name: minecraft-network
EOL

# Set proper permissions
echo "Setting permissions..."
chown -R 1000:1000 data/web-ui

# Restart web-ui container
echo "Restarting web-ui container..."
docker-compose restart web-ui

echo "Update complete!"
echo "You can access the updated web UI at http://your-server-ip"
echo "Note: If you experience any issues, backups are available in /opt/minecraft-server/backups/$timestamp/" 
