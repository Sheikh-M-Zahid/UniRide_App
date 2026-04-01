const ewuAdminDb = require('../config/ewuAdminDb');
const rideDb = require('../config/rideDb');
const generateOtp = require('../utils/generateOtp');
const { generateToken } = require('../utils/jwt');
const { hashPassword, comparePassword } = require('../utils/password');
const { isValidUniversityEmail } = require('../utils/validators');
const {
  savePasswordRecoveryOtp,
  createOtp,
  verifyOtp: verifyOtpFromService,
} = require('./otpService');
const {
  sendPasswordRecoveryOtpEmail,
  sendSignupOtpEmail,
} = require('./mailService');
const {
  generateResetToken,
  verifyResetToken,
} = require('./resetTokenService');
const {
  generateSignupToken,
  verifySignupToken,
} = require('./signupTokenService');

const normalizeEmail = (email) => String(email).trim().toLowerCase();
const normalize = (email) => String(email).trim().toLowerCase();

/* =========================
   COMMON HELPERS
========================= */
const checkEwuAllowedUser = async (email) => {
  const normalized = normalizeEmail(email);

  if (!isValidUniversityEmail(normalized)) {
    return { allowed: false, reason: 'Invalid university email domain.' };
  }

  const result = await ewuAdminDb.query(
    `SELECT id, university_email, occupation, status
     FROM ewu_users
     WHERE university_email = $1`,
    [normalized]
  );

  if (result.rowCount === 0) {
    return { allowed: false, reason: 'Email not found in EWU allowed users.' };
  }

  if (!result.rows[0].status) {
    return { allowed: false, reason: 'This EWU account is inactive.' };
  }

  return { allowed: true, ewuUser: result.rows[0] };
};

const checkAdminStatus = async (email, userId = null) => {
  const normalized = normalizeEmail(email);

  const adminResult = await ewuAdminDb.query(
    `SELECT id, role, name, email
     FROM admins
     WHERE email = $1`,
    [normalized]
  );

  if (adminResult.rowCount > 0) {
    return {
      isAdmin: true,
      adminSource: 'ewu_admin_db.admins',
      adminInfo: adminResult.rows[0],
    };
  }

  if (userId) {
    const roleResult = await rideDb.query(
      `SELECT role
       FROM user_roles
       WHERE user_id = $1 AND role = 'admin'`,
      [userId]
    );

    if (roleResult.rowCount > 0) {
      return {
        isAdmin: true,
        adminSource: 'ride_sharing_db.user_roles',
        adminInfo: roleResult.rows[0],
      };
    }
  }

  return { isAdmin: false };
};

