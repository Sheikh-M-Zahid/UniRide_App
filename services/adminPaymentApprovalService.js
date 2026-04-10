const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

const normalizeStatusFilter = (status) => {
  if (!status) return 'all';

  const value = String(status).trim().toLowerCase();

  if (['all', 'pending', 'confirmed', 'declined'].includes(value)) {
    return value;
  }

  return 'all';
};

const mapPaymentRow = (row, adminNameMap) => ({
  paymentDbId: row.transaction_id,
  transactionId: row.reference_id,
  dateTime: row.created_at,
  userId: row.user_id,
  userName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
  userType: row.user_type,
  paymentMethod: row.method,
  amount: Number(row.amount || 0),
  status: row.status,
  actionAdminName: row.action_admin_id
    ? adminNameMap.get(row.action_admin_id) || null
    : null,
});

const getPaymentRequests = async ({ search, status, page = 1, limit = 20 }) => {
  const safePage = page > 0 ? page : 1;
  const safeLimit = limit > 0 && limit <= 100 ? limit : 20;
  const offset = (safePage - 1) * safeLimit;

  const normalizedStatus = normalizeStatusFilter(status);

  const params = [];
  let whereClause = `
    WHERE t.type = 'credit'
      AND t.method IN ('bkash', 'nagad', 'bKash', 'Nagad')
  `;

  if (search && search.trim()) {
    params.push(`%${search.trim()}%`);
    whereClause += ` AND COALESCE(t.reference_id, '') ILIKE $${params.length}`;
  }

  if (normalizedStatus !== 'all') {
    params.push(normalizedStatus);
    whereClause += ` AND LOWER(t.status) = $${params.length}`;
  }

  const summaryQuery = `
    SELECT
      COUNT(*) FILTER (WHERE LOWER(status) = 'pending')::int AS pending,
      COUNT(*) FILTER (WHERE LOWER(status) = 'confirmed')::int AS confirmed,
      COUNT(*) FILTER (WHERE LOWER(status) = 'declined')::int AS declined
    FROM transactions
    WHERE type = 'credit'
      AND method IN ('bkash', 'nagad', 'bKash', 'Nagad')
  `;

  const listParams = [...params, safeLimit, offset];

  const listQuery = `
    SELECT
      t.transaction_id,
      t.user_id,
      t.amount,
      t.type,
      t.method,
      t.reference_id,
      t.status,
      t.created_at,
      t.action_admin_id,
      u.first_name,
      u.last_name,
      CASE
        WHEN EXISTS (
          SELECT 1
          FROM vehicles v
          WHERE v.user_id = u.user_id
        ) THEN 'Rider'
        ELSE 'Passenger'
      END AS user_type
    FROM transactions t
    JOIN users u
      ON u.user_id = t.user_id
    ${whereClause}
    ORDER BY t.created_at DESC
    LIMIT $${listParams.length - 1}
    OFFSET $${listParams.length}
  `;

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM transactions t
    JOIN users u
      ON u.user_id = t.user_id
    ${whereClause}
  `;

  const [summaryRes, listRes, countRes] = await Promise.all([
    rideDb.query(summaryQuery),
    rideDb.query(listQuery, listParams),
    rideDb.query(countQuery, params),
  ]);

  const adminIds = [
    ...new Set(
      listRes.rows
        .map((row) => row.action_admin_id)
        .filter(Boolean)
    ),
  ];

  let adminNameMap = new Map();

  if (adminIds.length > 0) {
    const adminRes = await ewuAdminDb.query(
      `SELECT id, name
       FROM admins
       WHERE id = ANY($1::uuid[])`,
      [adminIds]
    );

    adminNameMap = new Map(
      adminRes.rows.map((admin) => [admin.id, admin.name])
    );
  }

  return {
    summary: {
      pending: Number(summaryRes.rows[0]?.pending || 0),
      confirmed: Number(summaryRes.rows[0]?.confirmed || 0),
      declined: Number(summaryRes.rows[0]?.declined || 0),
    },
    items: listRes.rows.map((row) => mapPaymentRow(row, adminNameMap)),
    pagination: {
      page: safePage,
      limit: safeLimit,
      total: Number(countRes.rows[0]?.total || 0),
      hasMore:
        offset + listRes.rows.length < Number(countRes.rows[0]?.total || 0),
    },
    filters: {
      search,
      status: normalizedStatus,
    },
  };
};

const confirmPayment = async ({ paymentDbId, adminId }) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const txRes = await client.query(
      `SELECT
          t.transaction_id,
          t.user_id,
          t.amount,
          t.type,
          t.method,
          t.reference_id,
          t.status,
          u.due_balance,
          u.account_status,
          u.first_name,
          u.last_name
       FROM transactions t
       JOIN users u
         ON u.user_id = t.user_id
       WHERE t.transaction_id = $1
       FOR UPDATE`,
      [paymentDbId]
    );

    if (!txRes.rows.length) {
      throw new Error('Payment request not found.');
    }

    const tx = txRes.rows[0];

    if (String(tx.status).toLowerCase() !== 'pending') {
      throw new Error('Only pending payment requests can be confirmed.');
    }

    const updatedTransactionRes = await client.query(
      `UPDATE transactions
       SET status = 'confirmed',
           action_admin_id = $2,
           action_at = CURRENT_TIMESTAMP
       WHERE transaction_id = $1
       RETURNING *`,
      [paymentDbId, adminId]
    );

    const newDueBalance = Math.max(
      Number(tx.due_balance || 0) - Number(tx.amount || 0),
      0
    );

    const shouldActivate = newDueBalance <= 0;

    const updatedUserRes = await client.query(
      `UPDATE users
       SET due_balance = $2,
           account_status = CASE
             WHEN $3 = true THEN 'active'
             ELSE account_status
           END
       WHERE user_id = $1
       RETURNING user_id, due_balance, account_status`,
      [tx.user_id, newDueBalance, shouldActivate]
    );

    await client.query('COMMIT');

    return {
      paymentDbId: updatedTransactionRes.rows[0].transaction_id,
      transactionId: updatedTransactionRes.rows[0].reference_id,
      status: updatedTransactionRes.rows[0].status,
      amount: Number(updatedTransactionRes.rows[0].amount || 0),
      userId: updatedUserRes.rows[0].user_id,
      updatedDueBalance: Number(updatedUserRes.rows[0].due_balance || 0),
      accountStatus: updatedUserRes.rows[0].account_status,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const declinePayment = async ({ paymentDbId, adminId }) => {
  const result = await rideDb.query(
    `UPDATE transactions
     SET status = 'declined',
         action_admin_id = $2,
         action_at = CURRENT_TIMESTAMP
     WHERE transaction_id = $1
       AND LOWER(status) = 'pending'
     RETURNING *`,
    [paymentDbId, adminId]
  );

  if (!result.rows.length) {
    throw new Error('Pending payment request not found or already processed.');
  }

  return {
    paymentDbId: result.rows[0].transaction_id,
    transactionId: result.rows[0].reference_id,
    status: result.rows[0].status,
    amount: Number(result.rows[0].amount || 0),
  };
};

module.exports = {
  getPaymentRequests,
  confirmPayment,
  declinePayment,
};