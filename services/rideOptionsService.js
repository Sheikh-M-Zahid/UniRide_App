const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const { safeDistanceKm, calculateETA } = require('../utils/geo');
const { computeRoute, computeRouteMatrix } = require('./googleMapsService');

const DEFAULT_BIKE_RATE = 20;
const DEFAULT_CAR_RATE = 35;
const MAX_MATCH_DISTANCE_KM = 10;

const normalizeGenderFilter = (value) => {
  if (!value) return 'any';
  const normalized = String(value).trim().toLowerCase();

  if (normalized === 'male only') return 'male';
  if (normalized === 'female only') return 'female';
  if (['male', 'female', 'any'].includes(normalized)) return normalized;

  return 'any';
};

const normalizeVehicleFilter = (value) => {
  if (!value) return 'all';
  const normalized = String(value).trim().toLowerCase();
  if (['all', 'bike', 'car'].includes(normalized)) return normalized;
  return 'all';
};

const normalizeUserTypeFilter = (value) => {
  if (!value) return 'all';
  const normalized = String(value).trim().toLowerCase();
  if (normalized === 'teacher') return 'faculty';
  if (['all', 'student', 'faculty', 'staff'].includes(normalized)) return normalized;
  return 'all';
};

const mapOccupation = (occupation) => {
  if (!occupation) return 'User';

  const value = String(occupation).trim().toLowerCase();
  if (value === 'student') return 'Student';
  if (value === 'faculty') return 'Teacher';
  if (value === 'staff') return 'Staff';

  return 'User';
};

const getVehicleRate = (vehicleType) => {
  const type = String(vehicleType || '').trim().toLowerCase();
  if (type === 'bike') return DEFAULT_BIKE_RATE;
  return DEFAULT_CAR_RATE;
};

