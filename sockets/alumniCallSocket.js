// sockets/alumniCallSocket.js
// WebRTC signaling relay — শুধু offer/answer/ICE candidate forward করে, media কখনো সার্ভার দিয়ে যায় না
const attachAlumniCallSocket = (io) => {
  io.on('connection', (socket) => {
    socket.on('alumni_call:offer', ({ toUserId, sessionId, offer }) => {
      if (!toUserId || !offer) return;
      io.to(`user_${toUserId}`).emit('alumni_call:offer', {
        sessionId,
        fromUserId: socket.user?.userId,
        offer,
      });
    });

    socket.on('alumni_call:answer', ({ toUserId, sessionId, answer }) => {
      if (!toUserId || !answer) return;
      io.to(`user_${toUserId}`).emit('alumni_call:answer', {
        sessionId,
        fromUserId: socket.user?.userId,
        answer,
      });
    });

    socket.on('alumni_call:ice-candidate', ({ toUserId, sessionId, candidate }) => {
      if (!toUserId || !candidate) return;
      io.to(`user_${toUserId}`).emit('alumni_call:ice-candidate', {
        sessionId,
        fromUserId: socket.user?.userId,
        candidate,
      });
    });

    socket.on('alumni_call:end', ({ toUserId, sessionId }) => {
      if (!toUserId) return;
      io.to(`user_${toUserId}`).emit('alumni_call:end', { sessionId });
    });
  });
};

module.exports = attachAlumniCallSocket;
