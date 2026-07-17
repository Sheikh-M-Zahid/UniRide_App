const rideDb = require('../config/rideDb');
const { computeRouteAlternativesWithSteps, computeRoute } = require('./googleMapsService');
const { decodePolyline } = require('../utils/polyline');
const { nearestPointOnRoute } = require('../utils/routeCorridor');
const { computeRouteAlternatives } = require('./googleMapsService');
const { safeDistanceKm, calculateETA } = require('../utils/geo');
const { emitRideAvailable } = require('../utils/rideAvailabilityEmitter');
const { notifyUsersForRide } = require('./rideAlertMatcherService');
const {
  autoCompleteRideIfReachedDestination,
} = require('./activeRideAutoCompleteService');

const DEFAULT_BIKE_RATE = 20;
const DEFAULT_CAR_RATE = 35;
const PREFERENCE_MATCH_RADIUS_KM = 0.3;

const BLOCKING_RIDE_STATUSES = ['assigned', 'ongoing'];

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
      SET
        status = 'cancelled',
        cancelled_at = CURRENT_TIMESTAMP
      WHERE ride_id = $1
      `,
      [rideId]
    );

    await client.query(
      `
      UPDATE rider_availability
      SET
        is_active = FALSE,
        last_deactivated_at = CURRENT_TIMESTAMP,
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

  const vehicles = vehiclesRes.rows.map((vehicle) => {
    const vType = String(vehicle.vehicle_type || '').trim().toLowerCase();
    const rawSeats = Number(vehicle.total_seats || 0);
    const totalSeats = vType === 'bike' ? 1 : (rawSeats > 0 ? rawSeats : 4);

    return {
      vehicleId: vehicle.vehicle_id,
      vehicleType: vehicle.vehicle_type,
      vehicleTypeLabel: normalizeVehicleTypeLabel(vehicle.vehicle_type),
      company: vehicle.company || '',
      model: vehicle.model || '',
      vehicleNumber: vehicle.number_plate || '',
      totalSeats,
      verified: Boolean(vehicle.verified),
    };
  });

  return {
    riderName: `${rider.first_name || ''} ${rider.last_name || ''}`.trim(),
    vehicles,
  };
};

const findMatchingPreference = async ({ riderId, currentLat, currentLng, destinationLat, destinationLng }) => {
  const res = await rideDb.query(
    `SELECT * FROM rider_route_preferences WHERE rider_id = $1`,
    [riderId]
  );

  for (const pref of res.rows) {
    const pickupDist = safeDistanceKm(currentLat, currentLng, Number(pref.pickup_lat), Number(pref.pickup_lng));
    const destDist = safeDistanceKm(destinationLat, destinationLng, Number(pref.destination_lat), Number(pref.destination_lng));
    if (
      pickupDist !== null && destDist !== null &&
      pickupDist <= PREFERENCE_MATCH_RADIUS_KM &&
      destDist <= PREFERENCE_MATCH_RADIUS_KM
    ) {
      return pref;
    }
  }
  return null;
};

const getRouteAlternatives = async ({ riderId, currentLat, currentLng, destinationLat, destinationLng }) => {
  if (
    !isValidNumber(currentLat) ||
    !isValidNumber(currentLng) ||
    !isValidNumber(destinationLat) ||
    !isValidNumber(destinationLng)
  ) {
    throw new Error('Valid current and destination coordinates are required.');
  }

  const alternatives = await computeRouteAlternativesWithSteps({
    originLat: currentLat,
    originLng: currentLng,
    destinationLat,
    destinationLng,
  });

  const matchedPreference = riderId
    ? await findMatchingPreference({ riderId, currentLat, currentLng, destinationLat, destinationLng })
    : null;

  let defaultIndex = 0;

  if (matchedPreference) {
    let bestMatchIndex = -1;
    let bestDiff = Infinity;

    alternatives.forEach((alt, idx) => {
      const diff = Math.abs(alt.distanceKm - Number(matchedPreference.route_distance_km || 0));
      if (diff < bestDiff) {
        bestDiff = diff;
        bestMatchIndex = idx;
      }
    });

    const tolerance = Number(matchedPreference.route_distance_km || 0) * 0.15;

    if (bestMatchIndex !== -1 && bestDiff <= tolerance) {
      defaultIndex = bestMatchIndex;
    } else {
      let landmarks = [];
      try { landmarks = JSON.parse(matchedPreference.route_landmarks || '[]'); } catch (_) {}

      alternatives.unshift({
        routeIndex: -1,
        distanceKm: Number(matchedPreference.route_distance_km || 0),
        durationMinutes: Number(matchedPreference.route_duration_minutes || 0),
        polyline: matchedPreference.route_polyline,
        landmarks,
      });
      defaultIndex = 0;
    }
  }

  return alternatives.map((alt, idx) => ({
    ...alt,
    isDefault: idx === defaultIndex,
    isPreviouslyUsed: !!matchedPreference && idx === defaultIndex,
  }));
};

