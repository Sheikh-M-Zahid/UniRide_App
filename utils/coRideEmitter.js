let io;

const setCoRideIo = (ioInstance) => {
  io = ioInstance;
};

const emitCoRideSeatUpdate = (sessionId, availableSeats) => {
  if (!io) return;
  io.to(`coride_${sessionId}`).emit('coride:seat_update', {
    sessionId,
    availableSeats,
  });
};

const emitCoRideLiveLocation = (sessionId, location) => {
  if (!io) return;
  io.to(`coride_${sessionId}`).emit('coride:location', {
    sessionId,
    lat: location.lat,
    lng: location.lng,
  });
};

module.exports = {
  setCoRideIo,
  emitCoRideSeatUpdate,
  emitCoRideLiveLocation,
};