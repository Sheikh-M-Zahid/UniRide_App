require('dotenv').config();

const http = require('http');
const app = require('./app');
const ewuAdminDb = require('./config/ewuAdminDb');
const rideDb = require('./config/rideDb');
const { initSocket } = require('./config/socket');

const riderSocket = require('./sockets/riderSocket');
const riderActiveRideSocket = require('./sockets/riderActiveRideSocket');
setInterval(async () => {
  try {
    await riderActiveRideService.expirePendingRequests({ io });
  } catch (error) {
    console.error('Expire pending requests error:', error.message);
  }
}, 15000);

const PORT = process.env.PORT || 5000;


const server = http.createServer(app);
const io = initSocket(server);


riderSocket(io);
riderActiveRideSocket(io);

app.set('io', io);



const startServer = async () => {
  try {
    await ewuAdminDb.query('SELECT 1');
    await rideDb.query('SELECT 1');

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();