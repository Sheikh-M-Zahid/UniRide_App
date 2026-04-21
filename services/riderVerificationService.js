const rideDb = require('../config/rideDb');

const getMyRiderVerificationStatus = async (userId) => {
  const result = await rideDb.query(
    `
    SELECT
      vehicle_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      total_seats,
      verified,
      verification_status,
      rejection_reason,
      created_at,
      reviewed_at
    FROM vehicles
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [userId]
  );

  if (!result.rows.length) {
    return {
      hasApplied: false,
      riderEligible: false,
      status: 'not_applied',
      vehicle: null,
    };
  }

  const vehicle = result.rows[0];
  const riderEligible =
    vehicle.verified === true && vehicle.verification_status === 'approved';

  return {
    hasApplied: true,
    riderEligible,
    status: vehicle.verification_status,
    vehicle,
  };
};

module.exports = {
  getMyRiderVerificationStatus,
};