const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const staticPath = path.join(__dirname, '../public');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(staticPath));

// Health Check Route
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'ShopSmart Backend is running',
    timestamp: new Date().toISOString(),
  });
});

// Serve React app for non-API routes (SPA fallback)
app.get(/^\/(?!api).*/, (req, res) => {
  res.sendFile(path.join(staticPath, 'index.html'));
});

module.exports = app;
