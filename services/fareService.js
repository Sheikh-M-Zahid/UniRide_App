const rideDb = require('../config/rideDb');

const getActiveRateByVehicleType = async (vehicleType) => {
  const { rows } = await rideDb.query(
    `SELECT per_km_rate
     FROM vehicle_rates
     WHERE vehicle_type = $1
       AND is_active = true
     ORDER BY effective_from DESC
     LIMIT 1`,
    [vehicleType]
  );

  if (!rows.length) {
    throw new Error(`No active rate found for vehicle type: ${vehicleType}`);
  }

  return Number(rows[0].per_km_rate);
};

const calculateFare = ({ distanceKm, perKmRate }) => {
  return Number((Number(distanceKm) * Number(perKmRate)).toFixed(2));
};

module.exports = {
  getActiveRateByVehicleType,
  calculateFare,
};