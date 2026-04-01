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

    socket.join(`user_${userId}`);

    socket.on('join_company_session', (sessionId) => {
      socket.join(`company_session_${sessionId}`);
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', userId);
    });
  });
};