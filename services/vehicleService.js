const rideDb = require('../config/rideDb');

const requiredFileFields = [
  'varsity_id_photo',
  'driver_profile_photo',
  'driving_license_photo',
  'vehicle_registration_photo',
  'tax_token_photo',
];

const getUploadedPath = (files, field) => {
  if (!files || !files[field] || !files[field][0]) return null;
  return files[field][0].path;
};

const validateFiles = (files) => {
  for (const field of requiredFileFields) {
    if (!files || !files[field] || !files[field][0]) {
      throw new Error(`Missing file: ${field}`);
    }
  }
};

/* =========================
   CREATE VEHICLE
========================= */
const createVehicle = async (userId, body, files) => {
  const {
    vehicle_type,
    company,
    model,
    year,
    number_plate,
    total_seats,
  } = body;

  if (!vehicle_type || !company || !model || !year || !number_plate) {
    throw new Error('Required fields are missing.');
  }

  validateFiles(files);

  const normalizedType = String(vehicle_type).trim().toLowerCase();

  if (!['car', 'bike'].includes(normalizedType)) {
    throw new Error('Vehicle type must be car or bike.');
  }

  const normalizedCompany = String(company).trim();
  const normalizedModel = String(model).trim();
  const normalizedPlate = String(number_plate).trim().toUpperCase();
  const parsedYear = Number(year);

  if (!Number.isInteger(parsedYear) || parsedYear < 1900 || parsedYear > 2100) {
    throw new Error('Invalid vehicle year.');
  }

  let seats = Number(total_seats || 0);

  if (normalizedType === 'bike') {
    seats = 1;
  } else if (!Number.isInteger(seats) || seats <= 0) {
    seats = 4;
  }

  const userResult = await rideDb.query(
    `SELECT user_id, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  if (String(userResult.rows[0].account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const existing = await rideDb.query(
    `SELECT vehicle_id
     FROM vehicles
     WHERE number_plate = $1
     LIMIT 1`,
    [normalizedPlate]
  );

  if (existing.rowCount > 0) {
    throw new Error('This number plate is already registered.');
  }

  const result = await rideDb.query(
    `INSERT INTO vehicles (
      user_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      total_seats,
      verified,
      varsity_id_photo,
      driver_profile_photo,
      driving_license_photo,
      vehicle_registration_photo,
      tax_token_photo
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
    RETURNING
      vehicle_id,
      user_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      total_seats,
      verified,
      created_at`,
    [
      userId,
      normalizedType,
      normalizedCompany,
      normalizedModel,
      parsedYear,
      normalizedPlate,
      seats,
      false,
      getUploadedPath(files, 'varsity_id_photo'),
      getUploadedPath(files, 'driver_profile_photo'),
      getUploadedPath(files, 'driving_license_photo'),
      getUploadedPath(files, 'vehicle_registration_photo'),
      getUploadedPath(files, 'tax_token_photo'),
    ]
  );

  await rideDb.query(
    `UPDATE users
     SET rider = 'YES'
     WHERE user_id = $1`,
    [userId]
  );

  return result.rows[0];
};

/* =========================
   GET MY VEHICLES
========================= */
const getMyVehicles = async (userId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM vehicles
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

/* =========================
   UPDATE VEHICLE
========================= */
const updateVehicle = async (userId, vehicleId, payload) => {
  const allowedFields = [
    'vehicle_type',
    'company',
    'model',
    'year',
    'number_plate',
    'total_seats',
  ];

  const updates = [];
  const values = [];
  let count = 1;

  for (const key of allowedFields) {
    if (payload[key] !== undefined) {
      let value = payload[key];

      if (key === 'vehicle_type') {
        value = String(value).trim().toLowerCase();

        if (!['car', 'bike'].includes(value)) {
          throw new Error('Vehicle type must be car or bike.');
        }
      }

      if (key === 'company' || key === 'model') {
        value = String(value).trim();
      }

      if (key === 'number_plate') {
        value = String(value).trim().toUpperCase();

        const duplicateCheck = await rideDb.query(
          `SELECT vehicle_id
           FROM vehicles
           WHERE number_plate = $1
             AND vehicle_id != $2
           LIMIT 1`,
          [value, vehicleId]
        );

        if (duplicateCheck.rowCount > 0) {
          throw new Error('This number plate is already registered.');
        }
      }

      if (key === 'year') {
        value = Number(value);

        if (!Number.isInteger(value) || value < 1900 || value > 2100) {
          throw new Error('Invalid vehicle year.');
        }
      }

      if (key === 'total_seats') {
        value = Number(value);

        if (!Number.isInteger(value) || value <= 0) {
          throw new Error('Total seats must be greater than 0.');
        }
      }

      updates.push(`${key} = $${count}`);
      values.push(value);
      count++;
    }
  }

  if (updates.length === 0) {
    throw new Error('No valid fields to update.');
  }

  values.push(vehicleId, userId);

  const result = await rideDb.query(
    `UPDATE vehicles
     SET ${updates.join(', ')}
     WHERE vehicle_id = $${count}
       AND user_id = $${count + 1}
     RETURNING *`,
    values
  );

  if (result.rowCount === 0) {
    throw new Error('Vehicle not found or unauthorized.');
  }

  return result.rows[0];
};

/* =========================
   VERIFICATION STATUS
========================= */
const getVehicleVerificationStatus = async (userId) => {
  const result = await rideDb.query(
    `SELECT vehicle_id, vehicle_type, number_plate, verified
     FROM vehicles
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

/* =========================
   DELETE VEHICLE
========================= */
const deleteVehicle = async (userId, vehicleId) => {
  const result = await rideDb.query(
    `DELETE FROM vehicles
     WHERE vehicle_id = $1 AND user_id = $2
     RETURNING *`,
    [vehicleId, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('Vehicle not found or unauthorized.');
  }

  const remaining = await rideDb.query(
    `SELECT 1
     FROM vehicles
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (remaining.rowCount === 0) {
    await rideDb.query(
      `UPDATE users
       SET rider = 'NO'
       WHERE user_id = $1`,
      [userId]
    );
  }

  return true;
};

module.exports = {
  createVehicle,
  getMyVehicles,
  updateVehicle,
  getVehicleVerificationStatus,
  deleteVehicle,
};