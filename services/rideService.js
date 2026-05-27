const rideDb = require('../config/rideDb');

const createRide = async (userId, payload) => {
  const {
    vehicle_id,
    start_location,
    destination,
    total_distance_km,
    per_km_rate,
    total_fare,
    available_seats,
    status,
  } = payload;

  const result = await rideDb.query(
    `INSERT INTO rides (
      rider_id, vehicle_id, start_location, destination,
      total_distance_km, per_km_rate, total_fare, available_seats, status
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
    RETURNING *`,
    [
      userId,
      vehicle_id,
      start_location,
      destination,
      total_distance_km,
      per_km_rate,
      total_fare,
      available_seats,
      status || 'Active',
    ]
  );

  return result.rows[0];
};

const listActiveRides = async () => {
  const result = await rideDb.query(
    `SELECT r.*, 
            u.first_name, u.last_name, u.university_email, u.phone, u.rating,
            v.vehicle_type, v.company, v.model, v.number_plate
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     WHERE r.status IN ('Active','Reserve','Processing')
     ORDER BY r.created_at DESC`
  );

  return result.rows;
};

const getRideDetails = async (rideId) => {
  const rideResult = await rideDb.query(
    `SELECT r.*, 
            u.first_name, u.last_name, u.university_email, u.phone, u.rating,
            v.vehicle_type, v.company, v.model, v.number_plate, v.total_seats
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     WHERE r.ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const participantsResult = await rideDb.query(
    `SELECT rp.*, u.first_name, u.last_name, u.university_email, u.phone
     FROM ride_participants rp
     JOIN users u ON rp.passenger_id = u.user_id
     WHERE rp.ride_id = $1
     ORDER BY rp.participant_id DESC`,
    [rideId]
  );

  return {
    ride: rideResult.rows[0],
    participants: participantsResult.rows,
  };
};

const joinRide = async (rideId, passengerId, fare) => {
  const rideResult = await rideDb.query(
    `SELECT * FROM rides WHERE ride_id = $1`,
    [rideId]
  );

  if (rideResult.rowCount === 0) {
    throw new Error('Ride not found.');
  }

  const ride = rideResult.rows[0];

  if (ride.rider_id === passengerId) {
    throw new Error('Rider cannot join own ride.');
  }

  const existing = await rideDb.query(
    `SELECT participant_id FROM ride_participants
     WHERE ride_id = $1 AND passenger_id = $2`,
    [rideId, passengerId]
  );

  if (existing.rowCount > 0) {
    throw new Error('You already joined this ride.');
  }

  const totalJoinedResult = await rideDb.query(
    `SELECT COUNT(*)::int AS total
     FROM ride_participants
     WHERE ride_id = $1`,
    [rideId]
  );

  if (totalJoinedResult.rows[0].total >= ride.available_seats) {
    throw new Error('No available seats left.');
  }

  const result = await rideDb.query(
    `INSERT INTO ride_participants (
      ride_id, passenger_id, fare, rider_payment, confirmed
    )
    VALUES ($1, $2, $3, 'Unpaid', FALSE)
    RETURNING *`,
    [rideId, passengerId, fare]
  );

  return result.rows[0];
};

const confirmParticipant = async (rideId, riderId, participantId) => {
  const ownership = await rideDb.query(
    `SELECT ride_id FROM rides WHERE ride_id = $1 AND rider_id = $2`,
    [rideId, riderId]
  );

  if (ownership.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  const result = await rideDb.query(
    `UPDATE ride_participants
     SET confirmed = TRUE
     WHERE participant_id = $1 AND ride_id = $2
     RETURNING *`,
    [participantId, rideId]
  );

  if (result.rowCount === 0) {
    throw new Error('Participant not found.');
  }

  return result.rows[0];
};

const changeRideStatus = async (rideId, riderId, status) => {
  const result = await rideDb.query(
    `UPDATE rides
     SET status = $1
     WHERE ride_id = $2 AND rider_id = $3
     RETURNING *`,
    [status, rideId, riderId]
  );

  if (result.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  return result.rows[0];
};

const listMyCreatedRides = async (riderId) => {
  const result = await rideDb.query(
    `SELECT *
     FROM rides
     WHERE rider_id = $1
     ORDER BY created_at DESC`,
    [riderId]
  );

  return result.rows;
};

const listJoinedRides = async (passengerId) => {
  const result = await rideDb.query(
    `SELECT rp.*, r.*, u.first_name, u.last_name, u.phone
     FROM ride_participants rp
     JOIN rides r ON rp.ride_id = r.ride_id
     JOIN users u ON r.rider_id = u.user_id
     WHERE rp.passenger_id = $1
     ORDER BY r.created_at DESC`,
    [passengerId]
  );

  return result.rows;
};


// ==========================================
// নতুন যোগ করা অংশ এখান থেকে শুরু
// ==========================================

const searchRides = async (payload) => {
  const { pickup_lat, pickup_lng, destination_lat, destination_lng } = payload;

  const apiKey = process.env.GOOGLE_MAPS_API_KEY; 
  const url = `https://maps.googleapis.com/maps/api/distancematrix/json?destinations=${destination_lat},${destination_lng}&origins=${pickup_lat},${pickup_lng}&key=${apiKey}`;

  let distance_km = 0;
  let estimated_time = 0; 

  try {
    const mapResponse = await fetch(url);
    const mapData = await mapResponse.json();

    if (mapData.status === 'OK' && mapData.rows[0].elements[0].status === 'OK') {
      const element = mapData.rows[0].elements[0];
      distance_km = element.distance.value / 1000;
      estimated_time = Math.ceil(element.duration.value / 60);
    } else {
      console.warn('Google Maps API Warning: Could not calculate precise route.');
    }
  } catch (error) {
    console.error("Maps API Fetch Error:", error);
    throw new Error('Failed to fetch dynamic distance from map.');
  }

  // আপনার পছন্দমতো রেট পরিবর্তন করে নিতে পারেন
  const base_fare = 40; 
  const per_km_rate = 7; 
  const per_minute_rate = 2; 
  
  const estimated_fare = Math.ceil(base_fare + (distance_km * per_km_rate) + (estimated_time * per_minute_rate));

  const result = await rideDb.query(
    `SELECT r.*, 
            u.first_name, u.last_name, u.university_email, u.phone, u.rating,
            v.vehicle_type, v.company, v.model, v.number_plate, v.total_seats
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     WHERE r.status IN ('assigned', 'ongoing')
       AND r.available_seats > 0
     ORDER BY r.created_at DESC`
  );

  return {
    distance_km: parseFloat(distance_km.toFixed(2)),
    estimated_time: estimated_time,
    estimated_fare: estimated_fare,
    availableRides: result.rows
  };
};

// ==========================================
// নতুন যোগ করা অংশ এখানে শেষ
// ==========================================


module.exports = {
  createRide,
  listActiveRides,
  getRideDetails,
  joinRide,
  confirmParticipant,
  changeRideStatus,
  listMyCreatedRides,
  listJoinedRides,
  searchRides, // <-- এটি নতুন যোগ করা হয়েছে
};
