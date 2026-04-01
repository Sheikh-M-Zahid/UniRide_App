const rideDb = require('../config/rideDb');

const createSession = async (payload, user = null) => {
  const userId = user?.userId || user?.user_id || null;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  const {
    pickup_location,
    destination_location,
    trip_date,
    trip_time,
    vehicle_type,
    vehicle_number,
    available_seats,
    preferred_gender,
    fare_per_person,
  } = payload;

  if (!pickup_location) {
    throw new Error('Pickup location is required.');
  }

  if (!destination_location) {
    throw new Error('Destination is required.');
  }

  if (!trip_date) {
    throw new Error('Trip date is required.');
  }

  if (!trip_time) {
    throw new Error('Trip time is required.');
  }

  if (!vehicle_type) {
    throw new Error('Vehicle type is required.');
  }

  const seatCount = Number(available_seats);
  const fare = Number(fare_per_person);

  if (Number.isNaN(seatCount) || seatCount <= 0) {
    throw new Error('Available seats must be greater than 0.');
  }

  if (Number.isNaN(fare) || fare <= 0) {
    throw new Error('Fare per person must be greater than 0.');
  }

  const validVehicles = ['Private Car', 'CNG', 'Rickshaw'];
  if (!validVehicles.includes(vehicle_type)) {
    throw new Error('Invalid vehicle type.');
  }

  const validGender = ['Male', 'Female', 'Any'];
  if (preferred_gender && !validGender.includes(preferred_gender)) {
    throw new Error('Invalid gender preference.');
  }

  const today = new Date();
  const selectedDate = new Date(trip_date);

  today.setHours(0, 0, 0, 0);
  selectedDate.setHours(0, 0, 0, 0);

  if (selectedDate < today) {
    throw new Error('Trip date cannot be in the past.');
  }

  const result = await rideDb.query(
    `INSERT INTO company_sharing_sessions (
      created_by,
      start_location,
      destination,
      status,
      trip_date,
      trip_time,
      vehicle_type,
      vehicle_number,
      total_seats,
      preferred_gender,
      fare_per_person
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    RETURNING session_id, status, trip_date, trip_time`,
    [
      userId,
      pickup_location,
      destination_location,
      'scheduled',
      trip_date,
      trip_time,
      vehicle_type,
      vehicle_number || null,
      seatCount,
      preferred_gender || 'Any',
      fare,
    ]
  );

  return result.rows[0];
};

const getActiveSessions = async (user = null, queryParams = {}) => {
  const { search } = queryParams;

  let query = `
    SELECT
      cs.session_id,
      u.first_name || ' ' || u.last_name AS creator_name,
      cs.start_location AS pickup_location,
      cs.destination AS destination_location,
      cs.trip_date,
      cs.trip_time,
      cs.vehicle_type,
      cs.total_seats - COUNT(cp.user_id) AS available_seats,
      COUNT(cp.user_id) AS joined_members,
      cs.fare_per_person
    FROM company_sharing_sessions cs
    LEFT JOIN company_participants cp
      ON cs.session_id = cp.session_id
    LEFT JOIN users u
      ON cs.created_by = u.user_id
    WHERE
      cs.status IN ('scheduled', 'active')
      AND cs.trip_date >= CURRENT_DATE
  `;

  const values = [];
  let index = 1;

  if (search) {
    query += `
      AND (
        LOWER(cs.start_location) LIKE LOWER($${index})
        OR LOWER(cs.destination) LIKE LOWER($${index})
        OR LOWER(u.first_name) LIKE LOWER($${index})
        OR LOWER(u.last_name) LIKE LOWER($${index})
      )
    `;
    values.push(`%${search}%`);
    index++;
  }

  query += `
    GROUP BY cs.session_id, u.user_id
    HAVING (cs.total_seats - COUNT(cp.user_id)) > 0
    ORDER BY cs.trip_date ASC, cs.trip_time ASC
  `;

  const result = await rideDb.query(query, values);

  return result.rows.map((row) => ({
    session_id: row.session_id,
    creator_name: row.creator_name,
    pickup_location: row.pickup_location,
    destination_location: row.destination_location,
    trip_date: row.trip_date,
    trip_time: row.trip_time,
    vehicle_type: row.vehicle_type,
    available_seats: Number(row.available_seats),
    joined_members: Number(row.joined_members),
    fare_per_person: Number(row.fare_per_person),
  }));
};

