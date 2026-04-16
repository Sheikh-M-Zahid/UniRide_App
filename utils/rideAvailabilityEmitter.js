let ioInstance = null;

const setRideAvailabilityIo = (io) => {
  ioInstance = io;
};

const emitSeatUpdate = (payload) => {
  if (!ioInstance) return;
  ioInstance.to('ride-options').emit('ride-options:seat-updated', payload);
};

const emitRideUnavailable = (payload) => {
  if (!ioInstance) return;
  ioInstance.to('ride-options').emit('ride-options:unavailable', payload);
};

const emitRideAvailable = (payload) => {
  if (!ioInstance) return;
  ioInstance.to('ride-options').emit('ride-options:available', payload);
};

const emitRideAvailabilityFound = ({ userId, payload }) => {
  if (!ioInstance) return;

  ioInstance.to(`user:${userId}`).emit('ride-availability:found', payload);
};
module.exports = {
  setRideAvailabilityIo,
  emitSeatUpdate,
  emitRideUnavailable,
  emitRideAvailable,
  emitRideAvailabilityFound,
};