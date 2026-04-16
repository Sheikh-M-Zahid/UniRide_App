const rideDb = require('../config/rideDb');

const ALLOWED_LOCATION_ACCESS = ['never', 'during_ride', 'always'];
const ALLOWED_PROFILE_VISIBILITY = [
  'matched_only',
  'university_only',
  'admin_only',
];
const ALLOWED_PHONE_PRIVACY = ['hidden', 'after_accept', 'always_visible'];

const ensureAllowedValue = (value, allowed, fieldName) => {
  const normalized = String(value || '').trim().toLowerCase();

  if (!allowed.includes(normalized)) {
    throw new Error(
      `Invalid ${fieldName}. Allowed values: ${allowed.join(', ')}.`
    );
  }

  return normalized;
};

const getPrivacyData = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        first_name,
        last_name,
        university_email,
        phone,
        account_status,
        location_access,
        profile_visibility,
        phone_privacy
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  const user = result.rows[0];

  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim();
  const dueAmountRes = await rideDb.query(
    `SELECT due_balance
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  const dueAmount = Number(dueAmountRes.rows[0]?.due_balance || 0);

  return {
    fullName,
    email: user.university_email || '',
    phoneNumber: user.phone || '',
    canDownloadData: String(user.account_status || '').toLowerCase() !== 'blocked',
    locationAccess: user.location_access || 'during_ride',
    profileVisibility: user.profile_visibility || 'matched_only',
    phonePrivacy: user.phone_privacy || 'after_accept',
    hasDuePayment: dueAmount > 0,
    dueAmount,
  };
};

const updateLocationAccess = async (userId, locationAccess) => {
  const normalized = ensureAllowedValue(
    locationAccess,
    ALLOWED_LOCATION_ACCESS,
    'locationAccess'
  );

  const result = await rideDb.query(
    `UPDATE users
     SET location_access = $2
     WHERE user_id = $1
     RETURNING location_access`,
    [userId, normalized]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  return {
    locationAccess: result.rows[0].location_access,
  };
};

const updateProfileVisibility = async (userId, profileVisibility) => {
  const normalized = ensureAllowedValue(
    profileVisibility,
    ALLOWED_PROFILE_VISIBILITY,
    'profileVisibility'
  );

  const result = await rideDb.query(
    `UPDATE users
     SET profile_visibility = $2
     WHERE user_id = $1
     RETURNING profile_visibility`,
    [userId, normalized]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  return {
    profileVisibility: result.rows[0].profile_visibility,
  };
};

const updatePhonePrivacy = async (userId, phonePrivacy) => {
  const normalized = ensureAllowedValue(
    phonePrivacy,
    ALLOWED_PHONE_PRIVACY,
    'phonePrivacy'
  );

  const result = await rideDb.query(
    `UPDATE users
     SET phone_privacy = $2
     WHERE user_id = $1
     RETURNING phone_privacy`,
    [userId, normalized]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  return {
    phonePrivacy: result.rows[0].phone_privacy,
  };
};

const requestDataDownload = async (userId) => {
  const result = await rideDb.query(
    `SELECT
        user_id,
        first_name,
        last_name,
        university_email,
        phone,
        profile_picture,
        account_status,
        location_access,
        profile_visibility,
        phone_privacy,
        created_at
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (!result.rows.length) {
    throw new Error('User not found.');
  }

  const user = result.rows[0];

  // practical first version:
  // generate data instantly from real DB and return confirmation only
  // later this can become file export / email / queued job

  return {
    requested: true,
    generatedAt: new Date().toISOString(),
    preview: {
      userId: user.user_id,
      fullName: `${user.first_name || ''} ${user.last_name || ''}`.trim(),
      email: user.university_email,
      phone: user.phone,
      accountStatus: user.account_status,
      privacy: {
        locationAccess: user.location_access || 'during_ride',
        profileVisibility: user.profile_visibility || 'matched_only',
        phonePrivacy: user.phone_privacy || 'after_accept',
      },
      createdAt: user.created_at,
    },
  };
};

module.exports = {
  getPrivacyData,
  updateLocationAccess,
  updateProfileVisibility,
  updatePhonePrivacy,
  requestDataDownload,
};