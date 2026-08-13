// services/alumniCall.service.js
// Audio call permission flow — request → approve/decline
const pool = require('../config/rideDb');
const { createNotification } = require('./notificationService');
const { getIO } = require('../config/socket');

const getSessionParties = async (sessionId) => {
  const result = await pool.query(
    `SELECT acs.session_id, ap.user_id AS alumni_user_id, acs.requester_id
     FROM alumni_chat_sessions acs
     JOIN alumni_profiles ap ON ap.alumni_id = acs.alumni_id
     WHERE acs.session_id = $1`,
    [sessionId]
  );
  return result.rows[0] || null;
};

exports.requestCallPermission = async (req) => {
  const { sessionId } = req.params;
  const userId = req.user.userId;

  const session = await getSessionParties(sessionId);
  if (!session) throw { status: 404, message: 'Chat session not found' };
  if (session.alumni_user_id !== userId && session.requester_id !== userId) {
    throw { status: 403, message: 'Not allowed' };
  }

  const otherUserId =
    session.alumni_user_id === userId ? session.requester_id : session.alumni_user_id;

  await pool.query(
    `INSERT INTO alumni_call_permissions (session_id, requested_by, status)
     VALUES ($1,$2,'pending')
     ON CONFLICT (session_id)
     DO UPDATE SET requested_by=$2, status='pending', responded_at=NULL, created_at=CURRENT_TIMESTAMP`,
    [sessionId, userId]
  );

  const requesterRow = await pool.query(
    `SELECT first_name, last_name FROM users WHERE user_id=$1`,
    [userId]
  );
  const requesterName = requesterRow.rows.length
    ? `${requesterRow.rows[0].first_name || ''} ${requesterRow.rows[0].last_name || ''}`.trim()
    : 'Someone';

  await createNotification({
    userId: otherUserId,
    title: 'Call Request',
    message: `${requesterName} wants to start an audio call.`,
    type: 'alumni_call_request',
    isImportant: true,
    targetRole: 'general',
    relatedId: sessionId,
  });

  try {
    getIO().to(`user_${otherUserId}`).emit('alumni_call:permission_requested', {
      session_id: sessionId,
      requested_by: userId,
      requester_name: requesterName,
    });
  } catch (e) {
    console.error('call permission emit error:', e.message);
  }

  return { success: true, message: 'Call request sent' };
};

exports.respondCallPermission = async (req) => {
  const { sessionId } = req.params;
  const { action } = req.body; // 'approved' | 'declined'
  const userId = req.user.userId;

  if (!['approved', 'declined'].includes(action)) {
    throw { status: 400, message: 'Invalid action' };
  }

  const session = await getSessionParties(sessionId);
  if (!session) throw { status: 404, message: 'Chat session not found' };
  if (session.alumni_user_id !== userId && session.requester_id !== userId) {
    throw { status: 403, message: 'Not allowed' };
  }

  const permRow = await pool.query(
    `SELECT requested_by FROM alumni_call_permissions WHERE session_id=$1`,
    [sessionId]
  );
  if (!permRow.rows.length) throw { status: 404, message: 'No pending call request' };
  if (permRow.rows[0].requested_by === userId) {
    throw { status: 400, message: 'You cannot respond to your own request' };
  }

  await pool.query(
    `UPDATE alumni_call_permissions SET status=$1, responded_at=CURRENT_TIMESTAMP WHERE session_id=$2`,
    [action, sessionId]
  );

  const requesterId = permRow.rows[0].requested_by;

  try {
    getIO().to(`user_${requesterId}`).emit('alumni_call:permission_responded', {
      session_id: sessionId,
      status: action,
    });
  } catch (e) {
    console.error('call permission response emit error:', e.message);
  }

  return { success: true, message: `Call request ${action}` };
};

exports.getCallPermissionStatus = async (req) => {
  const { sessionId } = req.params;
  const result = await pool.query(
    `SELECT status, requested_by FROM alumni_call_permissions WHERE session_id=$1`,
    [sessionId]
  );
  return { success: true, data: result.rows[0] || null };
};
