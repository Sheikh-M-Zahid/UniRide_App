const { addViewer, removeViewerBySocket } = require('../utils/coRideChatPresence');

const coRideSocket = (io) => {
  io.on('connection', (socket) => {
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

    // ── CoRide চ্যাট রুমে জয়েন (real-time message + presence ট্র্যাকিং) ──
    socket.on('join_company_session', ({ sessionId }) => {
      if (!sessionId) return;

      socket.join(`company_session_${sessionId}`);

      // socket.userId টা attachNotificationSocket দিয়ে আগেই সেট হয়ে যায় (JWT থেকে)
      if (socket.userId) {
        addViewer(sessionId, socket.userId, socket.id);
      }
    });

    socket.on('leave_company_session', ({ sessionId } = {}) => {
      if (sessionId) {
        socket.leave(`company_session_${sessionId}`);
      }
      removeViewerBySocket(socket.id);
    });

    socket.on('disconnect', () => {
      removeViewerBySocket(socket.id);
    });
  });
};

module.exports = coRideSocket;
