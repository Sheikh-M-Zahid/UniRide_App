const rideDb = require('../config/rideDb');

const getWalletSummary = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT user_id, due_balance, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const user = userResult.rows[0];

  if (String(user.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const offersResult = await rideDb.query(
    `SELECT COUNT(*)::int AS count
     FROM offers
     WHERE CURRENT_DATE BETWEEN start_date AND end_date`
  );

  return {
    dueAmount: Number(user.due_balance || 0),
    activePromotionsCount: offersResult.rows[0].count,
  };
};

const payDue = async (userId, payload) => {
  const { method, reference_id } = payload;

  if (!method || !reference_id || !String(reference_id).trim()) {
    throw new Error('Invalid payment request.');
  }

  if (!['bKash', 'Nagad'].includes(method)) {
    throw new Error('Invalid payment request.');
  }

  const trimmedReferenceId = String(reference_id).trim();
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const userResult = await client.query(
      `SELECT user_id, due_balance, account_status
       FROM users
       WHERE user_id = $1
       FOR UPDATE`,
      [userId]
    );

    if (userResult.rowCount === 0) {
      throw new Error('User account not found.');
    }

    const user = userResult.rows[0];

    if (String(user.account_status).toLowerCase() !== 'active') {
      throw new Error('Your account is not active.');
    }

    const currentDue = Number(user.due_balance || 0);

    if (currentDue <= 0) {
      throw new Error('No due payment found.');
    }

    const duplicateResult = await client.query(
      `SELECT transaction_id
       FROM transactions
       WHERE reference_id = $1
       LIMIT 1`,
      [trimmedReferenceId]
    );

    if (duplicateResult.rowCount > 0) {
      throw new Error('This transaction ID has already been used.');
    }

    await client.query(
      `INSERT INTO transactions (
        user_id,
        amount,
        type,
        method,
        reference_id,
        status
      )
      VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        userId,
        currentDue,
        'credit',
        method,
        trimmedReferenceId,
        'paid',
      ]
    );

    await client.query(
      `UPDATE users
       SET due_balance = 0
       WHERE user_id = $1`,
      [userId]
    );

    await client.query('COMMIT');

    return {
      paidAmount: currentDue,
      method,
      reference_id: trimmedReferenceId,
      remainingDue: 0,
    };
  } catch (error) {
    await client.query('ROLLBACK');

    if (error.code === '23505') {
      throw new Error('This transaction ID has already been used.');
    }

    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  getWalletSummary,
  payDue,
};