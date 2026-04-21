const riderDeliverySocket = (io) => {
  io.on('connection', (socket) => {
    console.log(`Delivery socket connected: ${socket.id}`);

    socket.on('join:rider-delivery', (userId) => {
      if (!userId) return;

      const roomName = `rider:${userId}`;
      socket.join(roomName);

      console.log(`Socket ${socket.id} joined ${roomName}`);
    });

    socket.on('join:delivery-room', (deliveryId) => {
      if (!deliveryId) return;

      const roomName = `delivery:${deliveryId}`;
      socket.join(roomName);

      console.log(`Socket ${socket.id} joined ${roomName}`);
    });

    socket.on('leave:delivery-room', (deliveryId) => {
      if (!deliveryId) return;

      const roomName = `delivery:${deliveryId}`;
      socket.leave(roomName);

      console.log(`Socket ${socket.id} left ${roomName}`);
    });

    socket.on('disconnect', () => {
      console.log(`Delivery socket disconnected: ${socket.id}`);
    });
  });
};

module.exports = riderDeliverySocket;