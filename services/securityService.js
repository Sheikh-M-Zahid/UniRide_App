const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const bcrypt = require('bcrypt');

//SECURITY SUMMARY
const getSecuritySummary = async (userId) => {
  const userRes = await rideDb.query(
    `SELECT
        university_email,
        emergency_phone,
        due_balance
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (!userRes.rows.length) {
    throw new Error('User not found.');
  }

  const user = userRes.rows[0];

 //EMAIL VERIFIED LOGIC
  const ewuRes = await ewuAdminDb.query(
    `SELECT status
     FROM ewu_users
     WHERE university_email = $1`,
    [user.university_email]
  );

  // verified if exists and active
  const emailVerified =
    ewuRes.rowCount > 0 && ewuRes.rows[0].status === true;

 // DUE LOGIC
const dueAmount = Number(user.due_balance || 0);

  return {
    emailVerified,
    emergencyContact: user.emergency_phone || '',
    hasDuePayment: dueAmount > 0,
    dueAmount,
  };
};

//UPDATE EMERGENCY CONTACT
const updateEmergencyContact = async (userId, phone) => {
  const result = await rideDb.query(
    `UPDATE users
     SET emergency_phone = $2
     WHERE user_id = $1
     RETURNING emergency_phone`,
    [userId, phone]
  );

  return {
    emergencyContact: result.rows[0].emergency_phone,
  };
};

//CHANGE PASSWORD
const changePassword = async (
  userId,
  currentPassword,
  newPassword
) => {
  const userRes = await rideDb.query(
    `SELECT password_hash
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (!userRes.rows.length) {
    throw new Error('User not found.');
  }

  const user = userRes.rows[0];

  const isMatch = await bcrypt.compare(
    currentPassword,
    user.password_hash
  );

  if (!isMatch) {
    throw new Error('Current password is incorrect.');
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await rideDb.query(
    `UPDATE users
     SET password_hash = $2
     WHERE user_id = $1`,
    [userId, hashedPassword]
  );
};

module.exports = {
  getSecuritySummary,
  updateEmergencyContact,
  changePassword,
};
