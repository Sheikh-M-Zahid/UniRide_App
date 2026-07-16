const { haversineDistanceKm } = require('./geo');

const nearestPointOnRoute = (routePoints, lat, lng) => {
  let minDist = Infinity;
  let nearestIndex = -1;
  routePoints.forEach((point, idx) => {
    const dist = haversineDistanceKm(lat, lng, point.lat, point.lng);
    if (dist < minDist) {
      minDist = dist;
      nearestIndex = idx;
    }
  });
  return { distanceKm: minDist, index: nearestIndex };
};

// route-এর দুইটা point-index এর মধ্যে polyline ধরে cumulative দূরত্ব
const cumulativeDistanceKm = (routePoints, fromIndex, toIndex) => {
  const start = Math.min(fromIndex, toIndex);
  const end = Math.max(fromIndex, toIndex);
  let total = 0;
  for (let i = start; i < end; i++) {
    total += haversineDistanceKm(
      routePoints[i].lat, routePoints[i].lng,
      routePoints[i + 1].lat, routePoints[i + 1].lng
    );
  }
  return total;
};

module.exports = { nearestPointOnRoute, cumulativeDistanceKm };
