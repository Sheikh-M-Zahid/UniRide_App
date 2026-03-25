const rideDb = require('../config/rideDb');
const generateOtp = require('../utils/generateOtp');

const normalize = (email) => email.trim().toLowerCase();

const createOtp = async (email) => {
  const normalized = normalize(email);
  const otp = generateOtp();
  const expires = process.env.OTP_EXPIRES_MINUTES || 5;

  await rideDb.query(
    `DELETE FROM otp_verifications WHERE email = $1`,
    [normalized]
  );

  const result = await rideDb.query(
    `INSERT INTO otp_verifications (email, otp_code, expires_at)
     VALUES ($1, $2, CURRENT_TIMESTAMP + ($3 || ' minutes')::interval)
     RETURNING *`,
    [normalized, otp, String(expires)]
  );

  return {
    otp,
    record: result.rows[0],
  };
};

const verifyOtp = async (email, otp) => {
  const normalized = normalize(email);

  const result = await rideDb.query(
    `SELECT * FROM otp_verifications
     WHERE email = $1
     ORDER BY expires_at DESC
     LIMIT 1`,
    [normalized]
  );

  if (result.rowCount === 0) {
    throw new Error('Invalid OTP.');
  }

  const record = result.rows[0];

  if (record.otp_code !== otp) {
    throw new Error('Invalid OTP.');
  }

  if (new Date(record.expires_at) < new Date()) {
    throw new Error('OTP has expired. Please request a new one.');
  }

  await rideDb.query(
    `DELETE FROM otp_verifications WHERE otp_id = $1`,
    [record.otp_id]
  );

  return true;
};

module.exports = {
  createOtp,
  verifyOtp,
};