const getHistory = async (user = null, queryParams = {}) => {
  const userId = user?.userId || user?.user_id || null;

  if (!userId) {
    throw new Error('Unauthorized.');
  }

  const { search, status, safety } = queryParams;

  let query = `
    SELECT
      cs.session_id AS trip_id,
      u.first_name || ' ' || u.last_name AS creator_name,
      u.phone AS creator_phone,
      u.profile_picture AS creator_photo_url,
      cs.vehicle_type,
      cs.start_location AS pickup_location,
      cs.destination AS destination_location,
      cs.trip_date,
      cs.trip_time,
      cs.total_seats,
      COUNT(cp.user_id) AS joined_members,
      cs.total_cost,
      cs.per_seat_cost,
      cs.fare_per_person,
      cs.status AS trip_status,
      cs.has_safety_flag,
      cs.safety_note,
      u.university_email
    FROM company_sharing_sessions cs
    LEFT JOIN company_participants cp
      ON cs.session_id = cp.session_id
    LEFT JOIN users u
      ON cs.created_by = u.user_id
    WHERE cs.created_by = $1
  `;

  const values = [userId];
  let index = 2;

  if (search) {
    query += `
      AND (
        LOWER(cs.start_location) LIKE LOWER($${index})
        OR LOWER(cs.destination) LIKE LOWER($${index})
        OR LOWER(u.first_name) LIKE LOWER($${index})
        OR LOWER(u.last_name) LIKE LOWER($${index})
      )
    `;
    values.push(`%${search}%`);
    index++;
  }

  if (status && status !== 'all') {
    query += ` AND LOWER(cs.status) = LOWER($${index})`;
    values.push(status);
    index++;
  }

  if (safety && safety !== 'all') {
    if (safety === 'safe') {
      query += ` AND cs.has_safety_flag = FALSE`;
    } else if (safety === 'flagged') {
      query += ` AND cs.has_safety_flag = TRUE`;
    }
  }

  query += `
    GROUP BY cs.session_id, u.user_id
    ORDER BY cs.trip_date DESC, cs.trip_time DESC
  `;

  const result = await rideDb.query(query, values);

  return result.rows.map((row) => ({
    trip_id: `SC-${String(row.trip_id).substring(0, 6)}`,
    creator_name: row.creator_name,
    creator_type: getOccupation(row.university_email),
    creator_phone: row.creator_phone,
    creator_photo_url: row.creator_photo_url || '',
    vehicle_type: row.vehicle_type || 'Rental Car',
    pickup_location: row.pickup_location,
    destination_location: row.destination_location,
    trip_date: row.trip_date,
    trip_time: row.trip_time,
    total_seats: Number(row.total_seats),
    joined_members: Number(row.joined_members),
    total_cost: Number(row.total_cost || 0),
    per_seat_cost: Number(row.per_seat_cost || 0),
    fare_per_person: Number(row.fare_per_person || 0),
    trip_status: row.trip_status,
    has_safety_flag: row.has_safety_flag,
    safety_note: row.safety_note || '',
  }));
};

const getOccupation = (email) => {
  if (!email) return 'Student';

  const normalizedEmail = String(email).toLowerCase();

  if (normalizedEmail.includes('@std')) return 'Student';
  if (normalizedEmail.includes('@ewubd.edu')) return 'Faculty';

  return 'Student';
};

module.exports = {
  createSession,
  getActiveSessions,
  getHistory,
};