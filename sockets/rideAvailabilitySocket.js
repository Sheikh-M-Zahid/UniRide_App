const rideAvailabilitySocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('join:ride-alerts', ({ userId }) => {
      if (userId) {
        socket.join(`user:${userId}`);
      }
    });

    socket.on('leave:ride-alerts', ({ userId }) => {
      if (userId) {
        socket.leave(`user:${userId}`);
      }
    });
  });
};

module.exports = rideAvailabilitySocket;
