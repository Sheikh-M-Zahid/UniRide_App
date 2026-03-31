const toRadians = (degree) => {
  return (degree * Math.PI) / 180;
};

const isValidLatitude = (lat) => {
  return typeof lat === 'number' && !Number.isNaN(lat) && lat >= -90 && lat <= 90;
};

const isValidLongitude = (lng) => {
  return typeof lng === 'number' && !Number.isNaN(lng) && lng >= -180 && lng <= 180;
};

const haversineDistanceKm = (lat1, lng1, lat2, lng2) => {
  const earthRadiusKm = 6371;

  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadiusKm * c;
};

module.exports = {
  isValidLatitude,
  isValidLongitude,
  haversineDistanceKm,
};