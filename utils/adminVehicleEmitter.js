let adminVehicleIo = null;

const setAdminVehicleIo = (io) => {
  adminVehicleIo = io;
};

const emitAdminVehicleVerificationUpdated = (payload = {}) => {
  if (!adminVehicleIo) return;

  adminVehicleIo.to('admin_vehicle_verifications').emit(
    'admin:vehicle-verification-updated',
    {
      ...payload,
      emittedAt: new Date().toISOString(),
    }
  );
};

module.exports = {
  setAdminVehicleIo,
  emitAdminVehicleVerificationUpdated,
};