const rideRequestSocket = (io) => {
  io.on('connection', (socket) => {
    // Flutter passenger join করার জন্য
    socket.on('join_request_room', ({ requestId }) => {
      if (requestId) {
        socket.join(`request_${requestId}`);
        console.log(`Socket ${socket.id} joined request_${requestId}`);
      }
    });

    socket.on('join:rider-room', (userId) => {
      socket.join(`rider:${userId}`);
    });

    socket.on('join:user-room', (userId) => {
      socket.join(`user:${userId}`);
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
};

module.exports = rideRequestSocket;
