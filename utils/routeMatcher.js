const { haversineDistanceKm, isValidCoordinates } = require('./geo');

const MAX_PICKUP_DISTANCE_KM = 2.5;
const MAX_DEST_DISTANCE_KM = 3.0;
const MAX_ROUTE_START_DISTANCE_KM = 2.5;
const MAX_ROUTE_END_DISTANCE_KM = 3.5;
const MIN_DIRECTION_SCORE = 0.55;

const toRadians = (deg) => (deg * Math.PI) / 180;

const bearingRadians = (lat1, lng1, lat2, lng2) => {
  const phi1 = toRadians(lat1);
  const phi2 = toRadians(lat2);
  const lambda1 = toRadians(lng1);
  const lambda2 = toRadians(lng2);

  const y = Math.sin(lambda2 - lambda1) * Math.cos(phi2);
  const x =
    Math.cos(phi1) * Math.sin(phi2) -
    Math.sin(phi1) * Math.cos(phi2) * Math.cos(lambda2 - lambda1);

  return Math.atan2(y, x);
};

const directionSimilarity = (aLat1, aLng1, aLat2, aLng2, bLat1, bLng1, bLat2, bLng2) => {
  const a = bearingRadians(aLat1, aLng1, aLat2, aLng2);
  const b = bearingRadians(bLat1, bLng1, bLat2, bLng2);
  return Math.cos(a - b);
};

const isRouteMatch = ({
  riderStartLat,
  riderStartLng,
  riderDestLat,
  riderDestLng,
  reqPickupLat,
  reqPickupLng,
  reqDestLat,
  reqDestLng,
}) => {
  if (
    !isValidCoordinates(riderStartLat, riderStartLng) ||
    !isValidCoordinates(riderDestLat, riderDestLng) ||
    !isValidCoordinates(reqPickupLat, reqPickupLng) ||
    !isValidCoordinates(reqDestLat, reqDestLng)
  ) {
    return false;
  }

  const pickupNearRouteStart = haversineDistanceKm(
    riderStartLat,
    riderStartLng,
    reqPickupLat,
    reqPickupLng
  );

  const destinationNearRouteEnd = haversineDistanceKm(
    riderDestLat,
    riderDestLng,
    reqDestLat,
    reqDestLng
  );

  const pickupNearRider = haversineDistanceKm(
    riderStartLat,
    riderStartLng,
    reqPickupLat,
    reqPickupLng
  );

  const destinationNearRiderEnd = haversineDistanceKm(
    riderDestLat,
    riderDestLng,
    reqDestLat,
    reqDestLng
  );

  const directionScore = directionSimilarity(
    riderStartLat,
    riderStartLng,
    riderDestLat,
    riderDestLng,
    reqPickupLat,
    reqPickupLng,
    reqDestLat,
    reqDestLng
  );

  return (
    pickupNearRouteStart <= MAX_PICKUP_DISTANCE_KM &&
    destinationNearRouteEnd <= MAX_DEST_DISTANCE_KM &&
    pickupNearRider <= MAX_ROUTE_START_DISTANCE_KM &&
    destinationNearRiderEnd <= MAX_ROUTE_END_DISTANCE_KM &&
    directionScore >= MIN_DIRECTION_SCORE
  );
};

module.exports = {
  isRouteMatch,
};