const rideDb = require('../config/rideDb');

const buildProfileImageUrl = (req, storedPath) => {
  if (!storedPath) return null;

  if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
    return storedPath;
  }

  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}${storedPath}`;
};

const splitFullName = (fullName) => {
  const trimmed = String(fullName || '').trim();

  if (!trimmed) {
    return { firstName: '', lastName: '' };
  }

  const parts = trimmed.split(/\s+/);
  const firstName = parts.shift() || '';
  const lastName = parts.join(' ');

  return { firstName, lastName };
};

const getUserType = (user) => {
  // safest real fallback
  if (user.university_email?.includes('@std.')) return 'Student';
  return 'User';
};

const mapProfileResponse = (row, req, roles) => ({
  id: row.user_id,
  fullName: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
  email: row.university_email,
  phone: row.phone || '',
  userType: getUserType(row),
  gender: row.gender || '',
  joinedDate: row.created_at,
  profileImageUrl: buildProfileImageUrl(req, row.profile_picture),
  isVerified: row.account_status === 'active',
  roles,
});

const getUserByAdminEmail = async (adminEmail) => {
  const result = await rideDb.query(
    `SELECT
        user_id,
        university_email,
        first_name,
        last_name,
        phone,
        gender,
        profile_picture,
        account_status,
        activity_status,
        rating,
        created_at
     FROM users
     WHERE university_email = $1
     LIMIT 1`,
    [adminEmail]
  );

  if (!result.rows.length) {
    throw new Error('Admin user profile not found in ride_sharing_db users table.');
  }

  return result.rows[0];
};

const getRolesForUser = async ({ userId, adminAuth }) => {
  const roles = new Set();

  // Admin role from actual admin auth
  roles.add('admin');

  // Passenger role exists if user exists in users
  roles.add('passenger');

  const roleRes = await rideDb.query(
    `SELECT role
     FROM user_roles
     WHERE user_id = $1`,
    [userId]
  );

  for (const row of roleRes.rows) {
    if (row.role) {
      roles.add(String(row.role).trim().toLowerCase());
    }
  }

  const vehicleRes = await rideDb.query(
    `SELECT COUNT(*)::int AS vehicle_count
     FROM vehicles
     WHERE user_id = $1`,
    [userId]
  );

  if (Number(vehicleRes.rows[0]?.vehicle_count || 0) > 0) {
    roles.add('rider');
  }

  return Array.from(roles);
};

const getAdminProfile = async ({ adminAuth, req }) => {
  const user = await getUserByAdminEmail(adminAuth.email);

  const roles = await getRolesForUser({
    userId: user.user_id,
    adminAuth,
  });

  return mapProfileResponse(user, req, roles);
};

const updateAdminProfile = async ({ adminAuth, body, req }) => {
  const user = await getUserByAdminEmail(adminAuth.email);

  const { fullName, phone, gender } = body;

  const currentFirstName = user.first_name || '';
  const currentLastName = user.last_name || '';

  let firstName = currentFirstName;
  let lastName = currentLastName;

  if (fullName !== undefined) {
    const parsed = splitFullName(fullName);
    firstName = parsed.firstName;
    lastName = parsed.lastName;
  }

  const result = await rideDb.query(
    `UPDATE users
     SET
       first_name = $1,
       last_name = $2,
       phone = COALESCE($3, phone),
       gender = COALESCE($4, gender)
     WHERE user_id = $5
     RETURNING
       user_id,
       university_email,
       first_name,
       last_name,
       phone,
       gender,
       profile_picture,
       account_status,
       activity_status,
       rating,
       created_at`,
    [
      firstName,
      lastName,
      phone ?? null,
      gender ?? null,
      user.user_id,
    ]
  );

  const roles = await getRolesForUser({
    userId: user.user_id,
    adminAuth,
  });

  return mapProfileResponse(result.rows[0], req, roles);
};

const updateAdminProfileImage = async ({ adminAuth, file, req }) => {
  const user = await getUserByAdminEmail(adminAuth.email);

  const storedPath = `/uploads/profile-pictures/${file.filename}`;

  const result = await rideDb.query(
    `UPDATE users
     SET profile_picture = $1
     WHERE user_id = $2
     RETURNING
       user_id,
       university_email,
       first_name,
       last_name,
       phone,
       gender,
       profile_picture,
       account_status,
       activity_status,
       rating,
       created_at`,
    [storedPath, user.user_id]
  );

  const roles = await getRolesForUser({
    userId: user.user_id,
    adminAuth,
  });

  return mapProfileResponse(result.rows[0], req, roles);
};

module.exports = {
  getAdminProfile,
  updateAdminProfile,
  updateAdminProfileImage,
};