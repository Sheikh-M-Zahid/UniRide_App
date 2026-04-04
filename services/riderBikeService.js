const rideDb = require('../config/rideDb');

/* =========================
   REQUIRED FILE CHECK
========================= */
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

/* =========================
   GET FILE PATH
========================= */
const getFilePath = (files, field) => {
  return files[field][0].path;
};

/* =========================
   MAIN FUNCTION
========================= */
const registerBike = async ({ userId, body, files }) => {
  const { company, model, year, number_plate } = body;

  /* 🔴 FIELD VALIDATION */
  if (!company || !model || !year || !number_plate) {
    throw new Error('All fields are required.');
  }

  validateFiles(files);

  /* 🔴 DUPLICATE NUMBER PLATE CHECK */
  const duplicate = await rideDb.query(
    `SELECT 1 FROM vehicles WHERE number_plate = $1`,
    [number_plate]
  );

  if (duplicate.rows.length) {
    throw new Error('This number plate is already registered.');
  }

  /* 🔴 INSERT */
  const result = await rideDb.query(
    `
    INSERT INTO vehicles (
      user_id,
      vehicle_type,
      company,
      model,
      year,
      number_plate,
      varsity_id_photo,
      driver_profile_photo,
      driving_license_photo,
      vehicle_registration_photo,
      tax_token_photo,
      verified
    )
    VALUES (
      $1, 'bike', $2, $3, $4, $5,
      $6, $7, $8, $9, $10,
      false
    )
    RETURNING *
    `,
    [
      userId,
      company,
      model,
      year,
      number_plate,
      getFilePath(files, 'varsity_id_photo'),
      getFilePath(files, 'driver_profile_photo'),
      getFilePath(files, 'driving_license_photo'),
      getFilePath(files, 'vehicle_registration_photo'),
      getFilePath(files, 'tax_token_photo'),
    ]
  );

  return {
    vehicleId: result.rows[0].vehicle_id,
    status: 'pending_verification',
  };
};

module.exports = {
  registerBike,
};