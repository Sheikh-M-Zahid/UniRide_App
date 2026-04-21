const rideDb = require('../config/rideDb');

const requiredFiles = [
  'varsity_id_photo',
  'driver_profile_photo',
  'driving_license_photo',
  'vehicle_registration_photo',
  'tax_token_photo',
];

const validateFiles = (files) => {
  for (const field of requiredFiles) {
    if (!files || !files[field] || !files[field][0]) {
      throw new Error(`${field} is required`);
    }
  }
};

const getFilePath = (files, field) => {
  return files[field][0].path.replace(/\\/g, '/');
};

const registerCar = async ({ userId, body, files }) => {
  const { company, model, year, number_plate, total_seats } = body;

  if (!company || !model || !year || !number_plate) {
    throw new Error('All fields are required.');
  }

  if (Number.isNaN(Number(year))) {
    throw new Error('Year must be a valid number.');
  }

  const seats = Number(total_seats || 4);
  if (Number.isNaN(seats) || seats < 1 || seats > 4) {
    throw new Error('Total seats must be between 1 and 4.');
  }

  validateFiles(files);

  const existingApprovedOrPending = await rideDb.query(
    `
    SELECT vehicle_id, verification_status, verified
    FROM vehicles
    WHERE user_id = $1
      AND vehicle_type = 'car'
      AND verification_status IN ('pending', 'approved')
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [userId]
  );

  if (existingApprovedOrPending.rows.length > 0) {
    const row = existingApprovedOrPending.rows[0];

    if (row.verification_status === 'pending') {
      throw new Error('You already have a pending car verification request.');
    }

    if (row.verification_status === 'approved' && row.verified === true) {
      throw new Error('Your car is already approved.');
    }
  }

  const duplicatePlate = await rideDb.query(
    `SELECT 1 FROM vehicles WHERE LOWER(number_plate) = LOWER($1)`,
    [number_plate]
  );

  if (duplicatePlate.rows.length) {
    throw new Error('This number plate is already registered.');
  }

  const result = await rideDb.query(
    `
    INSERT INTO vehicles (
      user_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      total_seats,
      varsity_id_photo,
      driver_profile_photo,
      driving_license_photo,
      vehicle_registration_photo,
      tax_token_photo,
      verified,
      verification_status
    )
    VALUES (
      $1, 'car', $2, $3, $4, $5, $6,
      $7, $8, $9, $10, $11,
      false, 'pending'
    )
    RETURNING vehicle_id, vehicle_type, company, model, year, number_plate, total_seats, verification_status, verified, created_at
    `,
    [
      userId,
      company.trim(),
      model.trim(),
      Number(year),
      number_plate.trim(),
      seats,
      getFilePath(files, 'varsity_id_photo'),
      getFilePath(files, 'driver_profile_photo'),
      getFilePath(files, 'driving_license_photo'),
      getFilePath(files, 'vehicle_registration_photo'),
      getFilePath(files, 'tax_token_photo'),
    ]
  );

  return {
    vehicle: result.rows[0],
    riderEligibility: false,
    status: 'pending_verification',
  };
};

module.exports = {
  registerCar,
};