const rideDb = require('../config/rideDb');
const {
  emitAdminVehicleVerificationUpdated,
} = require('../utils/adminVehicleEmitter');

const getPendingVehicleRequests = async (search = '') => {
  const values = [];
  let where = `WHERE v.verification_status = 'pending'`;

  if (search && search.trim()) {
    values.push(`%${search.trim()}%`);
    where += `
      AND (
        u.first_name ILIKE $1 OR
        u.last_name ILIKE $1 OR
        CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) ILIKE $1 OR
        u.university_email ILIKE $1 OR
        v.company ILIKE $1 OR
        v.model ILIKE $1 OR
        v.number_plate ILIKE $1
      )
    `;
  }

  const query = `
    SELECT
      v.vehicle_id,
      v.user_id,
      v.vehicle_type,
      v.company,
      v.model,
      v.year,
      v.number_plate,
      v.total_seats,
      v.varsity_id_photo,
      v.driver_profile_photo,
      v.driving_license_photo,
      v.vehicle_registration_photo,
      v.tax_token_photo,
      v.verification_status,
      v.verified,
      v.created_at,
      u.first_name,
      u.last_name,
      u.university_email,
      u.phone,
      u.gender
    FROM vehicles v
    INNER JOIN users u ON u.user_id = v.user_id
    ${where}
    ORDER BY v.created_at DESC
  `;

  const result = await rideDb.query(query, values);

  return result.rows.map((row) => ({
    id: row.vehicle_id,
    userId: row.user_id,
    name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    email: row.university_email,
    phone: row.phone,
    gender: row.gender,
    vehicleType: row.vehicle_type,
    vehicleCompany: row.company,
    vehicleModel: row.model,
    vehicleYear: String(row.year),
    numberPlate: row.number_plate,
    totalSeats: row.total_seats,
    universityIdImage: row.varsity_id_photo,
    profilePhoto: row.driver_profile_photo,
    drivingLicenseImage: row.driving_license_photo,
    registrationPaperImage: row.vehicle_registration_photo,
    taxTokenImage: row.tax_token_photo,
    submittedAt: row.created_at,
    status: row.verification_status,
  }));
};

const getVehicleRequestDetails = async (vehicleId) => {
  const result = await rideDb.query(
    `
    SELECT
      v.vehicle_id,
      v.user_id,
      v.vehicle_type,
      v.company,
      v.model,
      v.year,
      v.number_plate,
      v.total_seats,
      v.varsity_id_photo,
      v.driver_profile_photo,
      v.driving_license_photo,
      v.vehicle_registration_photo,
      v.tax_token_photo,
      v.verification_status,
      v.rejection_reason,
      v.verified,
      v.created_at,
      v.reviewed_at,
      u.first_name,
      u.last_name,
      u.university_email,
      u.phone,
      u.gender
    FROM vehicles v
    INNER JOIN users u ON u.user_id = v.user_id
    WHERE v.vehicle_id = $1
    LIMIT 1
    `,
    [vehicleId]
  );

  if (!result.rows.length) {
    throw new Error('Vehicle request not found.');
  }

  const row = result.rows[0];

  return {
    id: row.vehicle_id,
    userId: row.user_id,
    name: `${row.first_name || ''} ${row.last_name || ''}`.trim(),
    email: row.university_email,
    phone: row.phone,
    gender: row.gender,
    vehicleType: row.vehicle_type,
    vehicleCompany: row.company,
    vehicleModel: row.model,
    vehicleYear: String(row.year),
    numberPlate: row.number_plate,
    totalSeats: row.total_seats,
    universityIdImage: row.varsity_id_photo,
    profilePhoto: row.driver_profile_photo,
    drivingLicenseImage: row.driving_license_photo,
    registrationPaperImage: row.vehicle_registration_photo,
    taxTokenImage: row.tax_token_photo,
    submittedAt: row.created_at,
    reviewedAt: row.reviewed_at,
    rejectionReason: row.rejection_reason,
    status: row.verification_status,
    verified: row.verified,
  };
};

const approveVehicleRequest = async (vehicleId, adminUserId) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const vehicleResult = await client.query(
      `
      SELECT vehicle_id, user_id, verification_status
      FROM vehicles
      WHERE vehicle_id = $1
      FOR UPDATE
      `,
      [vehicleId]
    );

    if (!vehicleResult.rows.length) {
      throw new Error('Vehicle request not found.');
    }

    const vehicle = vehicleResult.rows[0];

    if (vehicle.verification_status === 'approved') {
      throw new Error('This request is already approved.');
    }

    await client.query(
      `
      UPDATE vehicles
      SET
        verified = true,
        verification_status = 'approved',
        rejection_reason = NULL,
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = $2
      WHERE vehicle_id = $1
      `,
      [vehicleId, adminUserId]
    );

    await client.query(
      `
      UPDATE users
      SET selected_mode = 'rider'
      WHERE user_id = $1
      `,
      [vehicle.user_id]
    );

    await client.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        is_important,
        target_role,
        related_id
      )
      VALUES (
        $1,
        'Rider Request Approved',
        'Your vehicle verification has been approved. You can now use rider features.',
        'rider_verification',
        false,
        true,
        'user',
        $2
      )
      `,
      [vehicle.user_id, vehicleId]
    );

    await client.query('COMMIT');

    emitAdminVehicleVerificationUpdated({
        action: 'approved',
        vehicleId,
        userId: vehicle.user_id,
        adminUserId,
    });

    return {
      vehicleId,
      userId: vehicle.user_id,
      status: 'approved',
      riderEligible: true,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const rejectVehicleRequest = async (vehicleId, adminUserId, reason = null) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const vehicleResult = await client.query(
      `
      SELECT vehicle_id, user_id, verification_status
      FROM vehicles
      WHERE vehicle_id = $1
      FOR UPDATE
      `,
      [vehicleId]
    );

    if (!vehicleResult.rows.length) {
      throw new Error('Vehicle request not found.');
    }

    const vehicle = vehicleResult.rows[0];

    if (vehicle.verification_status === 'rejected') {
      throw new Error('This request is already rejected.');
    }

    await client.query(
      `
      UPDATE vehicles
      SET
        verified = false,
        verification_status = 'rejected',
        rejection_reason = $3,
        reviewed_at = CURRENT_TIMESTAMP,
        reviewed_by = $2
      WHERE vehicle_id = $1
      `,
      [vehicleId, adminUserId, reason || 'Your request did not meet verification requirements.']
    );

    await client.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        is_important,
        target_role,
        related_id
      )
      VALUES (
        $1,
        'Rider Request Rejected',
        $2,
        'rider_verification',
        false,
        true,
        'user',
        $3
      )
      `,
      [
        vehicle.user_id,
        reason || 'Your rider verification request has been rejected. Please review your documents and try again.',
        vehicleId,
      ]
    );

    await client.query('COMMIT');

    emitAdminVehicleVerificationUpdated({
      action: 'rejected',
      vehicleId,
      userId: vehicle.user_id,
      adminUserId,
    });

    return {
      vehicleId,
      userId: vehicle.user_id,
      status: 'rejected',
      riderEligible: false,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  getPendingVehicleRequests,
  getVehicleRequestDetails,
  approveVehicleRequest,
  rejectVehicleRequest,
};
