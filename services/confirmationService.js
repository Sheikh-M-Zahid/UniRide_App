const rideDb = require('../config/rideDb');

const getVehicleCount = async (userId) => {
  const query = `
    SELECT COUNT(*)::int AS vehicle_count
    FROM vehicles
    WHERE user_id = $1
  `;

  const { rows } = await rideDb.query(query, [userId]);
  return rows[0]?.vehicle_count || 0;
};

const inferRiderReadiness = ({ vehicleCount }) => {
  return vehicleCount > 0;
};

const resolveNextScreen = ({ selectedMode, riderReady }) => {
  if (selectedMode === 'passenger') {
    return 'passenger_home';
  }

  if (selectedMode === 'rider') {
    return riderReady ? 'rider_dashboard' : 'rider_onboarding';
  }

  return null;
};

const normalizeMode = (selectedMode) => {
  if (!selectedMode) return null;

  const mode = String(selectedMode).trim().toLowerCase();

  if (mode === 'rider' || mode === 'ride_sharer') return 'rider';
  if (mode === 'passenger') return 'passenger';

  return null;
};

const getConfirmationStatus = async ({ userId }) => {
  const vehicleCount = await getVehicleCount(userId);
  const riderReady = inferRiderReadiness({ vehicleCount });

  return {
    riderReady,
    vehicleCount,
    passengerReady: true,
  };
};

const selectMode = async ({ userId, selectedMode }) => {
  const normalizedMode = normalizeMode(selectedMode);

  if (!normalizedMode) {
    throw new Error('Valid selectedMode is required. Use rider or passenger.');
  }

  const vehicleCount = await getVehicleCount(userId);
  const riderReady = inferRiderReadiness({ vehicleCount });
  const nextScreen = resolveNextScreen({
    selectedMode: normalizedMode,
    riderReady,
  });

  return {
    selectedMode: normalizedMode,
    riderReady,
    vehicleCount,
    nextScreen,
  };
};

module.exports = {
  getConfirmationStatus,
  selectMode,
};