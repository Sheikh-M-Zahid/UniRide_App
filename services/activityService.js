const rideDb = require('../config/rideDb');

const getMyActivity = async (userId, sort = 'new') => {
  // ===== USER CHECK =====
  const userResult = await rideDb.query(
    `SELECT user_id, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  if (String(userResult.rows[0].account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  // ===== 1. RIDE JOIN ACTIVITY =====
  const rideJoinResult = await rideDb.query(
    `SELECT
        r.start_location,
        r.destination,
        rp.created_at
     FROM ride_participants rp
     INNER JOIN rides r ON rp.ride_id = r.ride_id
     WHERE rp.passenger_id = $1`,
    [userId]
  );

  const rideJoinActivities = rideJoinResult.rows.map((row) => ({
    type: 'ride_join',
    title: 'Joined a ride',
    subtitle: `${row.start_location || 'Unknown'} → ${row.destination || 'Unknown'}`,
    activity_time: row.created_at,
    display_text: `Joined a ride | ${row.start_location} → ${row.destination}`,
  }));

  // ===== 2. RIDE CREATE ACTIVITY =====
  const rideCreateResult = await rideDb.query(
    `SELECT
        start_location,
        destination,
        created_at
     FROM rides
     WHERE rider_id = $1`,
    [userId]
  );

  const rideCreateActivities = rideCreateResult.rows.map((row) => ({
    type: 'ride_create',
    title: 'Created a ride',
    subtitle: `${row.start_location || 'Unknown'} → ${row.destination || 'Unknown'}`,
    activity_time: row.created_at,
    display_text: `Created a ride | ${row.start_location} → ${row.destination}`,
  }));

  // ===== 3. SEND ITEM =====
  const sendItemResult = await rideDb.query(
    `SELECT
        item_type,
        delivery_fee,
        created_at
     FROM send_items
     WHERE receiver_id = $1`,
    [userId]
  );

  const sendItemActivities = sendItemResult.rows.map((row) => ({
    type: 'send_item',
    title: 'Item received',
    subtitle: `${row.item_type} | Fee: BDT ${row.delivery_fee || 0}`,
    activity_time: row.created_at,
    display_text: `Item received | ${row.item_type}`,
  }));

  // ===== 4. TRANSACTIONS =====
  const transactionResult = await rideDb.query(
    `SELECT
        type,
        reference_id,
        amount,
        created_at
     FROM transactions
     WHERE user_id = $1`,
    [userId]
  );

  const transactionActivities = transactionResult.rows.map((row) => ({
    type: 'payment',
    title: 'Payment submitted',
    subtitle: `${row.type} | Ref: ${row.reference_id}`,
    activity_time: row.created_at,
    display_text: `Payment | ${row.type} | Ref: ${row.reference_id}`,
  }));

  // ===== 5. COMPANY SHARING =====
  const companyResult = await rideDb.query(
    `SELECT
        cs.start_location,
        cs.destination,
        cp.created_at
     FROM company_participants cp
     INNER JOIN company_sharing_sessions cs
       ON cp.session_id = cs.session_id
     WHERE cp.user_id = $1`,
    [userId]
  );

  const companyActivities = companyResult.rows.map((row) => ({
    type: 'company_sharing',
    title: 'Joined company sharing',
    subtitle: `${row.start_location} → ${row.destination}`,
    activity_time: row.created_at,
    display_text: `Company sharing | ${row.start_location} → ${row.destination}`,
  }));

  // ===== MERGE ALL =====
  let allActivities = [
    ...rideJoinActivities,
    ...rideCreateActivities,
    ...sendItemActivities,
    ...transactionActivities,
    ...companyActivities,
  ];

  // ===== SORT =====
  allActivities.sort((a, b) => {
    const t1 = new Date(a.activity_time).getTime();
    const t2 = new Date(b.activity_time).getTime();

    return sort === 'old' ? t1 - t2 : t2 - t1;
  });

  // ===== LIMIT (FAST UI) =====
  return allActivities.slice(0, 20);
};

module.exports = {
  getMyActivity,
};