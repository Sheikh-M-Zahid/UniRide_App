const path = require('path');
const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');

/* =========================
   GET MY PROFILE
========================= */
const getMyProfile = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT
        user_id,
        first_name,
        last_name,
        university_email,
        phone,
        recovery_phone,
        emergency_phone,
        gender,
        blood_group,
        date_of_birth,
        home_address,
        hostel_address,
        campus_address,
        profile_picture,
        account_status,
        activity_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User not found.');
  }

  const user = userResult.rows[0];

  const ewuResult = await ewuAdminDb.query(
    `SELECT occupation
     FROM ewu_users
     WHERE university_email = $1`,
    [user.university_email]
  );

  const occupation =
    ewuResult.rowCount > 0 ? ewuResult.rows[0].occupation : null;

  return {
    first_name: user.first_name,
    last_name: user.last_name,
    occupation,
    university_email: user.university_email,
    phone: user.phone,
    recovery_phone: user.recovery_phone,
    emergency_phone: user.emergency_phone,
    gender: user.gender,
    blood_group: user.blood_group,
    date_of_birth: user.date_of_birth,
    home_address: user.home_address,
    hostel_address: user.hostel_address,
    campus_address: user.campus_address,
    profile_picture: user.profile_picture,
    account_status: user.account_status,
    activity_status: user.activity_status,
  };
};

/* =========================
   UPDATE PROFILE
========================= */
const updateMyProfile = async (userId, payload) => {
  const {
    phone,
    recovery_phone,
    emergency_phone,
    gender,
    date_of_birth,
    home_address,
    hostel_address,
    campus_address,
    blood_group,
  } = payload;

  const currentResult = await rideDb.query(
    `SELECT blood_group
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (currentResult.rowCount === 0) {
    throw new Error('User not found.');
  }

  const currentUser = currentResult.rows[0];

  if (
    !phone ||
    !emergency_phone ||
    !gender ||
    !date_of_birth ||
    !home_address ||
    !hostel_address
  ) {
    throw new Error('Please provide all required profile fields.');
  }

  if (!['male', 'female'].includes(String(gender).toLowerCase())) {
    throw new Error('Gender must be male or female.');
  }

  const updates = [
    `phone = $1`,
    `recovery_phone = $2`,
    `emergency_phone = $3`,
    `gender = $4`,
    `date_of_birth = $5`,
    `home_address = $6`,
    `hostel_address = $7`,
    `campus_address = $8`,
  ];

  const values = [
    phone,
    recovery_phone,
    emergency_phone,
    gender.toLowerCase(),
    date_of_birth,
    home_address,
    hostel_address,
    campus_address || null,
  ];

  let paramIndex = 9;

  if (!currentUser.blood_group && blood_group) {
    updates.push(`blood_group = $${paramIndex}`);
    values.push(blood_group);
    paramIndex++;
  }

  values.push(userId);

  await rideDb.query(
    `UPDATE users
     SET ${updates.join(', ')}
     WHERE user_id = $${paramIndex}`,
    values
  );

  return true;
};

/* =========================
   UPDATE PROFILE PICTURE
========================= */
const updateProfilePicture = async (userId, file) => {
  if (!file) {
    throw new Error('Profile picture file is required.');
  }

  const relativePath = `/uploads/profile-pictures/${path.basename(file.path)}`;

  const result = await rideDb.query(
    `UPDATE users
     SET profile_picture = $1
     WHERE user_id = $2
     RETURNING profile_picture`,
    [relativePath, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return {
    profile_picture: result.rows[0].profile_picture,
    profile_picture_url: `${process.env.BASE_URL}${result.rows[0].profile_picture}`,
  };
};

/* =========================
   ROLE OPTIONS (IMPORTANT FOR YOUR APP)
========================= */
const getRoleOptions = async (userId) => {
  const userResult = await rideDb.query(
     `SELECT user_id, university_email, account_status, activity_status, selected_mode
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
   const riderFlag = vehicleCount > 0 ? 'yes' : 'no';

  const isAccountActive =
    user.account_status &&
    String(user.account_status).toLowerCase() === 'active';

  const riderAllowed = isAccountActive && vehicleCount > 0;
  const passengerAllowed = isAccountActive;

  let riderReason = null;

  if (!isAccountActive) {
    riderReason = 'Your account is not active.';
  } else if (!riderAllowed) {
    riderReason =
      'You are not registered as a rider yet. Please add a vehicle first.';
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
  getMyProfile,
  updateMyProfile,
  updateProfilePicture,
  getRoleOptions,
};
