const rideDb = require('../config/rideDb');
const { createNotification } = require('./notificationService');

const createSafetyCheck = async ({
  sessionId = null, rideId = null, rideType, recipientUserId, recipientRole,
}) => {
  const result = await rideDb.query(
    `INSERT INTO safety_checks (session_id, ride_id, ride_type, recipient_user_id, recipient_role, status)
     VALUES ($1, $2, $3, $4, $5, 'pending') RETURNING *`,
    [sessionId, rideId, rideType, recipientUserId, recipientRole]
  );
  const check = result.rows[0];
  const rideLabel = rideType === 'coride' ? 'CoRide' : 'রাইড';

  await createNotification({
    userId: recipientUserId,
    title: 'Is everything okay?',
    message: `Your ${rideLabel} appears to have ended before reaching its intended destination. Are you okay?`,
    type: 'safety_check',
    isImportant: true,
    targetRole: 'general',
    relatedId: String(check.check_id),
  });
  return check;
};

const respondSafetyCheck = async (checkId, userId, { status, message }) => {
  if (!['okay', 'not_okay'].includes(status)) throw new Error('Invalid status.');
  const result = await rideDb.query(
    `UPDATE safety_checks SET status = $1, message = $2, responded_at = CURRENT_TIMESTAMP
     WHERE check_id = $3 AND recipient_user_id = $4 RETURNING *`,
    [status, status === 'not_okay' ? (message || '').trim() || null : null, checkId, userId]
  );
  if (result.rowCount === 0) throw new Error('Safety check not found or not authorized.');
  return result.rows[0];
};

const getAdminSafetyReports = async ({ status = 'all', page = 1, limit = 20 } = {}) => {
  const offset = (Math.max(1, page) - 1) * limit;
  const params = [];
  let where = '1=1';
  if (status && status !== 'all') {
    params.push(status);
    where += ` AND sc.status = $${params.length}`;
  }

  const query = `
    SELECT
      sc.check_id, sc.ride_type, sc.recipient_role, sc.status, sc.message,
      sc.created_at, sc.responded_at,
      ru.user_id AS recipient_user_id,
      ru.first_name || ' ' || ru.last_name AS recipient_name,
      ru.phone AS recipient_phone,
      COALESCE(css.start_location, r.start_location) AS pickup,
      COALESCE(css.destination, r.destination) AS destination,
      CASE
        WHEN sc.recipient_role = 'participant' THEN host_u.first_name || ' ' || host_u.last_name
        WHEN sc.recipient_role = 'passenger' THEN rider_u.first_name || ' ' || rider_u.last_name
        ELSE NULL
      END AS counterpart_name,
      CASE
        WHEN sc.recipient_role = 'participant' THEN host_u.phone
        WHEN sc.recipient_role = 'passenger' THEN rider_u.phone
        ELSE NULL
      END AS counterpart_phone
    FROM safety_checks sc
    JOIN users ru ON sc.recipient_user_id = ru.user_id
    LEFT JOIN company_sharing_sessions css ON sc.session_id = css.session_id
    LEFT JOIN users host_u ON css.created_by = host_u.user_id
    LEFT JOIN rides r ON sc.ride_id = r.ride_id
    LEFT JOIN users rider_u ON r.rider_id = rider_u.user_id
    WHERE ${where}
    ORDER BY sc.created_at DESC
    LIMIT $${params.length + 1} OFFSET $${params.length + 2}
  `;
  params.push(limit, offset);
  const result = await rideDb.query(query, params);
  return result.rows;
};

module.exports = { createSafetyCheck, respondSafetyCheck, getAdminSafetyReports };
