const rideDb = require('../config/rideDb');
const {
  isValidLatitude,
  isValidLongitude,
  haversineDistanceKm,
} = require('../utils/geo');
const {
  isValidDate,
  isValidTime,
  isPastDate,
  isBeyondLimit,
} = require('../utils/dateHelper');
const {
  isValidGenderPreference,
  isValidVehicleType,
} = require('../utils/preferenceHelper');

const BASE_FARE = 40;
const PER_KM_FARE = 12;
const AVERAGE_SPEED_KMH = 25;
const MINIMUM_TIME_MIN = 5;

const roundToOneDecimal = (value) => {
  return Math.round(value * 10) / 10;
};

const roundToNearestInteger = (value) => {
  return Math.round(value);
};

const formatDisplayText = ({
  start_location,
  destination,
  fare,
  ride_status,
}) => {
  const from = start_location || 'Unknown';
  const to = destination || 'Unknown';
  const fareText = fare ? `BDT ${fare}` : 'BDT 0';
    const status = ride_status || 'pending';

  return `${from} → ${to} | Fare: ${fareText} | ${status}`;
};

const validateSchedule = async (payload, user = null) => {
  const {
    pickup_location,
    destination_location,
    total_distance_km,
    estimated_travel_minutes,
    estimated_cost,
    travel_date,
    travel_time,
  } = payload;

  const userId = user?.userId || user?.user_id || null;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  if (
    !pickup_location ||
    !destination_location ||
    !travel_date ||
    !travel_time
  ) {
    throw new Error('Pickup location, destination, travel date and time are required.');
  }

  if (
    !total_distance_km ||
    Number(total_distance_km) <= 0 ||
    !estimated_travel_minutes ||
    Number(estimated_travel_minutes) <= 0 ||
    !estimated_cost ||
    Number(estimated_cost) <= 0
  ) {
    throw new Error('Invalid trip data.');
  }

  if (!isValidDate(travel_date)) {
    throw new Error('Invalid travel date.');
  }

  if (isPastDate(travel_date)) {
    throw new Error('Selected date cannot be in the past.');
  }

  if (isBeyondLimit(travel_date, 90)) {
    throw new Error('You can reserve only up to 90 days in advance.');
  }

  if (!isValidTime(travel_time)) {
    throw new Error('Invalid travel time format.');
  }

  return {
    pickup_location,
    destination_location,
    total_distance_km: Number(total_distance_km),
    estimated_travel_minutes: Number(estimated_travel_minutes),
    estimated_cost: Number(estimated_cost),
    travel_date,
    travel_time,
  };
};

const validatePreferences = async (payload, user = null) => {
  const userId = user?.userId || user?.user_id || null;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  const {
    pickup_location,
    destination_location,
    travel_date,
    travel_time,
    total_distance_km,
    estimated_travel_minutes,
    estimated_cost,
    selected_seats,
    gender_preference,
    vehicle_type,
    note,
  } = payload;

  if (
    !pickup_location ||
    !destination_location ||
    !travel_date ||
    !travel_time
  ) {
    throw new Error('Missing trip or schedule information.');
  }

  if (
    !total_distance_km ||
    Number(total_distance_km) <= 0 ||
    !estimated_travel_minutes ||
    Number(estimated_travel_minutes) <= 0 ||
    !estimated_cost ||
    Number(estimated_cost) <= 0
  ) {
    throw new Error('Invalid trip calculation data.');
  }

  if (!selected_seats) {
    throw new Error('Selected seats are required.');
  }

  const seatCount = Number(selected_seats);

  if (Number.isNaN(seatCount) || seatCount < 1 || seatCount > 4) {
    throw new Error('Selected seats must be between 1 and 4.');
  }

  if (!vehicle_type) {
    throw new Error('Vehicle type is required.');
  }

  if (!isValidVehicleType(vehicle_type)) {
    throw new Error('Invalid vehicle type.');
  }

  const vehicle = String(vehicle_type).toLowerCase();

  if (vehicle === 'bike' && seatCount !== 1) {
    throw new Error('Bike ride allows only 1 seat.');
  }

  if (!isValidGenderPreference(gender_preference)) {
    throw new Error('Invalid gender preference.');
  }

  const cleanedNote = note ? String(note).trim() : null;

  if (cleanedNote && cleanedNote.length > 180) {
    throw new Error('Note cannot exceed 180 characters.');
  }

  return {
    selected_seats: seatCount,
    gender_preference: gender_preference || null,
    vehicle_type: vehicle,
    note: cleanedNote,
  };
};

