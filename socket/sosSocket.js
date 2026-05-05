// SOS Tracking এর জন্য real-time location push
// Emergency contact এর browser-এ live update যাবে

module.exports = (io) => {
  const sosNamespace = io.of('/sos');

  sosNamespace.on('connection', (socket) => {

    // Tracker (emergency contact) একটা token দিয়ে join করে
    socket.on('sos:watch', ({ token }) => {
      if (!token) return;
      socket.join(`sos_track_${token}`);
    });

    // SOS চাপা ব্যক্তি তার location update করে
    socket.on('sos:location_update', ({ token, lat, lng }) => {
      if (!token || !lat || !lng) return;
      sosNamespace.to(`sos_track_${token}`).emit('sos:location', { lat, lng });
    });

    socket.on('disconnect', () => {});
  });
};
