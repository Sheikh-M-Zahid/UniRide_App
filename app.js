const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const vehicleRoutes = require('./routes/vehicleRoutes');
const rideRoutes = require('./routes/rideRoutes');
const rideChatRoutes = require('./routes/rideChatRoutes');
const ratingRoutes = require('./routes/ratingRoutes');
const companySharingRoutes = require('./routes/companySharingRoutes');
const liveLocationRoutes = require('./routes/liveLocationRoutes');
const sendItemRoutes = require('./routes/sendItemRoutes');
const offerRoutes = require('./routes/offerRoutes');
const reportRoutes = require('./routes/reportRoutes');
const transactionRoutes = require('./routes/transactionRoutes');
const adminRoutes = require('./routes/adminRoutes');
const homeRoutes = require('./routes/homeRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const walletRoutes = require('./routes/walletRoutes');
const supportRoutes = require('./routes/supportRoutes');
const vehicleRoutes = require('./routes/vehicleRoutes');
const reserveRoutes = require('./routes/reserveRoutes');
const activeRiderRoutes = require('./routes/activeRiderRoutes');
const earningsRoutes = require('./routes/earningsRoutes');
const activeRideRoutes = require('./routes/activeRideRoutes');
const activityRoutes = require('./routes/activityRoutes');
const riderActiveRideRoutes = require('./routes/riderActiveRideRoutes');
const riderDashboardRoutes = require('./routes/riderDashboardRoutes');
const passengerRideRequestRoutes = require('./routes/passengerRideRequestRoutes');
const riderRideHistoryRoutes = require('./routes/riderRideHistoryRoutes');
const riderMapRoutes = require('./routes/riderMapRoutes');
const riderProfileRoutes = require('./routes/riderProfileRoutes');
const riderSettingsRoutes = require('./routes/riderSettingsRoutes');

const errorMiddleware = require('./middlewares/errorMiddleware');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'UniRide backend is running.',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/ride-chat', rideChatRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/company-sharing', companySharingRoutes);
app.use('/api/live-locations', liveLocationRoutes);
app.use('/api/send-items', sendItemRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/rider/active-riders', activeRiderRoutes);
app.use('/api/reserve', reserveRoutes); 
app.use('/api/rider/earnings', earningsRoutes);
app.use('/api/rider/active-ride', activeRideRoutes);
app.use('/api/rider/activity', activityRoutes);
app.use('/api/rider/active-ride', riderActiveRideRoutes);
app.use('/api/rider/dashboard', riderDashboardRoutes);
app.use('/api/passenger/ride-requests', passengerRideRequestRoutes);
app.use('/api/rider/ride-history', riderRideHistoryRoutes);
app.use('/api/rider/map', riderMapRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/api/rider/profile', riderProfileRoutes);
app.use('/api/rider/settings', riderSettingsRoutes);

app.use(errorMiddleware);

module.exports = app;