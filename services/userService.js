const rideDb = require('../config/rideDb');

const getProfile = async (userId) => {
  const result = await rideDb.query(
    `SELECT user_id, university_email, first_name, last_name, phone, recovery_phone,
            gender, blood_group, home_address, hostel_address, campus_address,
            activity_status, profile_picture, wallet_bkash, account_status,
            due_balance, rating, rating_count, rating_sum, created_at, rider
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

const updateProfile = async (userId, payload) => {
  const allowedFields = [
    'first_name',
    'last_name',
    'phone',
    'recovery_phone',
    'gender',
    'blood_group',
    'home_address',
    'hostel_address',
    'campus_address',
    'activity_status',
    'profile_picture',
    'wallet_bkash',
  ];

  const updates = [];
  const values = [];
  let count = 1;

  for (const key of allowedFields) {
    if (payload[key] !== undefined) {
      updates.push(`${key} = $${count}`);
      values.push(payload[key]);
      count++;
    }
  }

  if (updates.length === 0) {
    throw new Error('No valid fields to update.');
  }

  values.push(userId);

  const result = await rideDb.query(
    `UPDATE users
     SET ${updates.join(', ')}
     WHERE user_id = $${count}
     RETURNING user_id, university_email, first_name, last_name, phone,
               recovery_phone, gender, blood_group, home_address, hostel_address,
               campus_address, activity_status, profile_picture, wallet_bkash,
               account_status, due_balance, rating, rating_count, rating_sum, created_at, rider`,
    values
  );

  return result.rows[0];
};

const getRole = async (userId) => {
  const result = await rideDb.query(
    `SELECT role FROM user_roles WHERE user_id = $1`,
    [userId]
  );

  return result.rows;
};

const getAccountStatus = async (userId) => {
  const result = await rideDb.query(
    `SELECT account_status, activity_status FROM users WHERE user_id = $1`,
    [userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

const getWalletInfo = async (userId) => {
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

const getRoleOptions = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT user_id, university_email, account_status, activity_status, rider
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User not found.');
  }

  const user = userResult.rows[0];

  const vehicleCountResult = await rideDb.query(
    `SELECT COUNT(*)::int AS vehicle_count
     FROM vehicles
     WHERE user_id = $1`,
    [userId]
  );

  const vehicleCount = vehicleCountResult.rows[0].vehicle_count;
  const riderFlag = user.rider ? String(user.rider).toLowerCase() : 'no';

  const isAccountActive =
    user.account_status &&
    String(user.account_status).toLowerCase() === 'active';

  const riderAllowed = riderFlag === 'yes' || vehicleCount > 0;
  const passengerAllowed = isAccountActive;

  let riderReason = null;

  if (!isAccountActive) {
    riderReason = 'Your account is not active.';
  } else if (!riderAllowed) {
    riderReason = 'You are not registered as a rider yet. Please add a vehicle first.';
  }

  return {
    email: user.university_email,
    accountStatus: user.account_status,
    activityStatus: user.activity_status,
    riderFlag,
    vehicleCount,
    passengerAllowed,
    riderAllowed,
    riderReason,
  };
};

module.exports = {
  getProfile,
  updateProfile,
  getRole,
  getAccountStatus,
  getWalletInfo,
  getRoleOptions,
};