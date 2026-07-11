const rideDb = require('../config/rideDb');
const cbfService = require('./cbfService');

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
  ride_id, passenger_id, fare, confirmed
)
VALUES ($1, $2, $3, FALSE)
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
     SET status = $1,
         completed_at = CASE WHEN $1 = 'completed' THEN CURRENT_TIMESTAMP ELSE completed_at END,
         cancelled_at = CASE WHEN $1 = 'cancelled' THEN CURRENT_TIMESTAMP ELSE cancelled_at END
     WHERE ride_id = $2 AND rider_id = $3
     RETURNING *`,
    [status, rideId, riderId]
  );

  if (result.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  const ride = result.rows[0];

  // শুধু completed হলে transaction logic চলবে
  if (status === 'completed') {
    const participantsRes = await rideDb.query(
      `SELECT passenger_id, fare
       FROM ride_participants
       WHERE ride_id = $1`,
      [rideId]
    );

    for (const participant of participantsRes.rows) {
      const fare = Number(participant.fare || 0);
      if (fare <= 0) continue;

      const passengerDueRef = `ride_due_${rideId}_${participant.passenger_id}`;
      const riderEarnRef = `ride_earn_${rideId}_${participant.passenger_id}`;

      // Duplicate check — একই ride এর জন্য দুইবার যেন না হয়
      const alreadyDone = await rideDb.query(
        `SELECT 1 FROM transactions WHERE reference_id = $1 LIMIT 1`,
        [riderEarnRef]
      );
      if (alreadyDone.rowCount > 0) continue;

      // Passenger এর due বাড়াও
      await rideDb.query(
        `UPDATE users SET due_balance = due_balance + $1 WHERE user_id = $2`,
        [fare, participant.passenger_id]
      );

      await rideDb.query(
        `INSERT INTO transactions (user_id, amount, type, method, reference_id, status)
         VALUES ($1, $2, 'debit', 'ride_fare', $3, 'completed')`,
        [participant.passenger_id, fare, passengerDueRef]
      );

      // Rider এর earning add করো
      await rideDb.query(
        `INSERT INTO transactions (user_id, amount, type, method, reference_id, status)
         VALUES ($1, $2, 'credit', 'ride_income', $3, 'completed')`,
        [riderId, fare, riderEarnRef]
      );
    }
  }

  return ride;
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

const searchRides = async (payload) => {
  const { pickup_lat, pickup_lng, destination_lat, destination_lng } = payload;

  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  //  Passenger এর route distance (ক → খ) 
  const url = `https://maps.googleapis.com/maps/api/distancematrix/json` +
    `?destinations=${destination_lat},${destination_lng}` +
    `&origins=${pickup_lat},${pickup_lng}` +
    `&key=${apiKey}`;

  let distance_km = 0;
  let estimated_time = 0;

  try {
    const mapResponse = await fetch(url);
    const mapData = await mapResponse.json();

    if (
      mapData.status === 'OK' &&
      mapData.rows[0].elements[0].status === 'OK'
    ) {
      const element = mapData.rows[0].elements[0];
      distance_km = element.distance.value / 1000;
      estimated_time = Math.ceil(element.duration.value / 60);
    }
  } catch (error) {
    console.error('Maps API Fetch Error:', error);
    throw new Error('Failed to fetch dynamic distance from map.');
  }

  // Vehicle rates DB থেকে নাও 
  const ratesRes = await rideDb.query(`
    SELECT DISTINCT ON (vehicle_type)
      vehicle_type, per_km_rate, base_fare
    FROM vehicle_rates
    WHERE is_active = TRUE
    ORDER BY vehicle_type, effective_from DESC
  `);

  const rateMap = {
    bike: { per_km_rate: 10, base_fare: 0 },
    car:  { per_km_rate: 15, base_fare: 0 },
  };

  for (const row of ratesRes.rows) {
    rateMap[row.vehicle_type] = {
      per_km_rate: Number(row.per_km_rate),
      base_fare:   Number(row.base_fare || 0),
    };
  }

  //Active rides + rider info fetch 
  const result = await rideDb.query(
    `SELECT
       r.ride_id,
       r.rider_id,
       r.available_seats,
       r.travel_time,
       r.travel_date,
       r.gender_preference,
       r.vehicle_type,
       r.status,
       r.destination,
       r.start_location,
       u.first_name,
       u.last_name,
       u.phone,
       u.rating,
       v.company,
       v.model,
       v.number_plate,
       ll.latitude  AS rider_lat,
       ll.longitude AS rider_lng
     FROM rides r
     JOIN users u ON r.rider_id = u.user_id
     LEFT JOIN vehicles v ON r.vehicle_id = v.vehicle_id
     LEFT JOIN LATERAL (
       SELECT latitude, longitude
       FROM live_locations
       WHERE user_id = r.rider_id
       ORDER BY updated_at DESC
       LIMIT 1
     ) ll ON TRUE
     WHERE r.status IN ('assigned', 'ongoing')
       AND r.available_seats > 0
     ORDER BY r.created_at DESC`
  );

  const rides = result.rows;
  if (!rides.length) {
    return {
      distance_km: parseFloat(distance_km.toFixed(2)),
      estimated_time,
      estimated_fare: 0,
      availableRides: [],
    };
  }

  // Rider থেকে Passenger পর্যন্ত দূরত্ব batch এ নাও 
  const validRiders = rides
    .map((r, i) => ({ i, lat: r.rider_lat, lng: r.rider_lng }))
    .filter(r => r.lat !== null && r.lng !== null);

  // Google Distance Matrix — একটাই call, সব rider এর জন্য
  let riderDistances = {}; // index → { distanceKm, withinRoute }

  if (validRiders.length) {
    const destinations = validRiders
      .map(r => `${r.lat},${r.lng}`)
      .join('|');

    const matrixUrl =
      `https://maps.googleapis.com/maps/api/distancematrix/json` +
      `?origins=${pickup_lat},${pickup_lng}` +
      `&destinations=${destinations}` +
      `&key=${apiKey}`;

    try {
      const mRes = await fetch(matrixUrl);
      const mData = await mRes.json();

      if (mData.status === 'OK') {
        mData.rows[0].elements.forEach((el, idx) => {
          if (el.status === 'OK') {
            const dKm = el.distance.value / 1000;
            riderDistances[validRiders[idx].i] = dKm;
          }
        });
      }
    } catch (_) { /* fallback: haversine */ }
  }

  // Haversine fallback 
  const haversine = (lat1, lng1, lat2, lng2) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  };

  //  প্রতিটা ride এর fare calculate 
  /*
   *Fare logic:
    base_fare = শুধু তখনই add হবে যখন (distance_km * per_km_rate) < base_fare
    অর্থাৎ: fare = max(base_fare, distance_km * per_km_rate)
   
   * Rider surcharge logic:
    Rider যদি passenger এর পথে থাকে (rider_dist ≤ 2km) → অতিরিক্ত ০ টাকা
    Rider যদি উল্টো দিক থেকে আসে (rider_dist > 2km) → +৫ টাকা প্রতি km
   */

  const DETOUR_THRESHOLD_KM = 2;
  const DETOUR_RATE_PER_KM  = 5;

  const availableRides = rides.map((ride, i) => {
    const vType = String(ride.vehicle_type || '').trim().toLowerCase();
    const rate  = rateMap[vType] ?? rateMap.car;

    // Main route fare
    const routeFare = distance_km * rate.per_km_rate;
    const baseFare  = routeFare < rate.base_fare ? rate.base_fare : routeFare;

    // Rider distance থেকে surcharge
    let riderDistKm = riderDistances[i] ?? null;
    if (riderDistKm === null && ride.rider_lat !== null) {
      riderDistKm = haversine(
        pickup_lat, pickup_lng,
        Number(ride.rider_lat), Number(ride.rider_lng)
      );
    }

    let surcharge = 0;
    if (riderDistKm !== null && riderDistKm > DETOUR_THRESHOLD_KM) {
      surcharge = Math.round(riderDistKm * DETOUR_RATE_PER_KM);
    }

    const estimatedFare = Math.round(baseFare) + surcharge;

    return {
      ride_id:          ride.ride_id,
      rider_id:         ride.rider_id,
      vehicle_type:     vType === 'bike' ? 'Bike' : vType === 'car' ? 'Car' : 'Vehicle',
      available_seats:  Number(ride.available_seats || 0),
      travel_time:      ride.travel_time || '',
      gender_preference: ride.gender_preference || 'any',
      company:          ride.company || '',
      model:            ride.model   || '',
      number_plate:     ride.number_plate || '',
      total_distance_km: parseFloat(distance_km.toFixed(2)),
      estimatedFare,
      riderDistanceKm:  riderDistKm !== null
                          ? parseFloat(riderDistKm.toFixed(2))
                          : null,
      //Rider info flat করে দিলাম 
      rider: {
        name:   `${ride.first_name || ''} ${ride.last_name || ''}`.trim(),
        phone:  ride.phone || '',
        rating: Number(ride.rating || 5),
      },
    };
  });

  // Route summary fare (car rate দিয়ে)
  const carRate = rateMap.car;
  const routeFareCar = distance_km * carRate.per_km_rate;
  const estimated_fare = Math.round(
    routeFareCar < carRate.base_fare ? carRate.base_fare : routeFareCar
  );

  return {
    distance_km:    parseFloat(distance_km.toFixed(2)),
    estimated_time,
    estimated_fare,
    availableRides,
  };
};

module.exports = {
  createRide,
  listActiveRides,
  getRideDetails,
  joinRide,
  confirmParticipant,
  changeRideStatus,
  listMyCreatedRides,
  listJoinedRides,
  searchRides, 
};
