const rideDb = require('../config/rideDb');
const riderActiveRideService = require('./riderActiveRideService');
const { isRouteMatch } = require('../utils/routeMatcher');
const googleMapsService = require('./googleMapsService');
const notificationService = require('./notificationService');

const getMapDashboard = async ({ riderId }) => {
  const locationRes = await rideDb.query(
    `SELECT latitude, longitude
     FROM live_locations
     WHERE user_id = $1
     ORDER BY updated_at DESC
     LIMIT 1`,
    [riderId]
  );

  const riderLocation = locationRes.rows[0] || { latitude: null, longitude: null };

  const rideRes = await rideDb.query(
    `SELECT
        r.ride_id,
        r.start_location,
        r.destination,
        r.total_distance_km,
        r.total_fare,
        r.status,
        u.first_name,
        u.last_name,
        u.phone,
        rp.passenger_id,
        r.pickup_latitude,
        r.pickup_longitude,
        r.destination_latitude,
        r.destination_longitude,
        r.route_polyline,
        r.route_distance_km,
        r.route_duration_minutes,
        v.vehicle_type
     FROM rides r
     JOIN ride_participants rp ON rp.ride_id = r.ride_id
     JOIN users u ON u.user_id = rp.passenger_id
     LEFT JOIN vehicles v ON v.vehicle_id = r.vehicle_id
     WHERE r.rider_id = $1
       AND r.status IN ('assigned','ongoing')
     LIMIT 1`,
    [riderId]
  );

  let currentRide = null;

  if (rideRes.rows.length) {
    const row = rideRes.rows[0];

    // ── রাইডার নিজে যেই route select করেছিল, সেটাই ব্যবহার করো — fresh recompute না ──
    let encodedPolyline = row.route_polyline || null;
    let distanceKm = row.route_distance_km != null ? Number(row.route_distance_km) : Number(row.total_distance_km);
    let durationMinutes = row.route_duration_minutes != null ? Number(row.route_duration_minutes) : 0;

    // পুরনো ride যাদের route_polyline সেভ নেই (এই ফিচারের আগে তৈরি হওয়া ride), তাদের জন্য fallback
    if (!encodedPolyline) {
      try {
        const routeData = await googleMapsService.computeRoute({
          originLat: Number(row.pickup_latitude),
          originLng: Number(row.pickup_longitude),
          destinationLat: Number(row.destination_latitude),
          destinationLng: Number(row.destination_longitude),
          travelMode: 'DRIVE',
        });
        encodedPolyline = routeData?.polyline ?? null;
        distanceKm = routeData?.distanceKm ?? distanceKm;
        durationMinutes = routeData?.durationMinutes ?? durationMinutes;
      } catch (_) {}
    }

    currentRide = {
      rideId: row.ride_id,
      passengerName: `${row.first_name} ${row.last_name}`,
      phoneNumber: row.phone,
      pickupLocationName: row.start_location,
      destinationName: row.destination,
      pickupLat: row.pickup_latitude,
      pickupLng: row.pickup_longitude,
      destinationLat: row.destination_latitude,
      destinationLng: row.destination_longitude,
      distanceKm,
      estimatedMinutes: durationMinutes,
      fare: Number(row.total_fare),
      status: row.status,
      vehicleType: row.vehicle_type ?? 'bike',
      encodedPolyline,
    };
  }

  const requestsRes = await rideDb.query(
    `SELECT
        rr.request_id,
        rr.pickup_location,
        rr.destination,
        rr.distance_km,
        rr.estimated_fare,
        rr.estimated_minutes,
        rr.pickup_latitude,
        rr.pickup_longitude,
        u.first_name,
        u.last_name
     FROM ride_requests rr
     JOIN users u ON u.user_id = rr.passenger_id
     WHERE rr.status = 'pending'
       AND rr.expires_at > CURRENT_TIMESTAMP
     ORDER BY rr.requested_at DESC
     LIMIT 20`
  );

  let nearbyRideRequests = [];

  if (currentRide) {
    nearbyRideRequests = requestsRes.rows
      .filter((r) =>
        isRouteMatch({
          riderStartLat: Number(currentRide.pickupLat ?? 0),
          riderStartLng: Number(currentRide.pickupLng ?? 0),
          riderDestLat: Number(currentRide.destinationLat ?? 0),
          riderDestLng: Number(currentRide.destinationLng ?? 0),
          reqPickupLat: Number(r.pickup_latitude ?? 0),
          reqPickupLng: Number(r.pickup_longitude ?? 0),
          reqDestLat: Number(r.destination_latitude ?? 0),
          reqDestLng: Number(r.destination_longitude ?? 0),
        })
      )
      .map((r) => ({
        requestId: r.request_id,
        name: `${r.first_name} ${r.last_name}`,
        pickup: r.pickup_location,
        destination: r.destination,
        distanceKm: Number(r.distance_km || 0),
        fare: Number(r.estimated_fare || 0),
        eta: r.estimated_minutes || 0,
        pickupLat: r.pickup_latitude,
        pickupLng: r.pickup_longitude,
      }));
  }

  return {
    riderLocation: {
      lat: riderLocation.latitude,
      lng: riderLocation.longitude,
    },
    currentRide,
    nearbyRideRequests,
  };
};

const updateLocation = async ({ riderId, body, io }) => {
  const { lat, lng } = body;

  await rideDb.query(
    `INSERT INTO live_locations (user_id, latitude, longitude)
     VALUES ($1,$2,$3)`,
    [riderId, lat, lng]
  );

  if (io) {
    io.emit('rider:location:update', { riderId, lat, lng });
  }

  return { lat, lng };
};

