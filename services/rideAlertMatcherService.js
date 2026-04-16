const rideDb = require('../config/rideDb');
const ewuAdminDb = require('../config/ewuAdminDb');
const { safeDistanceKm } = require('../utils/geo');
const { emitRideAvailabilityFound } = require('../utils/rideAvailabilityEmitter');

const MAX_PICKUP_DISTANCE_KM = 3;
const MAX_DESTINATION_DISTANCE_KM = 5;

const normalizeOccupation = (value) => {
  if (!value) return 'user';

  const normalized = String(value).trim().toLowerCase();

  if (normalized === 'student') return 'student';
  if (normalized === 'faculty') return 'faculty';
  if (normalized === 'staff') return 'staff';

  return 'user';
};

const normalizeGender = (value) => {
  if (!value) return 'any';

  const normalized = String(value).trim().toLowerCase();

  if (normalized === 'male only') return 'male';
  if (normalized === 'female only') return 'female';
  if (['male', 'female', 'any'].includes(normalized)) return normalized;

  return 'any';
};

const normalizeVehicleType = (value) => {
  if (!value) return 'all';

  const normalized = String(value).trim().toLowerCase();
  if (['bike', 'car', 'all'].includes(normalized)) return normalized;

  return 'all';
};

const normalizeUserType = (value) => {
  if (!value) return 'all';

  const normalized = String(value).trim().toLowerCase();
  if (normalized === 'teacher') return 'faculty';
  if (['student', 'faculty', 'staff', 'all'].includes(normalized)) return normalized;

  return 'all';
};

const getRideAlertMatchesForRide = async ({ ride }) => {
  // ride = created or updated ride
  const riderRes = await rideDb.query(
    `SELECT university_email
     FROM users
     WHERE user_id = $1
     LIMIT 1`,
    [ride.rider_id]
  );

  const riderEmail = riderRes.rows[0]?.university_email || null;

  let riderOccupation = 'user';

  if (riderEmail) {
    const occRes = await ewuAdminDb.query(
      `SELECT occupation
       FROM ewu_users
       WHERE university_email = $1
       LIMIT 1`,
      [riderEmail]
    );

    riderOccupation = normalizeOccupation(occRes.rows[0]?.occupation || 'user');
  }

  const alertsRes = await rideDb.query(
    `SELECT *
     FROM ride_availability_alerts
     WHERE is_active = TRUE`
  );

  const matches = [];

  for (const alert of alertsRes.rows) {
    const pickupDistance = safeDistanceKm(
      Number(alert.pickup_lat),
      Number(alert.pickup_lng),
      Number(ride.pickup_latitude ?? alert.pickup_lat),
      Number(ride.pickup_longitude ?? alert.pickup_lng)
    );

    // ride_requests-style rides may not have destination coords in rides table.
    // safest fallback: compare only pickup if ride lat/lng missing.
    const destinationDistance = safeDistanceKm(
      Number(alert.destination_lat),
      Number(alert.destination_lng),
      Number(ride.destination_latitude ?? alert.destination_lat),
      Number(ride.destination_longitude ?? alert.destination_lng)
    );

    const genderMatch =
      normalizeGender(alert.gender_preference) === 'any' ||
      normalizeGender(ride.gender_preference) === 'any' ||
      normalizeGender(alert.gender_preference) === normalizeGender(ride.gender_preference);

    const vehicleMatch =
      normalizeVehicleType(alert.vehicle_type) === 'all' ||
      normalizeVehicleType(alert.vehicle_type) === normalizeVehicleType(ride.vehicle_type);

    const userTypeMatch =
      normalizeUserType(alert.user_type) === 'all' ||
      normalizeUserType(alert.user_type) === riderOccupation;

    const pickupOk =
      pickupDistance !== null && pickupDistance <= MAX_PICKUP_DISTANCE_KM;

    const destinationOk =
      destinationDistance === null || destinationDistance <= MAX_DESTINATION_DISTANCE_KM;

    if (
      pickupOk &&
      destinationOk &&
      genderMatch &&
      vehicleMatch &&
      userTypeMatch &&
      Number(ride.available_seats || 0) > 0 &&
      !['cancelled', 'completed'].includes(String(ride.status || '').toLowerCase())
    ) {
      matches.push({
        alert,
        pickupDistanceKm: pickupDistance,
        destinationDistanceKm: destinationDistance,
      });
    }
  }

  return matches;
};

const notifyUsersForRide = async ({ ride }) => {
  const matches = await getRideAlertMatchesForRide({ ride });

  for (const match of matches) {
    const title = 'Ride Available';
    const message = `A matching ride is now available from ${ride.start_location} to ${ride.destination}.`;

    await rideDb.query(
      `INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        related_id,
        created_at
      )
      VALUES ($1, $2, $3, $4, FALSE, $5, CURRENT_TIMESTAMP)`,
      [
        match.alert.user_id,
        title,
        message,
        'ride_available',
        ride.ride_id,
      ]
    );

    await rideDb.query(
      `UPDATE ride_availability_alerts
       SET notified_at = CURRENT_TIMESTAMP
       WHERE alert_id = $1`,
      [match.alert.alert_id]
    );

    emitRideAvailabilityFound({
      userId: match.alert.user_id,
      payload: {
        rideId: ride.ride_id,
        pickupLocation: ride.start_location,
        destinationLocation: ride.destination,
        vehicleType: ride.vehicle_type,
        emptySeats: ride.available_seats,
      },
    });
  }

  return matches.length;
};

module.exports = {
  getRideAlertMatchesForRide,
  notifyUsersForRide,
};