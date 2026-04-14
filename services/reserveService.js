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
  const status = ride_status || 'active';

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

  const result = await rideDb.query(
    `INSERT INTO rides (
      rider_id,
      start_location,
      destination,
      total_distance_km,
      total_fare,
      available_seats,
      status,
      travel_date,
      travel_time,
      vehicle_type,
      gender_preference,
      note
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
    RETURNING ride_id, rider_id, status, travel_date, travel_time`,
    [
      userId,
      pickup_location,
      destination_location,
      Number(total_distance_km),
      Number(estimated_cost),
      seatCount,
      'reserve',
      travel_date,
      travel_time,
      vehicle,
      cleanedGenderPreference,
      cleanedNote,
    ]
  );

  return result.rows[0];
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
    `SELECT
        r.ride_id,
        r.start_location,
        r.destination,
        r.total_fare   AS fare,
        NULL           AS confirmed,
        r.status       AS ride_status,
        r.created_at
     FROM rides r
     WHERE r.rider_id = $1
       AND r.status = 'reserve'
     ORDER BY r.created_at DESC`,
    [userId]
  );

  return result.rows.map((row) => ({
    ride_id: row.ride_id,
    start_location: row.start_location,
    destination: row.destination,
    fare: row.fare,
    confirmed: row.confirmed,
    ride_status: row.ride_status,
    created_at: row.created_at,
    display_text: formatDisplayText(row),
  }));
};

module.exports = {
  createReserve,
  validateSchedule,
  validatePreferences,
  calculateReserveRide,
  getUpcomingReserve,
};
