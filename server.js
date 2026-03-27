require('dotenv').config();
const app = require('./app');
const ewuAdminDb = require('./config/ewuAdminDb');
const rideDb = require('./config/rideDb');

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await ewuAdminDb.query('SELECT 1');
    await rideDb.query('SELECT 1');

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();