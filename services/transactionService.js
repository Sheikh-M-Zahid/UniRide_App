const rideDb = require('../config/rideDb');

const createPaymentRecord = async (userId, payload) => {
  const { amount, type, method, reference_id, status } = payload;

  const result = await rideDb.query(
    `INSERT INTO transactions (
      user_id, amount, type, method, reference_id, status
    )
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *`,
    [userId, amount, type, method, reference_id, status || 'Pending']
  );

  return result.rows[0];
};

const listMyTransactions = async (userId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM transactions
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

const fetchDueBalance = async (userId) => {
  const result = await rideDb.query(
    `SELECT due_balance FROM users WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

const walletPaymentStatus = async (userId) => {
  const result = await rideDb.query(
    `SELECT wallet_bkash, due_balance, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

module.exports = {
  createPaymentRecord,
  listMyTransactions,
  fetchDueBalance,
  walletPaymentStatus,
};