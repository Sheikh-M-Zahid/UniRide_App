const toRadians = (degree) => {
  return (degree * Math.PI) / 180;
};


 //  VALIDATION


const isValidLatitude = (lat) => {
  return typeof lat === 'number' && !Number.isNaN(lat) && lat >= -90 && lat <= 90;
};

const isValidLongitude = (lng) => {
  return typeof lng === 'number' && !Number.isNaN(lng) && lng >= -180 && lng <= 180;
};

const isValidCoordinates = (lat, lng) => {
  return isValidLatitude(lat) && isValidLongitude(lng);
};


//   DISTANCE (HAVERSINE)


const haversineDistanceKm = (lat1, lng1, lat2, lng2) => {
  const earthRadiusKm = 6371;

  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadiusKm * c;
};


  // SAFE DISTANCE WRAPPER 🔥


const safeDistanceKm = (lat1, lng1, lat2, lng2) => {
  if (!isValidCoordinates(lat1, lng1) || !isValidCoordinates(lat2, lng2)) {
    return null; // invalid data হলে crash করবে না
  }

  return haversineDistanceKm(lat1, lng1, lat2, lng2);
};


//   ETA CALCULATION 

const calculateETA = (distanceKm, avgSpeedKmH = 25) => {
  if (!distanceKm || distanceKm <= 0) return 5;

  return Math.max(5, Math.round((distanceKm / avgSpeedKmH) * 60));
};

module.exports = {
  isValidLatitude,
  isValidLongitude,
  isValidCoordinates,
  haversineDistanceKm,
  safeDistanceKm,
  calculateETA,
};