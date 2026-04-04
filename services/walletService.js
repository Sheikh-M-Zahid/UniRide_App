const rideDb = require('../config/rideDb');

/* =========================
   WALLET SUMMARY
========================= */
const getWalletSummary = async (userId) => {
  const userRes = await rideDb.query(
    `SELECT due_balance FROM users WHERE user_id = $1`,
    [userId]
  );

  const latestPayment = await rideDb.query(
    `
    SELECT status
    FROM transactions
    WHERE user_id = $1 AND type = 'credit'
    ORDER BY created_at DESC
    LIMIT 1
  `,
    [userId]
  );

  return {
    dueAmount: Number(userRes.rows[0].due_balance || 0),
    activePromotionsCount: 0,
    bkashNumber: '017XXXXXXXX',
    nagadNumber: '018XXXXXXXX',
    latestPaymentStatus: latestPayment.rows[0]?.status || null,
  };
};

/* =========================
   ADD DUE (SYSTEM)
========================= */
const addDue = async ({ userId, amount, referenceId, method }) => {
  await rideDb.query(
    `
    UPDATE users
    SET due_balance = due_balance + $1
    WHERE user_id = $2
  `,
    [amount, userId]
  );

  await rideDb.query(
    `
    INSERT INTO transactions
    (user_id, amount, type, method, reference_id, status)
    VALUES ($1, $2, 'debit', $3, $4, 'completed')
  `,
    [userId, amount, method, referenceId]
  );
};

/* =========================
   USER PAYMENT SUBMIT
========================= */
const submitPayment = async ({ userId, method, transactionId, amount }) => {
  await rideDb.query(
    `
    INSERT INTO transactions
    (user_id, amount, type, method, reference_id, status)
    VALUES ($1, $2, 'credit', $3, $4, 'pending')
  `,
    [userId, amount, method, transactionId]
  );

  return {
    method,
    transactionId,
    amount,
    status: 'pending',
  };
};

/* =========================
   ADMIN: GET PENDING
========================= */
const getPendingPayments = async () => {
  const res = await rideDb.query(`
    SELECT *
    FROM transactions
    WHERE type = 'credit' AND status = 'pending'
    ORDER BY created_at DESC
  `);

  return res.rows;
};

/* =========================
   ADMIN: VERIFY PAYMENT
========================= */
const verifyPayment = async (transactionId) => {
  const txRes = await rideDb.query(
    `SELECT * FROM transactions WHERE transaction_id = $1`,
    [transactionId]
  );

  const tx = txRes.rows[0];

  if (!tx) throw new Error('Transaction not found');

  await rideDb.query(
    `
    UPDATE transactions
    SET status = 'completed'
    WHERE transaction_id = $1
  `,
    [transactionId]
  );

  await rideDb.query(
    `
    UPDATE users
    SET due_balance = GREATEST(due_balance - $1, 0),
        account_status = 'active'
    WHERE user_id = $2
  `,
    [tx.amount, tx.user_id]
  );

  return { transactionId, status: 'completed' };
};

/* =========================
   ADMIN: REJECT PAYMENT
========================= */
const rejectPayment = async (transactionId) => {
  await rideDb.query(
    `
    UPDATE transactions
    SET status = 'rejected'
    WHERE transaction_id = $1
  `,
    [transactionId]
  );

  return { transactionId, status: 'rejected' };
};

module.exports = {
  getWalletSummary,
  addDue,
  submitPayment,
  getPendingPayments,
  verifyPayment,
  rejectPayment,
};