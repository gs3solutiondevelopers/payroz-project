const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const { sequelize } = require('./src/config/db');
const { seedDatabase } = require('./src/config/seed');
const apiRoutes = require('./src/routes');
const { autoCheckFailedTransactions } = require('./src/services/automation');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static PDF receipts placeholder or standard static directory if needed
app.use('/receipts', express.static('public/receipts'));

// Routes
app.use('/api', apiRoutes);

// Simple root check
app.get('/', (req, res) => {
  res.json({ message: 'PAYROZ B2C API Backend is running.' });
});

// Sync Database and Start Server
async function startServer() {
  try {
    // Seed database on start (DISABLED FOR PRODUCTION)
    // await seedDatabase();

    app.listen(PORT, () => {
      console.log(`=========================================`);
      console.log(`PAYROZ SERVER IS RUNNING ON PORT: ${PORT}`);
      console.log(`API BASE PATH: http://localhost:${PORT}/api`);
      console.log(`=========================================`);

      // Start the Smart Automation background checker (runs every 15 seconds)
      console.log('[AUTOMATION] Starting Pending Transaction Daemon (every 15s)...');
      setInterval(async () => {
        await autoCheckFailedTransactions();
      }, 15000);
    });
  } catch (err) {
    console.error('Failed to sync DB and start server:', err);
  }
}

startServer();
