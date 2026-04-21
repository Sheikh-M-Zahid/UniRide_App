const rideDb = require('../config/rideDb');
const { safeDistanceKm, calculateETA } = require('../utils/geo');
const { emitRideAvailable } = require('../utils/rideAvailabilityEmitter');
const { notifyUsersForRide } = require('./rideAlertMatcherService');

const DEFAULT_BIKE_RATE = 20;
const DEFAULT_CAR_RATE = 35;

const BLOCKING_RIDE_STATUSES = ['active', 'assigned', 'accepted', 'ongoing'];

const isValidNumber = (value) =>
  typeof value === 'number' && !Number.isNaN(value);

const normalizeVehicleTypeLabel = (vehicleType) => {
  const type = String(vehicleType || '').trim().toLowerCase();

  if (type === 'bike') return 'Bike';
  if (type === 'car') return 'Private Car';

  return vehicleType || 'Vehicle';
};

const getPerKmRate = async (vehicleType) => {
  const result = await rideDb.query(
    `SELECT per_km_rate
     FROM vehicle_rates
     WHERE vehicle_type = $1
       AND is_active = TRUE
     ORDER BY effective_from DESC
     LIMIT 1`,
    [String(vehicleType || '').trim().toLowerCase()]
  );

  if (result.rows.length) {
    return Number(result.rows[0].per_km_rate);
  }

  return String(vehicleType || '').trim().toLowerCase() === 'bike'
    ? DEFAULT_BIKE_RATE
    : DEFAULT_CAR_RATE;
};

const getCurrentActiveRide = async (userId) => {
  const result = await rideDb.query(
    `
    SELECT
      r.ride_id,
      r.start_location,
      r.destination,
      r.total_fare,
      r.travel_date,
      r.travel_time,
      r.status,
      r.vehicle_type,
      v.model,
      v.number_plate
    FROM rides r
    LEFT JOIN vehicles v
      ON v.vehicle_id = r.vehicle_id
    WHERE r.rider_id = $1
      AND r.status = ANY($2::text[])
    ORDER BY r.created_at DESC
    LIMIT 1
    `,
    [userId, BLOCKING_RIDE_STATUSES]
  );

  if (!result.rows.length) {
    return {
      hasActiveRide: false,
      activeRide: null,
    };
  }

  const row = result.rows[0];

  return {
    hasActiveRide: true,
    activeRide: {
      rideId: row.ride_id,
      pickup: row.start_location || 'Pickup unavailable',
      destination: row.destination || 'Destination unavailable',
      fare: Number(row.total_fare || 0),
      travelDate: row.travel_date,
      travelTime: row.travel_time,
      status: row.status,
      vehicleType: normalizeVehicleTypeLabel(row.vehicle_type),
      vehicleModel: row.model || '',
      vehicleNumber: row.number_plate || '',
    },
  };
};