/* =========================
   SIGNUP EMAIL VERIFY FLOW
========================= */
const sendSignupOtp = async (emailInput) => {
  if (!emailInput || !String(emailInput).trim()) {
    throw new Error('Email is required.');
  }

  const email = normalizeEmail(emailInput);

  if (!isValidUniversityEmail(email)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  const ewuUser = await ewuAdminDb.query(
    `SELECT university_email, status
     FROM ewu_users
     WHERE university_email = $1`,
    [email]
  );

  if (ewuUser.rowCount === 0 || !ewuUser.rows[0].status) {
    throw new Error('This university email is not approved for signup.');
  }

  const existingUser = await rideDb.query(
    `SELECT user_id
     FROM users
     WHERE university_email = $1`,
    [email]
  );

  if (existingUser.rowCount > 0) {
    throw new Error('This account already exists. Please log in instead.');
  }

  const otpCode = generateOtp();

  await rideDb.query(
    `DELETE FROM otp_verifications
     WHERE email = $1`,
    [email]
  );

  await rideDb.query(
    `INSERT INTO otp_verifications (email, otp_code, expires_at)
     VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '5 minutes')`,
    [email, otpCode]
  );

  if (typeof sendSignupOtpEmail === 'function') {
    await sendSignupOtpEmail(email, otpCode);
  } else {
    console.log(`Signup OTP for ${email}: ${otpCode}`);
  }

  return { email };
};

const verifySignupOtp = async (emailInput, otpInput) => {
  if (!emailInput || !otpInput) {
    throw new Error('Email and OTP are required.');
  }

  const email = normalizeEmail(emailInput);
  const otp = String(otpInput).trim();

  if (!/^\d{6}$/.test(otp)) {
    throw new Error('Invalid OTP format.');
  }

  const result = await rideDb.query(
    `SELECT otp_id, otp_code, expires_at
     FROM otp_verifications
     WHERE email = $1
     ORDER BY expires_at DESC
     LIMIT 1`,
    [email]
  );

  if (result.rowCount === 0) {
    throw new Error('OTP not found. Please request a new code.');
  }

  const record = result.rows[0];

  if (new Date(record.expires_at) < new Date()) {
    throw new Error('OTP has expired. Please resend the code.');
  }

  if (String(record.otp_code) !== otp) {
    throw new Error('The code you entered is incorrect.');
  }

  await rideDb.query(
    `DELETE FROM otp_verifications
     WHERE email = $1`,
    [email]
  );

  return {
    email,
    verified: true,
    signupToken: generateSignupToken(email),
  };
};

const resendSignupOtp = async (emailInput) => {
  if (!emailInput || !String(emailInput).trim()) {
    throw new Error('Email is required.');
  }

  const email = normalizeEmail(emailInput);

  if (!isValidUniversityEmail(email)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  const ewuUser = await ewuAdminDb.query(
    `SELECT university_email, status
     FROM ewu_users
     WHERE university_email = $1`,
    [email]
  );

  if (ewuUser.rowCount === 0 || !ewuUser.rows[0].status) {
    throw new Error('This university email is not approved.');
  }

  const existingUser = await rideDb.query(
    `SELECT user_id
     FROM users
     WHERE university_email = $1`,
    [email]
  );

  if (existingUser.rowCount > 0) {
    throw new Error('Account already exists. Please login.');
  }

  const otpCode = generateOtp();

  await rideDb.query(
    `DELETE FROM otp_verifications
     WHERE email = $1`,
    [email]
  );

  await rideDb.query(
    `INSERT INTO otp_verifications (email, otp_code, expires_at)
     VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '5 minutes')`,
    [email, otpCode]
  );

  if (typeof sendSignupOtpEmail === 'function') {
    await sendSignupOtpEmail(email, otpCode);
  } else {
    console.log(`Resend signup OTP for ${email}: ${otpCode}`);
  }

  return {
    email,
    resent: true,
  };
};

const googleSignupCheck = async (emailInput) => {
  if (!emailInput || !String(emailInput).trim()) {
    throw new Error('Email is required.');
  }

  const email = normalizeEmail(emailInput);

  if (!isValidUniversityEmail(email)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  const ewuUser = await ewuAdminDb.query(
    `SELECT university_email, status
     FROM ewu_users
     WHERE university_email = $1`,
    [email]
  );

  if (ewuUser.rowCount === 0 || !ewuUser.rows[0].status) {
    throw new Error('This university email is not approved.');
  }

  const existingUser = await rideDb.query(
    `SELECT user_id
     FROM users
     WHERE university_email = $1`,
    [email]
  );

  const accountExists = existingUser.rowCount > 0;

  if (!accountExists) {
    const otpCode = generateOtp();

    await rideDb.query(
      `DELETE FROM otp_verifications
       WHERE email = $1`,
      [email]
    );

    await rideDb.query(
      `INSERT INTO otp_verifications (email, otp_code, expires_at)
       VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '5 minutes')`,
      [email, otpCode]
    );

    if (typeof sendSignupOtpEmail === 'function') {
      await sendSignupOtpEmail(email, otpCode);
    } else {
      console.log(`Google signup OTP for ${email}: ${otpCode}`);
    }
  }

  return {
    email,
    approved: true,
    accountExists,
  };
};

const register = async (payload) => {
  const {
    signupToken,
    first_name,
    last_name,
    phone,
    recovery_phone,
    emergency_phone,
    gender,
    blood_group,
    date_of_birth,
    home_address,
    hostel_address,
    campus_address,
    password,
  } = payload;

  if (
    !signupToken ||
    !first_name ||
    !last_name ||
    !phone ||
    !gender ||
    !date_of_birth ||
    !home_address ||
    !hostel_address ||
    !password
  ) {
    throw new Error('Required fields are missing.');
  }

  if (String(password).trim().length < 6) {
    throw new Error('Password must be at least 6 characters.');
  }

  const normalizedGender = String(gender).trim().toLowerCase();
  if (!['male', 'female'].includes(normalizedGender)) {
    throw new Error('Gender must be male or female.');
  }

  let decoded;
  try {
    decoded = verifySignupToken(signupToken);
  } catch (error) {
    throw new Error('Invalid or expired signup session. Please verify OTP again.');
  }

  if (decoded.purpose !== 'signup_verification') {
    throw new Error('Invalid signup session.');
  }

  const email = normalizeEmail(decoded.email);

  const existingUser = await rideDb.query(
    `SELECT user_id
     FROM users
     WHERE university_email = $1
     LIMIT 1`,
    [email]
  );

  if (existingUser.rowCount > 0) {
    throw new Error('Account already exists.');
  }

  const password_hash = await hashPassword(String(password).trim());

  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const userInsert = await client.query(
      `INSERT INTO users (
        university_email,
        password_hash,
        first_name,
        last_name,
        phone,
        recovery_phone,
        emergency_phone,
        gender,
        blood_group,
        date_of_birth,
        home_address,
        hostel_address,
        campus_address,
        account_status,
        activity_status
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
        $11, $12, $13, 'active', 'active'
      )
      RETURNING
        user_id,
        university_email,
        first_name,
        last_name,
        phone,
        account_status,
        activity_status,
        created_at`,
      [
        email,
        password_hash,
        String(first_name).trim(),
        String(last_name).trim(),
        String(phone).trim(),
        recovery_phone ? String(recovery_phone).trim() : null,
        emergency_phone ? String(emergency_phone).trim() : null,
        normalizedGender,
        blood_group ? String(blood_group).trim() : null,
        date_of_birth,
        String(home_address).trim(),
        String(hostel_address).trim(),
        campus_address ? String(campus_address).trim() : null,
      ]
    );

    const user = userInsert.rows[0];

    await client.query(
      `INSERT INTO user_roles (user_id, role)
       VALUES ($1, 'user')`,
      [user.user_id]
    );

    await client.query(
      `DELETE FROM otp_verifications
       WHERE email = $1`,
      [email]
    );

    await client.query('COMMIT');

    return { user };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/* =========================
   BASIC OTP / AUTH
========================= */
const sendOtp = async (email) => {
  const allowed = await checkEwuAllowedUser(email);
  if (!allowed.allowed) {
    throw new Error(allowed.reason);
  }

  const otpCode = generateOtp();

  await rideDb.query(
    `INSERT INTO otp_verifications (email, otp_code, expires_at)
     VALUES ($1, $2, CURRENT_TIMESTAMP + INTERVAL '10 minutes')`,
    [normalizeEmail(email), otpCode]
  );

  return {
    email: normalizeEmail(email),
    otpCode,
    note: 'For production, send this OTP by email/SMS. Returning in response for now.',
  };
};

const verifyOtp = async (email, otpCode) => {
  const result = await rideDb.query(
    `SELECT otp_id, email, otp_code, expires_at
     FROM otp_verifications
     WHERE email = $1 AND otp_code = $2
     ORDER BY expires_at DESC
     LIMIT 1`,
    [normalizeEmail(email), otpCode]
  );

  if (result.rowCount === 0) {
    throw new Error('Invalid OTP.');
  }

  const otp = result.rows[0];

  if (new Date(otp.expires_at) < new Date()) {
    throw new Error('OTP expired.');
  }

  await rideDb.query(
    `DELETE FROM otp_verifications WHERE otp_id = $1`,
    [otp.otp_id]
  );

  return {
    verified: true,
    email: otp.email,
  };
};

const signup = async ({
  university_email,
  password,
  first_name,
  last_name,
  phone,
  role = 'user',
}) => {
  const normalizedEmail = normalizeEmail(university_email);

  const allowed = await checkEwuAllowedUser(normalizedEmail);
  if (!allowed.allowed) {
    throw new Error(allowed.reason);
  }

  const existingUser = await rideDb.query(
    `SELECT user_id FROM users WHERE university_email = $1`,
    [normalizedEmail]
  );

  if (existingUser.rowCount > 0) {
    throw new Error('User already exists.');
  }

  const password_hash = await hashPassword(password);

  const insertedUser = await rideDb.query(
    `INSERT INTO users (
      university_email,
      password_hash,
      first_name,
      last_name,
      phone
    )
    VALUES ($1, $2, $3, $4, $5)
    RETURNING user_id, university_email, first_name, last_name, phone, account_status, created_at`,
    [normalizedEmail, password_hash, first_name || null, last_name || null, phone || null]
  );

  const user = insertedUser.rows[0];

  await rideDb.query(
    `INSERT INTO user_roles (user_id, role)
     VALUES ($1, $2)`,
    [user.user_id, role]
  );

  const adminCheck = await checkAdminStatus(normalizedEmail, user.user_id);

  const token = generateToken({
    userId: user.user_id,
    email: user.university_email,
    isAdmin: adminCheck.isAdmin,
  });

  return {
    user,
    token,
    isAdmin: adminCheck.isAdmin,
  };
};

const login = async (email, password) => {
  const normalizedEmail = normalizeEmail(email);

  const allowed = await checkEwuAllowedUser(normalizedEmail);
  if (!allowed.allowed) {
    throw new Error(allowed.reason);
  }

  const result = await rideDb.query(
    `SELECT user_id, university_email, password_hash, first_name, last_name, phone, account_status
     FROM users
     WHERE university_email = $1`,
    [normalizedEmail]
  );

  if (result.rowCount === 0) {
    throw new Error('Account not found. Please sign up first.');
  }

  const user = result.rows[0];

  if (
    user.account_status &&
    String(user.account_status).toLowerCase() === 'suspended'
  ) {
    throw new Error('Your account is suspended.');
  }

  const isMatched = await comparePassword(password, user.password_hash);

  if (!isMatched) {
    throw new Error('Invalid email or password.');
  }

  const adminCheck = await checkAdminStatus(normalizedEmail, user.user_id);

  const token = generateToken({
    userId: user.user_id,
    email: user.university_email,
    isAdmin: adminCheck.isAdmin,
  });

  return {
    token,
    isAdmin: adminCheck.isAdmin,
    user: {
      user_id: user.user_id,
      university_email: user.university_email,
      first_name: user.first_name,
      last_name: user.last_name,
      phone: user.phone,
      account_status: user.account_status,
    },
  };
};

const googleLogin = async (email) => {
  const normalizedEmail = normalizeEmail(email);

  const allowed = await checkEwuAllowedUser(normalizedEmail);
  if (!allowed.allowed) {
    throw new Error(allowed.reason);
  }

  let userResult = await rideDb.query(
    `SELECT user_id, university_email, first_name, last_name, phone, account_status
     FROM users
     WHERE university_email = $1`,
    [normalizedEmail]
  );

  if (userResult.rowCount === 0) {
    const randomTempPassword = await hashPassword(`google_${Date.now()}`);

    userResult = await rideDb.query(
      `INSERT INTO users (university_email, password_hash)
       VALUES ($1, $2)
       RETURNING user_id, university_email, first_name, last_name, phone, account_status`,
      [normalizedEmail, randomTempPassword]
    );

    await rideDb.query(
      `INSERT INTO user_roles (user_id, role)
       VALUES ($1, 'user')`,
      [userResult.rows[0].user_id]
    );
  }

  const user = userResult.rows[0];

  if (
    user.account_status &&
    String(user.account_status).toLowerCase() === 'suspended'
  ) {
    throw new Error('Your account is suspended.');
  }

  const adminCheck = await checkAdminStatus(normalizedEmail, user.user_id);

  const token = generateToken({
    userId: user.user_id,
    email: user.university_email,
    isAdmin: adminCheck.isAdmin,
  });

  return {
    token,
    isAdmin: adminCheck.isAdmin,
    user,
  };
};

/* =========================
   PASSWORD RESET FLOW
========================= */
const resetPassword = async (email, otpCode, newPassword) => {
  await verifyOtp(email, otpCode);

  const password_hash = await hashPassword(newPassword);

  const result = await rideDb.query(
    `UPDATE users
     SET password_hash = $1
     WHERE university_email = $2
     RETURNING user_id, university_email`,
    [password_hash, normalizeEmail(email)]
  );

  if (result.rowCount === 0) {
    throw new Error('User not found.');
  }

  return result.rows[0];
};

const findAccount = async (email) => {
  if (!email || !String(email).trim()) {
    throw new Error('Please enter your university email.');
  }

  const normalizedEmail = normalizeEmail(email);

  if (!isValidUniversityEmail(normalizedEmail)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  const userResult = await rideDb.query(
    `SELECT user_id, university_email, account_status
     FROM users
     WHERE university_email = $1`,
    [normalizedEmail]
  );

  if (userResult.rowCount === 0) {
    throw new Error('No account found with this university email.');
  }

  const otpRecord = await savePasswordRecoveryOtp(normalizedEmail);

  await sendPasswordRecoveryOtpEmail(normalizedEmail, otpRecord.otp_code);

  return {
    email: normalizedEmail,
  };
};

const verifyRecoveryOtp = async (email, otp) => {
  const normalized = normalize(email);

  if (!isValidUniversityEmail(normalized)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  if (!/^\d{6}$/.test(otp)) {
    throw new Error('OTP must be 6 digits.');
  }

  const userResult = await rideDb.query(
    `SELECT user_id FROM users WHERE university_email = $1`,
    [normalized]
  );

  if (userResult.rowCount === 0) {
    throw new Error('No account found with this university email.');
  }

  await verifyOtpFromService(normalized, otp);

  const resetToken = generateResetToken(normalized);

  return {
    email: normalized,
    resetToken,
  };
};

const resendRecoveryOtp = async (email) => {
  const normalized = normalize(email);

  if (!isValidUniversityEmail(normalized)) {
    throw new Error(
      'Enter a valid university email (@std.ewubd.edu or @ewubd.edu).'
    );
  }

  const userResult = await rideDb.query(
    `SELECT user_id FROM users WHERE university_email = $1`,
    [normalized]
  );

  if (userResult.rowCount === 0) {
    throw new Error('No account found with this university email.');
  }

  const { otp } = await createOtp(normalized);

  await sendPasswordRecoveryOtpEmail(normalized, otp);

  return true;
};

const resetPasswordWithToken = async (
  resetToken,
  newPassword,
  confirmPassword
) => {
  if (!resetToken) {
    throw new Error(
      'Invalid or expired reset session. Please verify OTP again.'
    );
  }

  if (!newPassword || !confirmPassword) {
    throw new Error('Please enter password and confirm password.');
  }

  if (newPassword.length < 6) {
    throw new Error('Password must be at least 6 characters.');
  }

  if (newPassword !== confirmPassword) {
    throw new Error('Passwords do not match.');
  }

  let decoded;
  try {
    decoded = verifyResetToken(resetToken);
  } catch (err) {
    throw new Error(
      'Invalid or expired reset session. Please verify OTP again.'
    );
  }

  if (decoded.purpose !== 'password_reset') {
    throw new Error('Invalid reset token.');
  }

  const email = decoded.email;

  const userResult = await rideDb.query(
    `SELECT user_id FROM users WHERE university_email = $1`,
    [email]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const password_hash = await hashPassword(newPassword);

  await rideDb.query(
    `UPDATE users
     SET password_hash = $1
     WHERE university_email = $2`,
    [password_hash, email]
  );

  return true;
};

module.exports = {
  sendSignupOtp,
  verifySignupOtp,
  resendSignupOtp,
  googleSignupCheck,
  register,
  sendOtp,
  verifyOtp,
  signup,
  login,
  googleLogin,
  resetPassword,
  checkEwuAllowedUser,
  checkAdminStatus,
  findAccount,
  verifyRecoveryOtp,
  resendRecoveryOtp,
  resetPasswordWithToken,
};