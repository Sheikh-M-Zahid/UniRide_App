const pool = require('../config/rideDb');

const getImageUrl = (req, filePath) => {
  if (!filePath) return null;
  if (filePath.startsWith('http')) return filePath;
  return `${req.protocol}://${req.get('host')}/${filePath}`;
};

// REGISTER
exports.registerAlumni = async (req) => {
  const userId = req.user.user_id;

  const existing = await pool.query(
    'SELECT alumni_id, verification_status FROM alumni_profiles WHERE user_id = $1',
    [userId]
  );

  if (existing.rows.length > 0) {
    const st = existing.rows[0].verification_status;
    if (st === 'pending') throw { status: 409, message: 'Already under review' };
    if (st === 'approved') throw { status: 409, message: 'Already verified' };

    await pool.query('DELETE FROM alumni_profiles WHERE user_id = $1', [userId]);
  }

  if (!req.body.degree_type) throw { status: 400, message: 'degree_type required' };

  if (!req.files?.alumni_card_photo || !req.files?.transcript_photo) {
    throw { status: 400, message: 'Images required' };
  }

  const alumniCard = req.files.alumni_card_photo[0].path;
  const transcript = req.files.transcript_photo[0].path;

  const insert = await pool.query(
    `INSERT INTO alumni_profiles (user_id, degree_type, alumni_card_photo, transcript_photo)
     VALUES ($1,$2,$3,$4) RETURNING alumni_id`,
    [userId, req.body.degree_type, alumniCard, transcript]
  );

  return {
    success: true,
    message: 'Submitted successfully',
    data: insert.rows[0]
  };
};

// STATUS
exports.getMyStatus = async (req) => {
  const userId = req.user.user_id;

  const result = await pool.query(
    `SELECT ap.*, u.first_name, u.last_name, u.profile_picture
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.user_id = $1`,
    [userId]
  );

  if (!result.rows.length) return { success: true, data: null };

  const row = result.rows[0];
  row.profile_picture = getImageUrl(req, row.profile_picture);

  return { success: true, data: row };
};

// UPDATE
exports.updateProfile = async (req) => {
  const userId = req.user.user_id;

  const check = await pool.query(
    `SELECT alumni_id FROM alumni_profiles
     WHERE user_id=$1 AND verification_status='approved'`,
    [userId]
  );

  if (!check.rows.length) throw { status: 403, message: 'Not allowed' };

  const alumniId = check.rows[0].alumni_id;

  await pool.query(
    `UPDATE alumni_profiles SET current_workplace=$1, current_position=$2 WHERE alumni_id=$3`,
    [req.body.current_workplace || null, req.body.current_position || null, alumniId]
  );

  return { success: true, message: 'Updated' };
};

// LIST
exports.getAlumniList = async (req) => {
  const result = await pool.query(
    `SELECT ap.*, u.first_name, u.last_name
     FROM alumni_profiles ap
     JOIN users u ON u.user_id = ap.user_id
     WHERE ap.verification_status='approved'`
  );

  return { success: true, data: result.rows };
};

// DEPARTMENTS
exports.getDepartments = async () => {
  const result = await pool.query(
    `SELECT DISTINCT department FROM alumni_profiles WHERE department IS NOT NULL`
  );
  return { success: true, data: result.rows.map(r => r.department) };
};

// CONTACT REQUEST
exports.sendContactRequest = async (req) => {
  const { alumni_id, message } = req.body;
  const requesterId = req.user.user_id;

  if (!alumni_id) throw { status: 400, message: 'alumni_id required' };

  await pool.query(
    `INSERT INTO alumni_contact_requests (alumni_id, requester_id, message)
     VALUES ($1,$2,$3)`,
    [alumni_id, requesterId, message || null]
  );

  return { success: true, message: 'Request sent' };
};

// REQUESTS
exports.getRequests = async (req) => {
  const userId = req.user.user_id;

  const result = await pool.query(
    `SELECT * FROM alumni_contact_requests WHERE requester_id=$1`,
    [userId]
  );

  return { success: true, data: result.rows };
};

// RESPOND
exports.respondRequest = async (req) => {
  const { requestId } = req.params;
  const { action } = req.body;

  await pool.query(
    `UPDATE alumni_contact_requests SET status=$1 WHERE request_id=$2`,
    [action, requestId]
  );

  return { success: true, message: 'Updated' };
};

// CHAT
exports.getMessages = async (req) => {
  const { sessionId } = req.params;

  const result = await pool.query(
    `SELECT * FROM alumni_chat_messages WHERE session_id=$1`,
    [sessionId]
  );

  return { success: true, data: result.rows };
};

exports.getMyChats = async (req) => {
  const userId = req.user.user_id;

  const result = await pool.query(
    `SELECT * FROM alumni_chat_sessions WHERE requester_id=$1`,
    [userId]
  );

  return { success: true, data: result.rows };
};

// ADMIN
exports.getPending = async () => {
  const result = await pool.query(
    `SELECT * FROM alumni_profiles WHERE verification_status='pending'`
  );
  return { success: true, data: result.rows };
};

exports.getPendingCount = async () => {
  const result = await pool.query(
    `SELECT COUNT(*) FROM alumni_profiles WHERE verification_status='pending'`
  );
  return { success: true, data: result.rows[0] };
};

exports.reviewAlumni = async (req) => {
  const { alumniId } = req.params;
  const { action } = req.body;

  await pool.query(
    `UPDATE alumni_profiles SET verification_status=$1 WHERE alumni_id=$2`,
    [action, alumniId]
  );

  return { success: true, message: `Alumni ${action}` };
};