const acceptRequest = async ({ riderId, requestId, io }) => {
  const data = await riderActiveRideService.acceptRideRequest({
    riderId,
    requestId,
    io,
  });

  if (io) {
    io.emit('ride-request:removed', { requestId });
  }

  return data;
};

const startNavigation = async ({ riderId, rideId }) => {
  await rideDb.query(
    `UPDATE rides
     SET status = 'ongoing'
     WHERE ride_id = $1 AND rider_id = $2`,
    [rideId, riderId]
  );

  return { rideId, status: 'ongoing' };
};

const getRoutePolyline = async ({ originLat, originLng, destinationLat, destinationLng }) => {
  try {
    const result = await googleMapsService.computeRoute({
      originLat: Number(originLat),
      originLng: Number(originLng),
      destinationLat: Number(destinationLat),
      destinationLng: Number(destinationLng),
      travelMode: 'DRIVE',
    });
    return {
      encodedPolyline: result.polyline ?? null,
      distanceKm: result.distanceKm,
      durationMinutes: result.durationMinutes,
    };
  } catch (_) {
    return { encodedPolyline: null, distanceKm: null, durationMinutes: null };
  }
};

// ✅ Rider যেই route select করে ride confirm করেছিল, সেই exact saved polyline
// রাইডার এবং passenger — দুইজনের জন্যই একই route (rides.route_polyline থেকে)
const getSavedRoutePolyline = async ({ userId, rideId }) => {
  const result = await rideDb.query(
    `SELECT r.route_polyline, r.route_distance_km, r.route_duration_minutes,
            r.pickup_latitude, r.pickup_longitude,
            r.destination_latitude, r.destination_longitude
     FROM rides r
     WHERE r.ride_id = $1
       AND (
         r.rider_id = $2
         OR EXISTS (
           SELECT 1 FROM ride_participants rp
           WHERE rp.ride_id = r.ride_id AND rp.passenger_id = $2
         )
       )
     LIMIT 1`,
    [rideId, userId]
  );

  if (result.rows.length === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  const row = result.rows[0];
  let encodedPolyline = row.route_polyline || null;
  let distanceKm = row.route_distance_km != null ? Number(row.route_distance_km) : null;
  let durationMinutes = row.route_duration_minutes != null ? Number(row.route_duration_minutes) : null;

  // পুরনো ride যাদের route_polyline সেভ নেই, তাদের জন্য fallback (rider সাইডের মতোই)
  if (!encodedPolyline) {
    try {
      const routeData = await googleMapsService.computeRoute({
        originLat: Number(row.pickup_latitude),
        originLng: Number(row.pickup_longitude),
        destinationLat: Number(row.destination_latitude),
        destinationLng: Number(row.destination_longitude),
        travelMode: 'DRIVE',
      });
      encodedPolyline = routeData?.polyline ?? null;
      distanceKm = routeData?.distanceKm ?? distanceKm;
      durationMinutes = routeData?.durationMinutes ?? durationMinutes;
    } catch (_) {}
  }

  return { encodedPolyline, distanceKm, durationMinutes };
};

const completeRideFromMap = async ({ riderId, rideId }) => {
  // Ride complete করো
  const rideRes = await rideDb.query(
    `UPDATE rides
     SET status = 'completed', completed_at = CURRENT_TIMESTAMP
     WHERE ride_id = $1 AND rider_id = $2
     RETURNING ride_id, rider_id`,
    [rideId, riderId]
  );

  if (rideRes.rowCount === 0) {
    throw new Error('Ride not found or unauthorized.');
  }

  // Passenger খুঁজো
  const participantRes = await rideDb.query(
    `SELECT rp.passenger_id, u.first_name, u.last_name
     FROM ride_participants rp
     JOIN users u ON u.user_id = rp.passenger_id
     WHERE rp.ride_id = $1
     LIMIT 1`,
    [rideId]
  );

  const passengerId = participantRes.rows[0]?.passenger_id;
  const riderRes = await rideDb.query(
    `SELECT first_name, last_name FROM users WHERE user_id = $1`,
    [riderId]
  );
  const riderName = riderRes.rows[0]
    ? `${riderRes.rows[0].first_name} ${riderRes.rows[0].last_name}`
    : 'Your rider';

  // Passenger কে notification পাঠাও
  if (passengerId) {
    await notificationService.createNotification({
      userId: passengerId,
      title: 'Ride Completed Successfully!',
      message: `Your ride has been completed. You have been safely dropped off at your destination. Thank you for riding with UniRide!`,
      type: 'booking',
      isImportant: false,
      targetRole: 'passenger',
      relatedId: rideId,
    });
  }

  // Rider কে notification পাঠাও
  await notificationService.createNotification({
    userId: riderId,
    title: 'Ride Completed!',
    message: `Congratulations! You have successfully completed the ride and dropped off the passenger at their destination. Great job!`,
    type: 'booking',
    isImportant: false,
    targetRole: 'rider',
    relatedId: rideId,
  });

  // ride_requests table এও update করো যাতে passenger এর active ride শেষ হয়
  await rideDb.query(
    `UPDATE ride_requests
     SET status = 'completed'
     WHERE ride_id = $1 AND status = 'accepted'`,
    [rideId]
  );

  return { rideId, status: 'completed' };
};

module.exports = {
  getMapDashboard,
  updateLocation,
  acceptRequest,
  startNavigation,
  getRoutePolyline,
  getSavedRoutePolyline,
  completeRideFromMap,
};
