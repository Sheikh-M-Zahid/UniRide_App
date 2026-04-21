const { Pool } = require('pg');
require('dotenv').config();

const rideDb = new Pool(
  process.env.DATABASE_RIDE_URL
    ? {
        connectionString: process.env.DATABASE_RIDE_URL,
        ssl: { rejectUnauthorized: false },
      }
    : {
        host: process.env.DB_RIDE_HOST,
        port: process.env.DB_RIDE_PORT,
        user: process.env.DB_RIDE_USER,
        password: process.env.DB_RIDE_PASSWORD,
        database: process.env.DB_RIDE_NAME,
      }
);

rideDb.on('connect', () => {
  console.log('Connected to DB (rideDb)');
});

rideDb.on('error', (err) => {
  console.error('DB error (rideDb):', err.message);
});

module.exports = rideDb;