const calculateReserveRide = async (payload) => {
  const {
    pickup_lat,
    pickup_lng,
    destination_lat,
    destination_lng,
  } = payload;

  const allFieldsProvided =
    pickup_lat !== undefined &&
    pickup_lng !== undefined &&
    destination_lat !== undefined &&
    destination_lng !== undefined;

  if (!allFieldsProvided) {
    throw new Error('All coordinates are required.');
  }

  const pickupLat = Number(pickup_lat);
  const pickupLng = Number(pickup_lng);
  const destinationLat = Number(destination_lat);
  const destinationLng = Number(destination_lng);

  if (
    !isValidLatitude(pickupLat) ||
    !isValidLongitude(pickupLng) ||
    !isValidLatitude(destinationLat) ||
    !isValidLongitude(destinationLng)
  ) {
    throw new Error('Invalid coordinates.');
  }

  const rawDistanceKm = haversineDistanceKm(
    pickupLat,
    pickupLng,
    destinationLat,
    destinationLng
  );

  const distanceKm = roundToOneDecimal(rawDistanceKm);

  const estimatedTimeMin = Math.max(
    MINIMUM_TIME_MIN,
    roundToNearestInteger((rawDistanceKm / AVERAGE_SPEED_KMH) * 60)
  );

  const estimatedCost = roundToNearestInteger(
    BASE_FARE + rawDistanceKm * PER_KM_FARE
  );

  return {
    distance_km: distanceKm,
    estimated_time_min: estimatedTimeMin,
    estimated_cost: estimatedCost,
  };
};

