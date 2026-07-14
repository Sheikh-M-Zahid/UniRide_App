const rideDb = require('../config/rideDb');

const ACTIVE_CORIDE_STATUSES = ['Active'];
const ACTIVE_RIDE_STATUSES = ['assigned', 'ongoing'];

const getActiveCommitment = async (userId) => {
  const hostRes = await rideDb.query(
    `SELECT session_id FROM company_sharing_sessions
     WHERE created_by = $1 AND status = ANY($2::text[]) LIMIT 1`,
    [userId, ACTIVE_CORIDE_STATUSES]
  );
  if (hostRes.rowCount > 0) return { type: 'coride_host', refId: hostRes.rows[0].session_id };

  const partRes = await rideDb.query(
    `SELECT cp.session_id FROM company_participants cp
     JOIN company_sharing_sessions css ON css.session_id = cp.session_id
     WHERE cp.user_id = $1 AND cp.confirmed = TRUE AND css.status = ANY($2::text[]) LIMIT 1`,
    [userId, ACTIVE_CORIDE_STATUSES]
  );
  if (partRes.rowCount > 0) return { type: 'coride_participant', refId: partRes.rows[0].session_id };

  const riderRes = await rideDb.query(
    `SELECT ride_id FROM rides WHERE rider_id = $1 AND status = ANY($2::text[]) LIMIT 1`,
    [userId, ACTIVE_RIDE_STATUSES]
  );
  if (riderRes.rowCount > 0) return { type: 'standard_rider', refId: riderRes.rows[0].ride_id };

  const passRes = await rideDb.query(
    `SELECT rr.request_id FROM ride_requests rr
     LEFT JOIN rides r ON rr.ride_id = r.ride_id
     WHERE rr.passenger_id = $1
       AND rr.status = 'accepted'
       AND (r.status IS NULL OR r.status IN ('assigned','ongoing'))
     LIMIT 1`,
    [userId]
  );
  if (passRes.rowCount > 0) return { type: 'standard_passenger', refId: passRes.rows[0].request_id };

  return null;
};

const assertNoActiveRideConflict = async (userId, { excludeCorideSessionId = null } = {}) => {
  const active = await getActiveCommitment(userId);
  if (active && String(active.refId) !== String(excludeCorideSessionId)) {
    const err = new Error(
      'You already have an active ride (CoRide or standard ride). Please finish or cancel it before starting a new one.'
    );
    err.code = 'ACTIVE_RIDE_CONFLICT';
    err.activeCommitment = active;
    throw err;
  }
};

module.exports = { getActiveCommitment, assertNoActiveRideConflict };
