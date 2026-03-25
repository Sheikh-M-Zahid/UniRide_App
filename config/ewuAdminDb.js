const { Pool } = require('pg');
require('dotenv').config();

const ewuAdminDb = new Pool({
  host: process.env.DB_EWU_HOST,
  port: process.env.DB_EWU_PORT,
  user: process.env.DB_EWU_USER,
  password: process.env.DB_EWU_PASSWORD,
  database: process.env.DB_EWU_NAME,
});

ewuAdminDb.on('connect', () => {
  console.log('Connected to ewu_admin_db');
});

ewuAdminDb.on('error', (err) => {
  console.error('ewu_admin_db error:', err.message);
});

module.exports = ewuAdminDb;