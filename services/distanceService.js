const getDistanceAndDuration = async ({
  pickupLatitude,
  pickupLongitude,
  destinationLatitude,
  destinationLongitude,
}) => {
  // Replace with real Google Maps / Mapbox / OSRM logic
  // Return normalized backend-safe format

  return {
    distanceKm: 6.8,
    estimatedMinutes: 18,
  };
};

module.exports = {
  getDistanceAndDuration,
};