const getRouteReconnect = async ({ rideId, currentLat, currentLng }) => {
  if (!isValidNumber(currentLat) || !isValidNumber(currentLng)) {
    throw new Error('Valid current coordinates are required.');
  }

  const rideRes = await rideDb.query(
    `SELECT route_polyline FROM rides WHERE ride_id = $1`,
    [rideId]
  );
  if (!rideRes.rows.length) throw new Error('Ride not found.');

  const ride = rideRes.rows[0];
  if (!ride.route_polyline) return { deviated: false };

  const routePoints = decodePolyline(ride.route_polyline);
  const nearest = nearestPointOnRoute(routePoints, currentLat, currentLng);

  const DEVIATION_THRESHOLD_KM = 0.08; // ~৮০ মিটার

  if (nearest.distanceKm <= DEVIATION_THRESHOLD_KM) {
    return { deviated: false };
  }

  const rejoinIndex = Math.min(nearest.index + 15, routePoints.length - 1);
  const rejoinPoint = routePoints[rejoinIndex];

  const reconnectRoute = await computeRoute({
    originLat: currentLat,
    originLng: currentLng,
    destinationLat: rejoinPoint.lat,
    destinationLng: rejoinPoint.lng,
  });

  return {
    deviated: true,
    reconnectPolyline: reconnectRoute.polyline,
    rejoinLat: rejoinPoint.lat,
    rejoinLng: rejoinPoint.lng,
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
    routePolyline = null,
    routeDistanceKm = null,
    routeDurationMinutes = null,
    isDefaultRoute = true,
    routeLandmarks = [],
    routeDistanceKm = null,
    routeDurationMinutes = null,
    isDefaultRoute = true,
  } = body;

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
    `SELECT vehicle_id, user_id, vehicle_type, company, model, number_plate, total_seats, verified
     FROM vehicles WHERE vehicle_id = $1 AND user_id = $2 LIMIT 1`,
    [vehicleId, userId]
  );

  if (!vehicleRes.rows.length) {
    throw new Error('Selected vehicle not found.');
  }

  const vehicle = vehicleRes.rows[0];

  const riderRes = await rideDb.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1 LIMIT 1`,
    [userId]
  );
  const rider = riderRes.rows[0];

  const startLocation =
    currentLocationText || `${Number(currentLat).toFixed(5)}, ${Number(currentLng).toFixed(5)}`;

  // ── এখানে গুরুত্বপূর্ণ পরিবর্তন: straight-line-এর বদলে rider-এর select করা route distance ──
  let totalDistanceKm;
  if (isValidNumber(routeDistanceKm) && routeDistanceKm > 0) {
    totalDistanceKm = Number(Number(routeDistanceKm).toFixed(2));
  } else {
    const distanceKmRaw = safeDistanceKm(
      Number(currentLat), Number(currentLng), Number(destinationLat), Number(destinationLng)
    );
    if (distanceKmRaw === null) throw new Error('Invalid current or destination coordinates.');
    totalDistanceKm = Number(distanceKmRaw.toFixed(2));
  }

  const perKmRate = await getPerKmRate(vehicle.vehicle_type);
  const totalFare = Number((totalDistanceKm * perKmRate).toFixed(2));
  const availableSeats = Math.max(Number(vehicle.total_seats || 1), 1);

  const client = await rideDb.connect();

  try {
    await client.query('BEGIN');

    await client.query(
      `INSERT INTO rider_availability (
        rider_id, is_active, current_latitude, current_longitude, last_activated_at, updated_at
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

    const rideInsertRes = await client.query(
      `INSERT INTO rides (
        rider_id, vehicle_id, start_location, destination,
        total_distance_km, per_km_rate, total_fare,
        available_seats, status, travel_date, travel_time,
        vehicle_type, gender_preference, note,
        pickup_latitude, pickup_longitude,
        destination_latitude, destination_longitude,
        start_latitude, start_longitude,
        route_polyline, route_distance_km, route_duration_minutes, is_default_route
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,'assigned',$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,
        $20,$21,$22,$23
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
        currentLat,
        currentLng,
        destinationLat,
        destinationLng,
        currentLat,
        currentLng,
        routePolyline,
        isValidNumber(routeDistanceKm) ? routeDistanceKm : totalDistanceKm,
        isValidNumber(routeDurationMinutes) ? routeDurationMinutes : null,
        isDefaultRoute !== false,
      ]
    );

    const createdRide = rideInsertRes.rows[0];

    await client.query(
      `INSERT INTO live_locations (user_id, ride_id, latitude, longitude, updated_at)
       VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id, ride_id)
       DO UPDATE SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, updated_at = CURRENT_TIMESTAMP`,
      [userId, createdRide.ride_id, currentLat, currentLng]
    );

    if (routePolyline) {
      try {
        const existingPrefRes = await client.query(
          `SELECT preference_id, pickup_lat, pickup_lng, destination_lat, destination_lng
           FROM rider_route_preferences WHERE rider_id = $1`,
          [userId]
        );

        let matchedPrefId = null;
        for (const row of existingPrefRes.rows) {
          const pickupDist = safeDistanceKm(currentLat, currentLng, Number(row.pickup_lat), Number(row.pickup_lng));
          const destDist = safeDistanceKm(destinationLat, destinationLng, Number(row.destination_lat), Number(row.destination_lng));
          if (pickupDist !== null && destDist !== null && pickupDist <= 0.3 && destDist <= 0.3) {
            matchedPrefId = row.preference_id;
            break;
          }
        }

        const landmarksJson = JSON.stringify(routeLandmarks || []);

        if (matchedPrefId) {
          await client.query(
            `UPDATE rider_route_preferences
             SET route_polyline = $1, route_distance_km = $2, route_duration_minutes = $3,
                 route_landmarks = $4, last_used_at = CURRENT_TIMESTAMP
             WHERE preference_id = $5`,
            [routePolyline, totalDistanceKm, routeDurationMinutes, landmarksJson, matchedPrefId]
          );
        } else {
          await client.query(
            `INSERT INTO rider_route_preferences (
              rider_id, pickup_lat, pickup_lng, destination_lat, destination_lng,
              route_polyline, route_distance_km, route_duration_minutes, route_landmarks
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
            [userId, currentLat, currentLng, destinationLat, destinationLng,
              routePolyline, totalDistanceKm, routeDurationMinutes, landmarksJson]
          );
        }
      } catch (prefErr) {
        console.error('Route preference save failed:', prefErr.message);
      }
    }

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
      estimatedTravelMinutes: isValidNumber(routeDurationMinutes)
        ? routeDurationMinutes
        : calculateETA(totalDistanceKm, 25),
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

  let resolvedRideId = rideId;

  if (!resolvedRideId) {
    const activeRideRes = await rideDb.query(
      `
      SELECT ride_id
      FROM rides
      WHERE rider_id = $1
        AND status = ANY($2::text[])
      ORDER BY created_at DESC
      LIMIT 1
      `,
      [userId, BLOCKING_RIDE_STATUSES]
    );

    if (activeRideRes.rows.length) {
      resolvedRideId = activeRideRes.rows[0].ride_id;
    }
  }

  if (resolvedRideId) {
    const existingLiveLocation = await rideDb.query(
      `
      SELECT location_id
      FROM live_locations
      WHERE user_id = $1
        AND ride_id = $2
      LIMIT 1
      `,
      [userId, resolvedRideId]
    );

    if (existingLiveLocation.rows.length) {
      await rideDb.query(
        `
        UPDATE live_locations
        SET
          latitude = $3,
          longitude = $4,
          updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $1
          AND ride_id = $2
        `,
        [userId, resolvedRideId, latitude, longitude]
      );
    } else {
      await rideDb.query(
        `
        INSERT INTO live_locations (
          user_id,
          ride_id,
          latitude,
          longitude,
          updated_at
        )
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        `,
        [userId, resolvedRideId, latitude, longitude]
      );
    }
  }

  const autoCompleteResult = await autoCompleteRideIfReachedDestination({
    userId,
    rideId: resolvedRideId,
    latitude,
    longitude,
  });

  return {
    userId,
    rideId: resolvedRideId,
    latitude,
    longitude,
    autoComplete: autoCompleteResult,
  };
};

module.exports = {
  getActiveRideSetupData,
  getRouteAlternatives,
  getRouteReconnect,
  activateRide,
  updateCurrentLocation,
};
