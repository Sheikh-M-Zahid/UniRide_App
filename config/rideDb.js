const { Pool } = require('pg');
require('dotenv').config();

const rideDb = new Pool({
  host: process.env.DB_RIDE_HOST,
  port: process.env.DB_RIDE_PORT,
  user: process.env.DB_RIDE_USER,
  password: process.env.DB_RIDE_PASSWORD,
  database: process.env.DB_RIDE_NAME,
});

rideDb.on('connect', () => {
  console.log('Connected to ride_sharing_db');
});

rideDb.on('error', (err) => {
  console.error('ride_sharing_db error:', err.message);
});

module.exports = rideDb;