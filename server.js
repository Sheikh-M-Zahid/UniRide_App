console.log('Server boot started...');
require('dotenv').config();

const http = require('http');
console.log('Requiring app...');
const app = require('./app');
console.log('App required successfully');
const ewuAdminDb = require('./config/ewuAdminDb');
const rideDb = require('./config/rideDb');
const { initSocket } = require('./config/socket');

const riderSocket = require('./sockets/riderSocket');
const riderActiveRideSocket = require('./sockets/riderActiveRideSocket');
const riderDashboardSocket = require('./sockets/riderDashboardSocket');
const rideRequestSocket = require('./sockets/rideRequestSocket');
const riderDeliverySocket = require('./sockets/riderDeliverySocket');

const activeRiderSocket = require('./sockets/activeRiderSocket');
const activeRideSocket = require('./sockets/activeRideSocket');
const activitySocket = require('./sockets/activitySocket');
const earningsSocket = require('./sockets/earningsSocket');
const riderMapSocket = require('./sockets/riderMapSocket');

const rideAvailabilitySocket = require('./sockets/rideAvailabilitySocket');
const adminVehicleSocket = require('./sockets/adminVehicleSocket');
const { setRideAvailabilityIo } = require('./utils/rideAvailabilityEmitter');
const { setAdminVehicleIo } = require('./utils/adminVehicleEmitter');

const { setNotificationIo } = require('./utils/notificationEmitter');
const attachNotificationSocket = require('./sockets/notificationSocket');



const PORT = process.env.PORT || 5000;

const server = http.createServer(app);
const io = initSocket(server);


riderSocket(io);
riderActiveRideSocket(io);
riderDashboardSocket(io);
rideRequestSocket(io);
riderDeliverySocket(io);
rideAvailabilitySocket(io);
adminVehicleSocket(io);

setRideAvailabilityIo(io);
setAdminVehicleIo(io);
setNotificationIo(io);
attachNotificationSocket(io);

io.on('connection', (socket) => {
  activeRiderSocket(socket);
  activeRideSocket(socket);
  activitySocket(socket);
  earningsSocket(socket);
  riderMapSocket(socket);
});

const startServer = async () => {
  try {
    console.log('Checking ewuAdminDb...');
    await ewuAdminDb.query('SELECT 1');
    console.log('ewuAdminDb connected');

    console.log('Checking rideDb...');
    await rideDb.query('SELECT 1');
    console.log('rideDb connected');

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    console.error(error.stack);
    process.exit(1);
  }
};

startServer();