const createReserve = async (payload, user = null) => {
  const userId = user?.userId || user?.user_id || null;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  const {
    pickup_location,
    destination_location,
    travel_date,
    travel_time,
    selected_seats,
    gender_preference,
    vehicle_type,
    total_distance_km,
    estimated_travel_minutes,
    estimated_cost,
    note,
  } = payload;

  await validateSchedule(payload, user);
  const preferenceData = await validatePreferences(payload, user);

  const vehicle = preferenceData.vehicle_type;
  const seatCount = preferenceData.selected_seats;
  const cleanedNote = preferenceData.note;
  const cleanedGenderPreference = preferenceData.gender_preference;

  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const insertReserveQuery = `
      INSERT INTO reserves (
        user_id,
        pickup_location,
        destination_location,
        travel_date,
        travel_time,
        selected_seats,
        gender_preference,
        vehicle_type,
        total_distance_km,
        estimated_travel_minutes,
        estimated_cost,
        note,
        status
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'pending'
      )
      RETURNING
        reserve_id,
        user_id,
        pickup_location,
        destination_location,
        travel_date,
        travel_time,
        selected_seats,
        gender_preference,
        vehicle_type,
        total_distance_km,
        estimated_travel_minutes,
        estimated_cost,
        note,
        status,
        created_at
    `;

    const reserveResult = await client.query(insertReserveQuery, [
      userId,
      pickup_location,
      destination_location,
      travel_date,
      travel_time,
      seatCount,
      cleanedGenderPreference,
      vehicle,
      Number(total_distance_km),
      Number(estimated_travel_minutes),
      Number(estimated_cost),
      cleanedNote,
    ]);

    const reserve = reserveResult.rows[0];

    await client.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        target_role,
        related_id
      )
      SELECT
        v.user_id,
        'New Reserve Request',
        $1,
        'reserve_request',
        FALSE,
        'rider',
        $2
      FROM vehicles v
      INNER JOIN users u ON u.user_id = v.user_id
      WHERE u.account_status = 'active'
      GROUP BY v.user_id
      `,
      [
        `${pickup_location} → ${destination_location} | ${travel_date} ${travel_time} | ৳${Number(estimated_cost)}`,
        reserve.reserve_id,
      ]
    );

    await client.query('COMMIT');
    return reserve;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const getUpcomingReserve = async (userId) => {
  const userResult = await rideDb.query(
    `SELECT user_id, account_status
     FROM users
     WHERE user_id = $1`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    throw new Error('User account not found.');
  }

  const userData = userResult.rows[0];

  if (String(userData.account_status).toLowerCase() !== 'active') {
    throw new Error('Your account is not active.');
  }

  const result = await rideDb.query(
    `
    SELECT
      r.reserve_id,
      r.pickup_location,
      r.destination_location,
      r.total_distance_km,
      r.estimated_travel_minutes,
      r.estimated_cost,
      r.travel_date,
      r.travel_time,
      r.status,
      r.created_at,
      rr.rider_id,
      ru.first_name AS rider_first_name,
      ru.last_name AS rider_last_name,
      ru.phone AS rider_phone
    FROM reserves r
    LEFT JOIN reserve_rider_matches rr
      ON rr.reserve_id = r.reserve_id
     AND rr.is_selected = TRUE
    LEFT JOIN users ru
      ON ru.user_id = rr.rider_id
    WHERE r.user_id = $1
      AND r.status IN ('pending', 'confirmed', 'ongoing')
    ORDER BY r.created_at DESC
    `,
    [userId]
  );

  return result.rows.map((row) => ({
    reserve_id: row.reserve_id,
    pickup_location: row.pickup_location,
    destination_location: row.destination_location,
    total_distance_km: Number(row.total_distance_km || 0),
    estimated_travel_minutes: Number(row.estimated_travel_minutes || 0),
    estimated_cost: Number(row.estimated_cost || 0),
    travel_date: row.travel_date,
    travel_time: row.travel_time,
    status: row.status,
    rider_id: row.rider_id,
    rider_name: row.rider_first_name
      ? `${row.rider_first_name} ${row.rider_last_name || ''}`.trim()
      : null,
    rider_phone: row.rider_phone || null,
    created_at: row.created_at,
  }));
};

const cancelReserve = async (reserveId, userId) => {
  const result = await rideDb.query(
    `
    UPDATE reserves
    SET status = 'cancelled'
    WHERE reserve_id = $1
      AND user_id = $2
      AND status = 'pending'
    RETURNING reserve_id, status
    `,
    [reserveId, userId]
  );

  if (result.rowCount === 0) {
    throw new Error('Only pending reserve requests can be cancelled.');
  }

  return result.rows[0];
};

const getReserveActivityList = async ({ userId, type = 'all', time = 'today' }) => {
  let timeCondition = '';
  const params = [userId];
  let paramIndex = 2;

  if (time === 'today') {
    timeCondition = `AND r.created_at >= CURRENT_DATE`;
  } else if (time === 'this_week') {
    timeCondition = `AND r.created_at >= DATE_TRUNC('week', CURRENT_DATE)`;
  } else if (time === 'this_month') {
    timeCondition = `AND r.created_at >= DATE_TRUNC('month', CURRENT_DATE)`;
  }

  let typeCondition = '';
  if (type === 'reserved') {
    typeCondition = `AND r.status IN ('pending', 'confirmed', 'ongoing')`;
  } else if (type === 'completed') {
    typeCondition = `AND r.status = 'completed'`;
  } else if (type === 'cancelled') {
    typeCondition = `AND r.status = 'cancelled'`;
  }

  const summaryResult = await rideDb.query(
    `
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE status = 'completed')::int AS completed,
      COUNT(*) FILTER (WHERE status = 'cancelled')::int AS cancelled,
      0::float AS earnings
    FROM reserves
    WHERE user_id = $1
    ${timeCondition}
    `,
    params
  );

  const listResult = await rideDb.query(
    `
    SELECT
      r.reserve_id,
      r.pickup_location,
      r.destination_location,
      r.total_distance_km,
      r.estimated_travel_minutes,
      r.estimated_cost,
      r.travel_date,
      r.travel_time,
      r.status,
      r.created_at,
      rr.rider_id,
      u.first_name,
      u.last_name,
      u.phone
    FROM reserves r
    LEFT JOIN reserve_rider_matches rr
      ON rr.reserve_id = r.reserve_id
     AND rr.is_selected = TRUE
    LEFT JOIN users u
      ON u.user_id = rr.rider_id
    WHERE r.user_id = $1
    ${timeCondition}
    ${typeCondition}
    ORDER BY r.created_at DESC
    `,
    params
  );

  return {
    summary: summaryResult.rows[0] || {
      total: 0,
      completed: 0,
      cancelled: 0,
      earnings: 0,
    },
    activities: listResult.rows.map((row) => ({
      id: row.reserve_id,
      item_type: 'reserve',
      title: 'Reserved Ride',
      name: row.first_name
        ? `${row.first_name} ${row.last_name || ''}`.trim()
        : 'Waiting for rider',
      phone: row.phone || 'Not assigned yet',
      pickup: row.pickup_location,
      destination: row.destination_location,
      time: `${row.travel_time ?? ''}`,
      fare: Number(row.estimated_cost || 0),
      date: row.travel_date,
      status: row.status,
      totalDistanceKm: Number(row.total_distance_km || 0),
      estimatedTravelMinutes: Number(row.estimated_travel_minutes || 0),
      riderName: row.first_name
        ? `${row.first_name} ${row.last_name || ''}`.trim()
        : null,
      riderPhone: row.phone || null,
      canCancel: row.status === 'pending',
    })),
    emptyState: 'No activity found',
  };
};

const assignRiderToReserve = async ({ reserveId, riderId }) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const reserveResult = await client.query(
      `
      SELECT reserve_id, user_id, status
      FROM reserves
      WHERE reserve_id = $1
      FOR UPDATE
      `,
      [reserveId]
    );

    if (reserveResult.rowCount === 0) {
      throw new Error('Reserve request not found.');
    }

    const reserve = reserveResult.rows[0];

    if (reserve.status !== 'pending') {
      throw new Error('This reserve request is no longer available.');
    }

    await client.query(
      `
      INSERT INTO reserve_rider_matches (
        reserve_id,
        rider_id,
        is_selected,
        accepted_at
      )
      VALUES ($1, $2, TRUE, CURRENT_TIMESTAMP)
      ON CONFLICT (reserve_id, rider_id)
      DO UPDATE SET
        is_selected = TRUE,
        accepted_at = CURRENT_TIMESTAMP
      `,
      [reserveId, riderId]
    );

    const updatedReserve = await client.query(
      `
      UPDATE reserves
      SET status = 'confirmed'
      WHERE reserve_id = $1
      RETURNING reserve_id, user_id, status
      `,
      [reserveId]
    );

    await client.query(
      `
      INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        target_role,
        related_id
      )
      VALUES ($1, 'Reserve Request Confirmed', 'A rider accepted your reserve request.', 'reserve_confirmed', FALSE, 'passenger', $2)
      `,
      [reserve.user_id, reserveId]
    );

    await client.query('COMMIT');
    return updatedReserve.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  createReserve,
  validateSchedule,
  validatePreferences,
  calculateReserveRide,
  getUpcomingReserve,
  cancelReserve,
  getReserveActivityList,
  assignRiderToReserve,
};
