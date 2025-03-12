const express = require('express');
const { Rcon } = require('rcon-client');
const path = require('path');

const app = express();
const port = 3000;
const debug = true;

// Serve static files
app.use(express.static('public'));
app.use(express.json());

// RCON configuration
const rcon = new Rcon({
    host: "minecraft",
    port: 25575,
    password: "your_secure_password"
});

// Connect to RCON
async function connectRcon() {
    try {
        await rcon.connect();
        console.log('Connected to Minecraft RCON');
    } catch (error) {
        console.error('Failed to connect to RCON:', error);
        // Try to reconnect after 5 seconds
        setTimeout(connectRcon, 5000);
    }
}

// Add reconnection logic
rcon.on('end', () => {
    console.log('RCON connection closed, attempting to reconnect...');
    setTimeout(connectRcon, 5000);
});

// API endpoints
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

// Serve the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server
app.listen(port, () => {
    console.log(`Web UI running on port ${port}`);
    connectRcon();
}); 