const getRideOptions = async ({ body }) => {
  const {
    pickupAddress,
    destinationAddress,
    pickupLat,
    pickupLng,
    destinationLat,
    destinationLng,
    genderPreference = 'Any',
    vehicleType = 'All',
    userType = 'All',
  } = body;

  if (
    !pickupAddress ||
    !destinationAddress ||
    typeof pickupLat !== 'number' ||
    typeof pickupLng !== 'number' ||
    typeof destinationLat !== 'number' ||
    typeof destinationLng !== 'number'
  ) {
    throw new Error('Pickup, destination, and valid coordinates are required.');
  }

  const normalizedGender = normalizeGenderFilter(genderPreference);
  const normalizedVehicleType = normalizeVehicleFilter(vehicleType);
  const normalizedUserType = normalizeUserTypeFilter(userType);

  // Real route summary from Google Routes API
  const route = await computeRoute({
    originLat: pickupLat,
    originLng: pickupLng,
    destinationLat,
    destinationLng,
  });

  const ridesRes = await rideDb.query(`
    SELECT
      r.ride_id,
      r.rider_id,
      r.vehicle_id,
      r.available_seats,
      r.travel_time,
      r.travel_date,
      r.gender_preference,
      r.vehicle_type,
      r.status,

      u.first_name,
      u.last_name,
      u.phone,
      u.rating,
      u.university_email,

      v.number_plate,
      v.vehicle_type AS db_vehicle_type,

      ll.latitude,
      ll.longitude
    FROM rides r
    JOIN users u
      ON r.rider_id = u.user_id
    LEFT JOIN vehicles v
      ON r.vehicle_id = v.vehicle_id
    LEFT JOIN LATERAL (
      SELECT latitude, longitude
      FROM live_locations
      WHERE user_id = r.rider_id
      ORDER BY updated_at DESC
      LIMIT 1
    ) ll ON TRUE
    WHERE r.status IN ('active', 'scheduled', 'assigned')
      AND r.available_seats > 0
      AND (r.travel_date IS NULL OR r.travel_date >= CURRENT_DATE)
    ORDER BY r.created_at DESC
    LIMIT 100
  `);

  const rides = ridesRes.rows;

  if (!rides.length) {
    return {
      routeSummary: {
        routeDistanceKm: route.distanceKm,
        estimatedTravelMinutes: route.durationMinutes,
        totalCost: Math.round(route.distanceKm * DEFAULT_CAR_RATE),
        polyline: route.polyline,
      },
      availableRides: [],
    };
  }

  const emails = [...new Set(rides.map((r) => r.university_email).filter(Boolean))];
  let occupationMap = new Map();

  if (emails.length) {
    const occRes = await ewuAdminDb.query(
      `SELECT university_email, occupation
       FROM ewu_users
       WHERE university_email = ANY($1::text[])`,
      [emails]
    );

    occupationMap = new Map(
      occRes.rows.map((row) => [row.university_email, row.occupation])
    );
  }

  // Google Route Matrix for rider -> passenger pickup comparison
  const riderDestinations = rides
    .map((ride, index) => ({
      index,
      lat: ride.latitude,
      lng: ride.longitude,
    }))
    .filter((item) => item.lat !== null && item.lng !== null);

  let matrixMap = new Map();

  if (riderDestinations.length) {
    const matrix = await computeRouteMatrix({
      origin: { lat: pickupLat, lng: pickupLng },
      destinations: riderDestinations,
    });

    for (const row of matrix) {
      const source = riderDestinations[row.destinationIndex];
      if (source) {
        matrixMap.set(source.index, row);
      }
    }
  }

  const availableRides = rides
    .map((ride, index) => {
      const resolvedVehicleType = String(
        ride.vehicle_type || ride.db_vehicle_type || ''
      )
        .trim()
        .toLowerCase();

      const fallbackDistance = safeDistanceKm(
        pickupLat,
        pickupLng,
        ride.latitude !== null ? Number(ride.latitude) : null,
        ride.longitude !== null ? Number(ride.longitude) : null
      );

      const matrix = matrixMap.get(index);

      const distanceAwayKm =
        matrix?.distanceKm ??
        (fallbackDistance !== null ? Number(fallbackDistance.toFixed(2)) : null);

      const estimatedFare = Math.round(
        route.distanceKm * getVehicleRate(resolvedVehicleType)
      );

      const mappedUserType = mapOccupation(
        occupationMap.get(ride.university_email) || null
      );

      return {
        rideId: ride.ride_id,
        driverName: `${ride.first_name || ''} ${ride.last_name || ''}`.trim(),
        driverPhoneNumber: ride.phone || '',
        userType: mappedUserType,
        vehicleType:
          resolvedVehicleType === 'bike'
            ? 'Bike'
            : resolvedVehicleType === 'car'
            ? 'Car'
            : 'Vehicle',
        rating: Number(ride.rating || 5),
        vehicleNumber: ride.number_plate || '',
        emptySeats: Number(ride.available_seats || 0),
        departureTime: ride.travel_time || null,
        genderPreference:
          ride.gender_preference === 'male'
            ? 'Male'
            : ride.gender_preference === 'female'
            ? 'Female'
            : 'Any',
        distanceAwayKm,
        estimatedFare,
        isAvailable:
          Number(ride.available_seats || 0) > 0 &&
          !['cancelled', 'completed'].includes(String(ride.status).toLowerCase()),
        _etaToPickup: matrix?.durationMinutes ?? calculateETA(distanceAwayKm || 0),
      };
    })
    .filter((ride) => {
      if (!ride.isAvailable) return false;

      if (ride.distanceAwayKm === null || ride.distanceAwayKm > MAX_MATCH_DISTANCE_KM) {
        return false;
      }

      if (
        normalizedGender !== 'any' &&
        String(ride.genderPreference).toLowerCase() !==
          (normalizedGender === 'male'
            ? 'male'
            : normalizedGender === 'female'
            ? 'female'
            : 'any') &&
        String(ride.genderPreference).toLowerCase() !== 'any'
      ) {
        return false;
      }

      if (
        normalizedVehicleType !== 'all' &&
        String(ride.vehicleType).toLowerCase() !== normalizedVehicleType
      ) {
        return false;
      }

      if (
        normalizedUserType !== 'all' &&
        String(ride.userType).toLowerCase() !==
          (normalizedUserType === 'faculty' ? 'teacher' : normalizedUserType)
      ) {
        return false;
      }

      return true;
    })
    .map(({ _etaToPickup, ...rest }) => rest);

  return {
    routeSummary: {
      routeDistanceKm: route.distanceKm,
      estimatedTravelMinutes: route.durationMinutes,
      totalCost: Math.round(route.distanceKm * DEFAULT_CAR_RATE),
      polyline: route.polyline,
    },
    availableRides,
  };
};

module.exports = {
  getRideOptions,
};