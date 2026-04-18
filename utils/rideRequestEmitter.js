const { getIO } = require('../config/socket');

const emitRideRequestStatusUpdate = (requestId, payload) => {
  const io = getIO();
  io.to(`request_${requestId}`).emit('ride_request_status_update', payload);
};

const emitToRider = (riderId, payload) => {
  const io = getIO();
  io.to(`rider_${riderId}`).emit('new_ride_request', payload);
};

const emitToPassenger = (passengerId, payload) => {
  const io = getIO();
  io.to(`user_${passengerId}`).emit('ride_request_passenger_update', payload);
};

module.exports = {
  emitRideRequestStatusUpdate,
  emitToRider,
  emitToPassenger,
};