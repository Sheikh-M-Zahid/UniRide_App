const jwt = require('jsonwebtoken');

module.exports = (io) => {
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.user_id;

    // join personal room
    socket.join(`user_${userId}`);

    console.log('Chat socket connected:', userId);

    socket.on('disconnect', () => {
      console.log('Chat socket disconnected:', userId);
    });
  });
};