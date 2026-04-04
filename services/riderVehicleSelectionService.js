const rideDb = require('../config/rideDb');

const normalizeVehicleType = (selectedVehicleType) => {
  if (!selectedVehicleType) return null;

  const type = String(selectedVehicleType).trim().toLowerCase();

  if (type === 'car' || type === 'private_car' || type === 'private car') {
    return 'car';
  }

  if (type === 'bike' || type === 'motorbike' || type === 'motor bike') {
    return 'bike';
  }

  return null;
};

const getVehicleStats = async (userId) => {
  const query = `
    SELECT
      COUNT(*)::int AS vehicle_count,
      COUNT(*) FILTER (WHERE vehicle_type = 'car')::int AS car_count,
      COUNT(*) FILTER (WHERE vehicle_type = 'bike')::int AS bike_count,
      COUNT(*) FILTER (WHERE verified = false)::int AS pending_vehicle_count,
      BOOL_OR(vehicle_type = 'car') AS has_car,
      BOOL_OR(vehicle_type = 'bike') AS has_bike,
      BOOL_OR(verified = false) AS has_pending_vehicle
    FROM vehicles
    WHERE user_id = $1
  `;

  const { rows } = await rideDb.query(query, [userId]);

  return {
    vehicleCount: rows[0]?.vehicle_count || 0,
    carCount: rows[0]?.car_count || 0,
    bikeCount: rows[0]?.bike_count || 0,
    hasCar: rows[0]?.has_car || false,
    hasBike: rows[0]?.has_bike || false,
    hasPendingVehicle: rows[0]?.has_pending_vehicle || false,
    pendingVehicleCount: rows[0]?.pending_vehicle_count || 0,
  };
};

const resolveNextScreen = ({ selectedVehicleType, hasMatchingType, hasPendingVehicle }) => {
  if (selectedVehicleType === 'car') {
    if (hasPendingVehicle) return 'vehicle_pending_review';
    if (hasMatchingType) return 'vehicle_already_exists';
    return 'private_car_registration';
  }

  if (selectedVehicleType === 'bike') {
    if (hasPendingVehicle) return 'vehicle_pending_review';
    if (hasMatchingType) return 'vehicle_already_exists';
    return 'bike_registration';
  }

  return null;
};

const getVehicleSelectionStatus = async ({ userId }) => {
  const stats = await getVehicleStats(userId);

  return {
    vehicleCount: stats.vehicleCount,
    hasCar: stats.hasCar,
    hasBike: stats.hasBike,
    hasPendingVehicle: stats.hasPendingVehicle,
    pendingVehicleCount: stats.pendingVehicleCount,
  };
};

const selectVehicleType = async ({ userId, selectedVehicleType }) => {
  const normalizedType = normalizeVehicleType(selectedVehicleType);

  if (!normalizedType) {
    throw new Error('Valid selectedVehicleType is required. Use car or bike.');
  }

  const stats = await getVehicleStats(userId);

  const hasMatchingType = normalizedType === 'car' ? stats.hasCar : stats.hasBike;

  const nextScreen = resolveNextScreen({
    selectedVehicleType: normalizedType,
    hasMatchingType,
    hasPendingVehicle: stats.hasPendingVehicle,
  });

  return {
    selectedVehicleType: normalizedType,
    vehicleCount: stats.vehicleCount,
    hasCar: stats.hasCar,
    hasBike: stats.hasBike,
    hasPendingVehicle: stats.hasPendingVehicle,
    nextScreen,
    alreadyHasSameType: hasMatchingType,
  };
};

module.exports = {
  getVehicleSelectionStatus,
  selectVehicleType,
};