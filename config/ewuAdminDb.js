const { Pool } = require('pg');
require('dotenv').config();

const ewuAdminDb = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
      }
    : {
        host: process.env.DB_EWU_HOST,
        port: process.env.DB_EWU_PORT,
        user: process.env.DB_EWU_USER,
        password: process.env.DB_EWU_PASSWORD,
        database: process.env.DB_EWU_NAME,
      }
);

ewuAdminDb.on('connect', () => {
  console.log('Connected to DB (ewuAdminDb)');
});

ewuAdminDb.on('error', (err) => {
  console.error('DB error (ewuAdminDb):', err.message);
});

module.exports = ewuAdminDb;
