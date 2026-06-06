const toNumber = (value, fallback = 0) => {
  if (value === null || value === undefined || value === '') return fallback;
  const parsed = Number(value);
  return Number.isNaN(parsed) ? fallback : parsed;
};

const buildPassengerName = (firstName, lastName) => {
  return `${firstName || ''} ${lastName || ''}`.trim();
};

const mapToRideRequestModelPayload = (row) => {
  return {
    passengerName: buildPassengerName(row.first_name, row.last_name),
    phoneNumber: row.phone || '',
    currentLocation: row.pickup_location || row.start_location || '',
    destination: row.destination || '',
    distanceKm: toNumber(row.distance_km ?? row.total_distance_km),
    fare: toNumber(row.estimated_fare ?? row.total_fare),
    estimatedMinutes: toNumber(row.estimated_minutes),
  };
};

const mapToRideRequestMeta = (row) => {
  return {
    requestId: row.request_id || null,
    passengerId: row.passenger_id || null,
    riderId: row.rider_id || null,
    status: row.request_status || row.status || null,
    createdAt: row.requested_at || row.created_at || null,
    confirmedAt: row.confirmed_at || null,
    freeCancelUntil: row.free_cancel_until || null,
    confirmedRideId: row.ride_id || null,
    cancelReason: row.cancel_reason || null,
    cancelledBy: row.cancelled_by || null,
    vehicleType: row.vehicle_type || null,
    ratePerKm: row.rate_per_km !== undefined ? toNumber(row.rate_per_km, null) : null,
  };
};

const mapToRideRequestPayload = (row) => {
  return {
    request: mapToRideRequestModelPayload(row),
    meta: mapToRideRequestMeta(row),
  };
};

const mapToFlatRideRequestPayload = (row) => {
  return {
    ...mapToRideRequestModelPayload(row),
    ...mapToRideRequestMeta(row),
  };
};

module.exports = {
  mapToRideRequestModelPayload,
  mapToRideRequestMeta,
  mapToRideRequestPayload,
  mapToFlatRideRequestPayload,
};
