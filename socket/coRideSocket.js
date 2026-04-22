
const coRideSocket = (io) => {
  io.on('connection', (socket) => {
    // কোনো user একটি session room-এ join করে
    socket.on('coride:join_room', ({ sessionId }) => {
      if (sessionId) {
        socket.join(`coride_${sessionId}`);
      }
    });

    socket.on('coride:leave_room', ({ sessionId }) => {
      if (sessionId) {
        socket.leave(`coride_${sessionId}`);
      }
    });
  });
};

module.exports = coRideSocket;