const cancelCurrentRide = async ({ userId }) => {
  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    const rideRes = await client.query(
      `
      SELECT ride_id
      FROM rides
      WHERE rider_id = $1
        AND status = ANY($2::text[])
      ORDER BY created_at DESC
      LIMIT 1
      FOR UPDATE
      `,
      [userId, BLOCKING_RIDE_STATUSES]
    );

    if (!rideRes.rows.length) {
      throw new Error('No active ride found to cancel.');
    }

    const rideId = rideRes.rows[0].ride_id;

    await client.query(
      `
      UPDATE rides
      SET status = 'cancelled'
      WHERE ride_id = $1
      `,
      [rideId]
    );

    await client.query(
      `
      UPDATE rider_availability
      SET
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
      WHERE rider_id = $1
      `,
      [userId]
    );

    await client.query('COMMIT');

    return {
      cancelled: true,
      rideId,
      status: 'cancelled',
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const getActiveRideSetupData = async (userId) => {
  const userRes = await rideDb.query(
    `SELECT
        user_id,
        first_name,
        last_name
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  if (!userRes.rows.length) {
    throw new Error('User not found.');
  }

  const vehiclesRes = await rideDb.query(
    `SELECT
        vehicle_id,
        vehicle_type,
        company,
        model,
        number_plate,
        total_seats,
        verified,
        created_at
     FROM vehicles
     WHERE user_id = $1
     ORDER BY created_at DESC`,
    [userId]
  );

  const rider = userRes.rows[0];

  const vehicles = vehiclesRes.rows.map((vehicle) => ({
    vehicleId: vehicle.vehicle_id,
    vehicleType: vehicle.vehicle_type,
    vehicleTypeLabel: normalizeVehicleTypeLabel(vehicle.vehicle_type),
    company: vehicle.company || '',
    model: vehicle.model || '',
    vehicleNumber: vehicle.number_plate || '',
    totalSeats: Number(vehicle.total_seats || 0),
    verified: Boolean(vehicle.verified),
  }));

  return {
    riderName: `${rider.first_name || ''} ${rider.last_name || ''}`.trim(),
    vehicles,
  };
};

const activateRide = async ({ userId, body }) => {
  const {
    vehicleId,
    destination,
    destinationLat,
    destinationLng,
    currentLat,
    currentLng,
    currentLocationText = null,
    genderPreference = 'any',
    note = null,
    travelDate = null,
    travelTime = null,
  } = body;

  const existingRideRes = await rideDb.query(
    `
    SELECT ride_id, status, start_location, destination
    FROM rides
    WHERE rider_id = $1
      AND status = ANY($2::text[])
    ORDER BY created_at DESC
    LIMIT 1
    `,
    [userId, BLOCKING_RIDE_STATUSES]
  );

  if (existingRideRes.rows.length) {
    const existingRide = existingRideRes.rows[0];

    throw new Error(
      `You already have an active ride from ${existingRide.start_location || 'your current location'} to ${existingRide.destination || 'your destination'}. Cancel or complete it first.`
    );
  }

  if (
    !vehicleId ||
    !destination ||
    !isValidNumber(destinationLat) ||
    !isValidNumber(destinationLng) ||
    !isValidNumber(currentLat) ||
    !isValidNumber(currentLng)
  ) {
    throw new Error(
      'vehicleId, destination, destinationLat, destinationLng, currentLat and currentLng are required.'
    );
  }

  const vehicleRes = await rideDb.query(
    `SELECT
        vehicle_id,
        user_id,
        vehicle_type,
        company,
        model,
        number_plate,
        total_seats,
        verified
     FROM vehicles
     WHERE vehicle_id = $1
       AND user_id = $2
     LIMIT 1`,
    [vehicleId, userId]
  );

  if (!vehicleRes.rows.length) {
    throw new Error('Selected vehicle not found.');
  }

  const vehicle = vehicleRes.rows[0];

  const riderRes = await rideDb.query(
    `SELECT
        first_name,
        last_name
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [userId]
  );

  const rider = riderRes.rows[0];

  const startLocation =
    currentLocationText ||
    `${Number(currentLat).toFixed(5)}, ${Number(currentLng).toFixed(5)}`;

  // since current rides table has no destination text geocoder column from frontend picker is already destination
  const distanceKmRaw = safeDistanceKm(
    Number(currentLat),
    Number(currentLng),
    Number(destinationLat),
    Number(destinationLng)
  );

  if (distanceKmRaw === null) {
    throw new Error('Invalid current or destination coordinates.');
  }

  const totalDistanceKm = Number(distanceKmRaw.toFixed(2));
  const perKmRate = await getPerKmRate(vehicle.vehicle_type);
  const totalFare = Number((totalDistanceKm * perKmRate).toFixed(2));

  // safest offered seats = vehicle total seats
  const availableSeats = Math.max(Number(vehicle.total_seats || 1), 1);

  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    // rider availability active
    await client.query(
      `INSERT INTO rider_availability (
        rider_id,
        is_active,
        current_latitude,
        current_longitude,
        last_activated_at,
        updated_at
      )
      VALUES ($1, TRUE, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT (rider_id)
      DO UPDATE SET
        is_active = TRUE,
        current_latitude = EXCLUDED.current_latitude,
        current_longitude = EXCLUDED.current_longitude,
        last_activated_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP`,
      [userId, currentLat, currentLng]
    );

    // live location upsert-like behavior using existing unique(user_id, ride_id)
    // first create ride, then attach ride live location
    const rideInsertRes = await client.query(
      `INSERT INTO rides (
        rider_id,
        vehicle_id,
        start_location,
        destination,
        total_distance_km,
        per_km_rate,
        total_fare,
        available_seats,
        status,
        travel_date,
        travel_time,
        vehicle_type,
        gender_preference,
        note
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,'active',$9,$10,$11,$12,$13
      )
      RETURNING *`,
      [
        userId,
        vehicle.vehicle_id,
        startLocation,
        destination,
        totalDistanceKm,
        perKmRate,
        totalFare,
        availableSeats,
        travelDate,
        travelTime,
        vehicle.vehicle_type,
        String(genderPreference || 'any').toLowerCase(),
        note,
      ]
    );

    const createdRide = rideInsertRes.rows[0];

    await client.query(
      `INSERT INTO live_locations (
        user_id,
        ride_id,
        latitude,
        longitude,
        updated_at
      )
      VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id, ride_id)
      DO UPDATE SET
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        updated_at = CURRENT_TIMESTAMP`,
      [userId, createdRide.ride_id, currentLat, currentLng]
    );

    await client.query('COMMIT');

    emitRideAvailable({
      rideId: createdRide.ride_id,
      emptySeats: Number(createdRide.available_seats || 0),
      vehicleType: createdRide.vehicle_type,
      pickupLocation: createdRide.start_location,
      destinationLocation: createdRide.destination,
    });

    try {
      await notifyUsersForRide({ ride: createdRide });
    } catch (notifyError) {
      console.error('notifyUsersForRide error:', notifyError.message);
    }

    return {
      rideId: createdRide.ride_id,
      riderName: `${rider.first_name || ''} ${rider.last_name || ''}`.trim(),
      vehicleType: normalizeVehicleTypeLabel(vehicle.vehicle_type),
      vehicleModel: vehicle.model || '',
      vehicleNumber: vehicle.number_plate || '',
      currentLocation: startLocation,
      destination: createdRide.destination,
      totalDistanceKm,
      estimatedTravelMinutes: calculateETA(totalDistanceKm, 25),
      totalFare,
      availableSeats: Number(createdRide.available_seats || 0),
      status: createdRide.status,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const updateCurrentLocation = async ({ userId, body }) => {
  const { latitude, longitude, rideId = null } = body;

  if (!isValidNumber(latitude) || !isValidNumber(longitude)) {
    throw new Error('Valid latitude and longitude are required.');
  }

  const availabilityRes = await rideDb.query(
    `UPDATE rider_availability
     SET current_latitude = $2,
         current_longitude = $3,
         updated_at = CURRENT_TIMESTAMP
     WHERE rider_id = $1
     RETURNING *`,
    [userId, latitude, longitude]
  );

  if (!availabilityRes.rows.length) {
    await rideDb.query(
      `INSERT INTO rider_availability (
        rider_id,
        is_active,
        current_latitude,
        current_longitude,
        updated_at
      )
      VALUES ($1, FALSE, $2, $3, CURRENT_TIMESTAMP)`,
      [userId, latitude, longitude]
    );
  }

  if (rideId) {
    await rideDb.query(
      `INSERT INTO live_locations (
        user_id,
        ride_id,
        latitude,
        longitude,
        updated_at
      )
      VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id, ride_id)
      DO UPDATE SET
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        updated_at = CURRENT_TIMESTAMP`,
      [userId, rideId, latitude, longitude]
    );
  }

  return {
    userId,
    rideId,
    latitude,
    longitude,
  };
};

module.exports = {
  getCurrentActiveRide,
  getActiveRideSetupData,
  activateRide,
  cancelCurrentRide,
  updateCurrentLocation,
};
