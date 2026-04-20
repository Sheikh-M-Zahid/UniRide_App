const rideDb = require('../config/rideDb');

const addVehicle = async (userId, payload) => {
  const {
    vehicle_type,
    company,
    model,
    year,
    number_plate,
    total_seats,
  } = payload;

  const result = await rideDb.query(
    `INSERT INTO vehicles (
      user_id, vehicle_type, company, model, year, number_plate, total_seats
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *`,
    [userId, vehicle_type, company, model, year, number_plate, total_seats]
  );

  return result.rows[0];
};

const getMyVehicles = async (userId) => {
  const result = await rideDb.query(
    `SELECT * FROM vehicles WHERE user_id = $1 ORDER BY created_at DESC`,
    [userId]
  );

  return result.rows;
};

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
      updates.push(`${key} = $${count}`);
      values.push(payload[key]);
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
     WHERE vehicle_id = $${count} AND user_id = $${count + 1}
     RETURNING *`,
    values
  );

  if (result.rowCount === 0) {
    throw new Error('Vehicle not found or unauthorized.');
  }

  return result.rows[0];
};

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

module.exports = {
  addVehicle,
  getMyVehicles,
  updateVehicle,
  getVehicleVerificationStatus,
};