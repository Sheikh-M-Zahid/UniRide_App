const rideDb = require('../config/rideDb');
const riderActiveRideService = require('./riderActiveRideService');
const { isRouteMatch } = require('../utils/routeMatcher');
const googleMapsService = require('./googleMapsService');

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

    // Real route from Google Maps
    let routeData = null;
    try {
      routeData = await googleMapsService.computeRoute({
        originLat: Number(row.pickup_latitude),
        originLng: Number(row.pickup_longitude),
        destinationLat: Number(row.destination_latitude),
        destinationLng: Number(row.destination_longitude),
        travelMode: 'DRIVE',
      });
    } catch (_) {}

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
      distanceKm: routeData?.distanceKm ?? Number(row.total_distance_km),
      estimatedMinutes: routeData?.durationMinutes ?? 0,
      fare: Number(row.total_fare),
      status: row.status,
      vehicleType: row.vehicle_type ?? 'bike',
      encodedPolyline: routeData?.polyline ?? null,
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

module.exports = {
  getMapDashboard,
  updateLocation,
  acceptRequest,
  startNavigation,
};
